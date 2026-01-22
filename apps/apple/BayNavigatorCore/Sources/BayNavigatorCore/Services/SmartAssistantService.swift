import Foundation

/// Service for AI-powered smart search functionality
/// Uses a tiered approach: Quick Answers first, then AI API if needed
public actor SmartAssistantService {
    public static let shared = SmartAssistantService()

    private let assistantEndpoint = "https://ai.baytides.org/api/chat"
    // Tor-compatible endpoint (same, but uses .onion if available)
    private let torEndpoint = "https://ai.baytides.org/api/chat"  // TODO: Add .onion endpoint when available

    // API key from environment or fallback
    private let apiKey = ProcessInfo.processInfo.environment["OLLAMA_API_KEY"]
        ?? "bnav_a76a835781d394a03aaf1662d76fd1f05e78da85bf8edf27c8f26fbb9d2b79f0"

    private var standardSession: URLSession
    private var torSession: URLSession?
    private let requestTimeout: TimeInterval = 45
    private let torRequestTimeout: TimeInterval = 90 // Tor is slower

    private let quickAnswers = QuickAnswersService.shared

    // System prompt for Carl - CONDENSED for faster API responses
    private let systemPrompt = """
    You're Carl, Bay Navigator's AI (named after Karl the Fog, C for Chat). Help Bay Area residents find programs.

    RULES:
    1. Ask city/zip FIRST (unless crisis)
    2. ONLY link to baynavigator.org - NEVER external sites
    3. Crisis (911/988/DV hotline) = respond immediately, no location needed
    4. Be concise, warm. Available 24/7!

    LINKS (use these, not external):
    Food: baynavigator.org/eligibility/food-assistance
    Health: baynavigator.org/eligibility/healthcare
    Housing: baynavigator.org/eligibility/housing-assistance
    Utilities: baynavigator.org/eligibility/utility-programs
    Cash: baynavigator.org/eligibility/cash-assistance
    Seniors: baynavigator.org/eligibility/seniors
    Veterans: baynavigator.org/eligibility/military-veterans
    Directory: baynavigator.org/directory

    KEY PROGRAMS: CalFresh ($292/mo 1 person), Medi-Cal (free health), CARE (20% off PG&E), Section 8 (rent help, long waits).

    CRISIS: 911 emergency, 988 suicide/crisis, 1-800-799-7233 DV.
    """

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = requestTimeout
        self.standardSession = URLSession(configuration: config)
    }

    // MARK: - Tor Configuration

    /// Configure Tor proxy for requests using SafetyService's configuration
    /// This ensures consistent Tor settings across all services
    public func configureTorProxy(host: String = "127.0.0.1", port: Int = 9050) async {
        let safetyService = SafetyService.shared
        let proxyAvailable = await safetyService.isOrbotProxyAvailable()

        if proxyAvailable {
            let config = safetyService.createTorProxyConfiguration()
            config.timeoutIntervalForRequest = torRequestTimeout
            config.timeoutIntervalForResource = torRequestTimeout
            self.torSession = URLSession(configuration: config)
            print("[SmartAssistant] Tor proxy configured via SafetyService")
        } else {
            print("[SmartAssistant] Tor proxy not available (Orbot not running)")
            self.torSession = nil
        }
    }

    /// Disable Tor proxy
    public func disableTorProxy() {
        self.torSession = nil
        print("[SmartAssistant] Tor proxy disabled")
    }

    /// Check if Tor is configured and available
    public var isTorEnabled: Bool {
        get async {
            await SafetyService.shared.isTorEnabled()
        }
    }

    /// Check if Tor session is ready for use
    public var isTorSessionReady: Bool {
        torSession != nil
    }

    // MARK: - PII Sanitization

    /// Sanitize query to remove personally identifiable information
    private func sanitizeQuery(_ query: String) -> String {
        var result = query
        // SSN with dashes (XXX-XX-XXXX)
        result = result.replacingOccurrences(of: "\\b\\d{3}-\\d{2}-\\d{4}\\b", with: "[REDACTED]", options: .regularExpression)
        // SSN without dashes (9 consecutive digits)
        result = result.replacingOccurrences(of: "\\b\\d{9}\\b", with: "[REDACTED]", options: .regularExpression)
        // Email addresses
        result = result.replacingOccurrences(of: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}", with: "[REDACTED]", options: .regularExpression)
        // Phone numbers (various formats)
        result = result.replacingOccurrences(of: "\\b\\d{3}[-.]?\\d{3}[-.]?\\d{4}\\b", with: "[REDACTED]", options: .regularExpression)
        result = result.replacingOccurrences(of: "\\(\\d{3}\\)\\s*\\d{3}[-.]?\\d{4}", with: "[REDACTED]", options: .regularExpression)
        // Credit card numbers
        result = result.replacingOccurrences(of: "\\b\\d{4}[-\\s]?\\d{4}[-\\s]?\\d{4}[-\\s]?\\d{1,7}\\b", with: "[REDACTED]", options: .regularExpression)
        return result
    }

    // MARK: - Search (Tiered Approach)

    /// Main search function - uses quick answers first, then AI if needed
    public func search(
        query: String,
        conversationHistory: [[String: String]] = [],
        useTor: Bool = false,
        profileContext: ProfileContext? = nil
    ) async throws -> AISearchResult {
        // Tier 1: Check for quick answer match first (instant, no network)
        if let quickMatch = await quickAnswers.matchQuery(query) {
            return buildResultFromQuickAnswer(quickMatch)
        }

        // Tier 2: Use AI API
        return try await performAISearch(
            query: query,
            conversationHistory: conversationHistory,
            useTor: useTor,
            profileContext: profileContext
        )
    }

    /// Build AISearchResult from a quick answer match
    private func buildResultFromQuickAnswer(_ match: QuickAnswerResult) -> AISearchResult {
        let response = match.response

        // Build message from quick answer
        var message = ""

        if let title = response.title {
            message += "**\(title)**\n\n"
        }

        if let msg = response.message {
            message += msg
        } else if let summary = response.summary {
            message += summary
        }

        // Add resource info if present
        if let resource = response.resource {
            message += "\n\n📞 **\(resource.name)**"
            if let phone = resource.phone {
                message += " - \(phone)"
            }
            if let action = resource.action {
                message += "\n\(action)"
            }
        }

        // Add guide link if present
        if let guideUrl = response.guideUrl, let guideText = response.guideText {
            message += "\n\n📖 [\(guideText)](https://baynavigator.org\(guideUrl))"
        }

        // Add apply link if present
        if let applyUrl = response.applyUrl, let applyText = response.applyText {
            message += "\n\n✅ [\(applyText)](\(applyUrl))"
        }

        return AISearchResult(
            message: message,
            programs: [],
            programsFound: 0,
            location: nil,
            quickAnswer: nil,
            tier: "quick_answer"
        )
    }

    // MARK: - AI Search

    /// Perform an AI-powered search using the Ollama LLM
    public func performAISearch(
        query: String,
        conversationHistory: [[String: String]] = [],
        location: String? = nil,
        county: String? = nil,
        useTor: Bool = false,
        profileContext: ProfileContext? = nil
    ) async throws -> AISearchResult {
        let endpoint = useTor ? torEndpoint : assistantEndpoint
        guard let url = URL(string: endpoint) else {
            throw SmartAssistantError.invalidURL
        }

        // Select appropriate session
        let session: URLSession
        if useTor {
            guard let torSession = torSession else {
                throw SmartAssistantError.torNotConfigured
            }
            session = torSession
        } else {
            session = standardSession
        }

        // Sanitize the query to remove PII
        let sanitizedQuery = sanitizeQuery(query)

        // Build system prompt with optional profile context
        var effectiveSystemPrompt = systemPrompt
        if let profile = profileContext {
            effectiveSystemPrompt += "\n\n" + profile.toPromptContext()
        }

        // Build messages array for Ollama chat API
        var messages: [[String: String]] = [
            ["role": "system", "content": effectiveSystemPrompt]
        ]

        // Add conversation history (sanitized)
        for msg in conversationHistory.prefix(6) {
            if let role = msg["role"], let content = msg["content"] {
                let sanitizedContent = role == "user" ? sanitizeQuery(content) : content
                messages.append(["role": role, "content": sanitizedContent])
            }
        }

        // Add current user message
        messages.append(["role": "user", "content": sanitizedQuery])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }

        let body: [String: Any] = [
            "model": "llama3.1:8b-instruct-q4_K_M",
            "messages": messages,
            "stream": false,
            "options": [
                "temperature": 0.5,
                "num_predict": 256,
                "num_ctx": 2048
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SmartAssistantError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw SmartAssistantError.serverError(errorData.error)
            }
            throw SmartAssistantError.httpError(httpResponse.statusCode)
        }

        // Parse Ollama response format
        let result = try JSONDecoder().decode(OllamaResponse.self, from: data)

        let aiMessage = result.message?.content ?? result.response ?? "I couldn't generate a response. Please try searching the directory directly."

        return AISearchResult(
            message: aiMessage,
            programs: [],  // Programs are fetched separately
            programsFound: 0,
            location: nil,
            quickAnswer: nil,
            tier: useTor ? "llm_tor" : "llm"
        )
    }

    // MARK: - Crisis Detection

    /// Check if a query contains crisis keywords
    public func detectCrisis(_ query: String) async -> CrisisType? {
        // First check quick answers for crisis patterns
        if let crisisResponse = await quickAnswers.matchCrisis(query) {
            if crisisResponse.type == "crisis" {
                // Determine crisis type from the response
                if let resource = crisisResponse.resource {
                    if resource.phone == "988" {
                        return .mentalHealth
                    } else if resource.phone == "1-800-799-7233" {
                        return .domesticViolence
                    }
                }
                return .emergency
            }
        }

        // Fallback to simple keyword detection
        let lowerQuery = query.lowercased()

        let emergencyKeywords = [
            "emergency", "danger", "hurt", "attack", "abuse",
            "violence", "domestic violence", "unsafe", "threatened"
        ]

        let mentalHealthKeywords = [
            "suicide", "suicidal", "kill myself", "end my life",
            "don't want to live", "want to die", "self-harm",
            "cutting", "hurting myself", "crisis", "desperate"
        ]

        for keyword in mentalHealthKeywords {
            if lowerQuery.contains(keyword) {
                return .mentalHealth
            }
        }

        for keyword in emergencyKeywords {
            if lowerQuery.contains(keyword) {
                return .emergency
            }
        }

        return nil
    }

    // MARK: - Query Classification

    /// Check if a query should use AI search (complex/natural language queries)
    public func shouldUseAISearch(_ query: String) -> Bool {
        guard query.count >= 10 else { return false }

        let demographicTerms = [
            "senior", "elderly", "veteran", "disabled", "disability",
            "student", "low-income", "homeless", "immigrant", "lgbtq",
            "family", "child", "parent", "youth", "teen"
        ]

        let naturalPatterns = [
            "i need", "i'm looking", "help with", "how can i", "where can i",
            "looking for", "need help", "can you help", "what programs",
            "i am a", "i'm a", "my family", "we need"
        ]

        let lowerQuery = query.lowercased()

        for term in demographicTerms {
            if lowerQuery.contains(term) { return true }
        }

        for pattern in naturalPatterns {
            if lowerQuery.contains(pattern) { return true }
        }

        let wordCount = query.split(separator: " ").filter { $0.count > 2 }.count
        if wordCount >= 4 { return true }

        return false
    }
}

