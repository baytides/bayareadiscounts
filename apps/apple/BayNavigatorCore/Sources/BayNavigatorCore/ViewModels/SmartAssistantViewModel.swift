import Foundation
import SwiftUI

/// View model for Smart Assistant chat functionality
@Observable
public final class SmartAssistantViewModel {
    private let assistantService = SmartAssistantService.shared

    public var messages: [ChatMessage] = []
    public var inputText: String = ""
    public var isLoading: Bool = false
    public var showCrisisAlert: Bool = false
    public var detectedCrisisType: CrisisType?

    private var conversationHistory: [[String: String]] = []

    public init() {
        // Add welcome message
        messages.append(ChatMessage(
            role: .assistant,
            content: "Hi! I'm here to help you find programs and services in the Bay Area. You can ask me things like:\n\n- \"I need help paying my electric bill\"\n- \"What food assistance is available for seniors?\"\n- \"I'm a veteran looking for housing help\"\n\nWhat can I help you find today?"
        ))
    }

    public var quickPrompts: [String] {
        ["Food assistance", "Utility bill help", "Healthcare"]
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
            let result = try await assistantService.performAISearch(
                query: message,
                conversationHistory: conversationHistory
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
                programs: result.programs
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
            content: "Hi! I'm here to help you find programs and services in the Bay Area. You can ask me things like:\n\n- \"I need help paying my electric bill\"\n- \"What food assistance is available for seniors?\"\n- \"I'm a veteran looking for housing help\"\n\nWhat can I help you find today?"
        )]
        conversationHistory = []
    }
}

// MARK: - Chat Message Model

public struct ChatMessage: Identifiable, Sendable {
    public let id = UUID()
    public let role: MessageRole
    public let content: String
    public var programs: [AIProgram]?
    public var isError: Bool = false
    public let timestamp = Date()

    public enum MessageRole: Sendable {
        case user
        case assistant
    }

    public init(role: MessageRole, content: String, programs: [AIProgram]? = nil, isError: Bool = false) {
        self.role = role
        self.content = content
        self.programs = programs
        self.isError = isError
    }
}
