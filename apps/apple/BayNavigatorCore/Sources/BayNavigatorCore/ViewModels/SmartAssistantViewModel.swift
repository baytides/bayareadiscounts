import Foundation
import SwiftUI

/// View model for Smart Assistant chat functionality
@Observable
public final class SmartAssistantViewModel {
    private let assistantService = SmartAssistantService.shared
    private let safetyService = SafetyService.shared

    public var messages: [ChatMessage] = []
    public var inputText: String = ""
    public var isLoading: Bool = false
    public var showCrisisAlert: Bool = false
    public var detectedCrisisType: CrisisType?
    public var useTor: Bool = false  // Whether to route requests through Tor

    // Profile context for personalized responses
    private var userPrefs: UserPrefsViewModel?

    private var conversationHistory: [[String: String]] = []

    public init() {
        // Add welcome message
        messages.append(ChatMessage(
            role: .assistant,
            content: "Hi! I'm Carl, your Bay Area benefits guide. I can help you find programs for food, healthcare, housing, utilities, and more.\n\nWhat can I help you with today?"
        ))
    }

    /// Set user preferences for personalized context
    public func setUserPreferences(_ prefs: UserPrefsViewModel) {
        self.userPrefs = prefs
    }

    public var quickPrompts: [String] {
        ["Food assistance", "Utility bill help", "Healthcare"]
    }

    /// Configure Tor for Ask Carl
    public func configureTor(enabled: Bool, host: String = "127.0.0.1", port: Int = 9050) async {
        useTor = enabled
        if enabled {
            await assistantService.configureTorProxy(host: host, port: port)
        } else {
            await assistantService.disableTorProxy()
        }
    }

    @MainActor
    public func sendMessage(_ overrideMessage: String? = nil) async {
        let message = overrideMessage ?? inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, !isLoading else { return }

        inputText = ""

        // Check for crisis keywords
        if let crisisType = await assistantService.detectCrisis(message) {
            detectedCrisisType = crisisType
            showCrisisAlert = true
        }

        // Add user message
        messages.append(ChatMessage(role: .user, content: message))
        isLoading = true

        do {
            // Build profile context if user has opted in
            let profileContext = await buildProfileContext()

            // Use the tiered search (quick answers first, then AI)
            let result = try await assistantService.search(
                query: message,
                conversationHistory: conversationHistory,
                useTor: useTor,
                profileContext: profileContext
            )

            // Update conversation history
            conversationHistory.append(["role": "user", "content": message])
            conversationHistory.append(["role": "assistant", "content": result.message])

            // Keep only last 10 messages in history
            if conversationHistory.count > 10 {
                conversationHistory = Array(conversationHistory.suffix(10))
            }

            // Add assistant response with programs
            messages.append(ChatMessage(
                role: .assistant,
                content: result.message,
                programs: result.programs,
                tier: result.tier
            ))
        } catch SmartAssistantError.torNotConfigured {
            messages.append(ChatMessage(
                role: .assistant,
                content: "Tor is enabled but not configured. Please check that Tor is running on your device, or disable Tor in Privacy settings to use standard connection.",
                isError: true
            ))
        } catch {
            messages.append(ChatMessage(
                role: .assistant,
                content: "I'm sorry, I'm having trouble connecting right now. Please try searching the programs directly or try again later.",
                isError: true
            ))
        }

        isLoading = false
    }

    public func clearConversation() {
        messages = [ChatMessage(
            role: .assistant,
            content: "Hi! I'm Carl, your Bay Area benefits guide. I can help you find programs for food, healthcare, housing, utilities, and more.\n\nWhat can I help you with today?"
        )]
        conversationHistory = []
    }

    // MARK: - Profile Context

    /// Build profile context if user has opted in to sharing with Carl
    private func buildProfileContext() async -> ProfileContext? {
        // Check if user has opted in
        let isEnabled = await safetyService.isShareProfileWithCarlEnabled()
        guard isEnabled, let prefs = userPrefs else { return nil }

        // Convert birth year to age range for privacy
        let ageRange: String? = {
            guard let birthYear = prefs.birthYear else { return nil }
            let currentYear = Calendar.current.component(.year, from: Date())
            let age = currentYear - birthYear
            switch age {
            case 0..<18: return "under 18"
            case 18..<25: return "18-24"
            case 25..<35: return "25-34"
            case 35..<45: return "35-44"
            case 45..<55: return "45-54"
            case 55..<62: return "55-61"
            case 62..<65: return "62-64"
            case 65...: return "65+"
            default: return nil
            }
        }()

        return ProfileContext(
            county: prefs.selectedCounty,
            city: prefs.city,
            ageRange: ageRange,
            isMilitaryOrVeteran: prefs.isMilitaryOrVeteran ?? false,
            qualifications: prefs.qualifications
        )
    }
}

// MARK: - Chat Message Model

public struct ChatMessage: Identifiable, Sendable {
    public let id = UUID()
    public let role: MessageRole
    public let content: String
    public var programs: [AIProgram]?
    public var isError: Bool = false
    public var tier: String?  // "quick_answer", "llm", "llm_tor"
    public let timestamp = Date()

    public enum MessageRole: Sendable {
        case user
        case assistant
    }

    public init(role: MessageRole, content: String, programs: [AIProgram]? = nil, isError: Bool = false, tier: String? = nil) {
        self.role = role
        self.content = content
        self.programs = programs
        self.isError = isError
        self.tier = tier
    }
}