// MARK: - Types

public enum CrisisType: Sendable {
    case emergency
    case mentalHealth
    case domesticViolence
}

public enum SmartAssistantError: LocalizedError, Sendable {
    case invalidURL
    case networkError
    case httpError(Int)
    case serverError(String)
    case decodingError
    case torNotConfigured

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network error"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .serverError(let message):
            return message
        case .decodingError:
            return "Failed to decode response"
        case .torNotConfigured:
            return "Tor proxy is not configured. Enable Tor in Privacy settings."
        }
    }
}

public struct AISearchResult: Sendable {
    public let message: String
    public let programs: [AIProgram]
    public let programsFound: Int
    public let location: LocationInfo?
    public let quickAnswer: QuickAnswer?
    public let tier: String?

    public init(
        message: String,
        programs: [AIProgram],
        programsFound: Int,
        location: LocationInfo?,
        quickAnswer: QuickAnswer?,
        tier: String?
    ) {
        self.message = message
        self.programs = programs
        self.programsFound = programsFound
        self.location = location
        self.quickAnswer = quickAnswer
        self.tier = tier
    }
}

public struct AISearchResponse: Codable, Sendable {
    public let message: String?
    public let programs: [AIProgram]?
    public let programsFound: Int?
    public let searchQuery: String?
    public let location: LocationInfo?
    public let quickAnswer: QuickAnswer?
    public let tier: String?
}

