import Foundation

/// Service for AI-powered smart search functionality using Ollama LLM
public actor SmartAssistantService {
    public static let shared = SmartAssistantService()

    private let assistantEndpoint = "https://ai.baytides.org/api/chat"
    // API key from environment or fallback
    private let apiKey = ProcessInfo.processInfo.environment["OLLAMA_API_KEY"]
        ?? "bnav_a76a835781d394a03aaf1662d76fd1f05e78da85bf8edf27c8f26fbb9d2b79f0"
    private let session: URLSession
    private let requestTimeout: TimeInterval = 45

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
        self.session = URLSession(configuration: config)
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

    // MARK: - AI Search

    /// Perform an AI-powered search using the Ollama LLM
    public func performAISearch(
        query: String,
        conversationHistory: [[String: String]] = [],
        location: String? = nil,
        county: String? = nil
    ) async throws -> AISearchResult {
        guard let url = URL(string: assistantEndpoint) else {
            throw SmartAssistantError.invalidURL
        }

        // Sanitize the query to remove PII
        let sanitizedQuery = sanitizeQuery(query)

        // Build messages array for Ollama chat API
        var messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
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
            tier: "llm"
        )
    }

    /// Simplified search for quick program lookup
    public func search(query: String) async throws -> AISearchResult {
        try await performAISearch(query: query)
    }

    // MARK: - Crisis Detection

    /// Check if a query contains crisis keywords
    public func detectCrisis(_ query: String) -> CrisisType? {
        let lowerQuery = query.lowercased()

        // Emergency keywords
        let emergencyKeywords = [
            "emergency", "danger", "hurt", "attack", "abuse",
            "violence", "domestic violence", "unsafe", "threatened"
        ]

        // Mental health crisis keywords
        let mentalHealthKeywords = [
            "suicide", "suicidal", "kill myself", "end my life",
            "don't want to live", "want to die", "self-harm",
            "cutting", "hurting myself", "crisis", "desperate"
        ]

        for keyword in emergencyKeywords {
            if lowerQuery.contains(keyword) {
                return .emergency
            }
        }

        for keyword in mentalHealthKeywords {
            if lowerQuery.contains(keyword) {
                return .mentalHealth
            }
        }

        return nil
    }

    // MARK: - Query Classification

    /// Check if a query should use AI search (complex/natural language queries)
    public func shouldUseAISearch(_ query: String) -> Bool {
        guard query.count >= 10 else { return false }

        // Demographic/eligibility terms that suggest complex queries
        let demographicTerms = [
            "senior", "elderly", "veteran", "disabled", "disability",
            "student", "low-income", "homeless", "immigrant", "lgbtq",
            "family", "child", "parent", "youth", "teen"
        ]

        // Natural language patterns
        let naturalPatterns = [
            "i need", "i'm looking", "help with", "how can i", "where can i",
            "looking for", "need help", "can you help", "what programs",
            "i am a", "i'm a", "my family", "we need"
        ]

        let lowerQuery = query.lowercased()

        // Check for demographic terms
        for term in demographicTerms {
            if lowerQuery.contains(term) { return true }
        }

        // Check for natural language patterns
        for pattern in naturalPatterns {
            if lowerQuery.contains(pattern) { return true }
        }

        // Multiple words with spaces suggest natural language
        let wordCount = query.split(separator: " ").filter { $0.count > 2 }.count
        if wordCount >= 4 { return true }

        return false
    }
}

// MARK: - Types

public enum CrisisType: Sendable {
    case emergency
    case mentalHealth
}

public enum SmartAssistantError: LocalizedError, Sendable {
    case invalidURL
    case networkError
    case httpError(Int)
    case serverError(String)
    case decodingError

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
    let response: String?  // Alternative format for non-chat completions
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

/// Quick answer from cached responses (Tier 1)
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

    /// Check if this is a crisis response
    public var isCrisis: Bool { type == "crisis" }

    /// Check if this needs user clarification
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