/// Response format from Ollama API
struct OllamaResponse: Codable {
    let model: String?
    let message: OllamaMessage?
    let response: String?
    let done: Bool?
}

struct OllamaMessage: Codable {
    let role: String
    let content: String
}

public struct AIProgram: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let category: String
    public let description: String?
    public let phone: String?
    public let website: String?
    public let areas: [String]?
}

public struct LocationInfo: Codable, Sendable {
    public let zip: String?
    public let city: String?
    public let county: String?
}

struct ErrorResponse: Codable {
    let error: String
}

// MARK: - Quick Answer Types

public struct QuickAnswer: Codable, Sendable {
    public let type: String
    public let title: String?
    public let message: String?
    public let summary: String?
    public let resource: QuickAnswerResource?
    public let secondary: QuickAnswerResource?
    public let categories: [QuickAnswerCategory]?
    public let countyContact: CountyContact?
    public let guideUrl: String?
    public let guideText: String?
    public let applyUrl: String?
    public let applyText: String?
    public let search: String?

    public var isCrisis: Bool { type == "crisis" }
    public var needsClarification: Bool { type == "clarify" }
}

public struct QuickAnswerResource: Codable, Sendable {
    public let name: String
    public let phone: String?
    public let description: String?
    public let action: String?
}

public struct QuickAnswerCategory: Codable, Identifiable, Sendable {
    public let id: String
    public let label: String
    public let icon: String?
    public let search: String?
}

public struct CountyContact: Codable, Sendable {
    public let name: String
    public let phone: String
    public let agency: String
}

// MARK: - Profile Context for Personalized Responses

/// Profile context for personalized AI responses
/// Contains abstracted user attributes - never raw PII
public struct ProfileContext: Sendable {
    public let county: String?
    public let city: String?
    public let ageRange: String?  // e.g., "18-25", "65+", not exact age
    public let isMilitaryOrVeteran: Bool
    public let qualifications: [String]  // e.g., ["student", "caregiver"]

    public init(
        county: String? = nil,
        city: String? = nil,
        ageRange: String? = nil,
        isMilitaryOrVeteran: Bool = false,
        qualifications: [String] = []
    ) {
        self.county = county
        self.city = city
        self.ageRange = ageRange
        self.isMilitaryOrVeteran = isMilitaryOrVeteran
        self.qualifications = qualifications
    }

    /// Convert profile to a privacy-respecting prompt context
    /// Uses abstracted categories rather than specific personal details
    public func toPromptContext() -> String {
        var parts: [String] = []

        if let city = city, !city.isEmpty {
            parts.append("located in \(city)")
        } else if let county = county, !county.isEmpty {
            parts.append("in \(county) County")
        }

        if let ageRange = ageRange, !ageRange.isEmpty {
            parts.append("age \(ageRange)")
        }

        if isMilitaryOrVeteran {
            parts.append("veteran or military")
        }

        if !qualifications.isEmpty {
            let formattedQuals = qualifications.map { $0.replacingOccurrences(of: "-", with: " ") }
            parts.append(formattedQuals.joined(separator: ", "))
        }

        guard !parts.isEmpty else { return "" }

        return "USER CONTEXT: The user is \(parts.joined(separator: "; ")). Use this to prioritize relevant programs but still ask clarifying questions as needed."
    }
}
