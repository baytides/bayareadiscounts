import SwiftUI
import BayNavigatorCore

/// Ask Carl - Full-screen AI chat interface for finding Bay Area programs and services
struct AskCarlView: View {
    @Environment(SmartAssistantViewModel.self) private var assistantVM
    @Environment(ProgramsViewModel.self) private var programsVM
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme

    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    // MARK: - Quick Prompts

    private let quickPrompts: [(icon: String, label: String, query: String)] = [
        ("fork.knife", "Food help", "I need help with food"),
        ("lightbulb.fill", "Utility help", "I need help paying my utility bills"),
        ("cross.case.fill", "Healthcare", "I need healthcare assistance"),
        ("house.fill", "Housing", "I need housing assistance"),
        ("figure.walk", "Seniors", "Programs for seniors"),
        ("medal.fill", "Veterans", "Programs for veterans")
    ]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            // Messages or empty state
            if assistantVM.messages.isEmpty {
                emptyStateView
            } else {
                messagesListView
            }

            // Input bar
            inputBarView
        }
        .background(backgroundColor)
        .alert("Crisis Support", isPresented: Binding(
            get: { assistantVM.showCrisisAlert },
            set: { assistantVM.showCrisisAlert = $0 }
        )) {
            crisisAlertButtons
        } message: {
            Text(crisisAlertMessage)
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: 12) {
            // Carl avatar
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.appPrimary)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Ask Carl")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                Text("Your Bay Area benefits guide")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Clear conversation button
            if !assistantVM.messages.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        assistantVM.clearConversation()
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.appPrimary)
                        .frame(width: 40, height: 40)
                        #if os(iOS)
                        .background(.regularMaterial, in: Circle())
                        #else
                        .background(Color.secondary.opacity(0.1), in: Circle())
                        #endif
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start new conversation")
                .accessibilityHint("Clears the current chat history")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(headerBackground)
    }

    private var headerBackground: some View {
        #if os(iOS)
        Rectangle()
            .fill(.regularMaterial)
            .overlay(alignment: .bottom) {
                Divider()
            }
        #else
        Rectangle()
            .fill(Color(.systemBackground))
            .overlay(alignment: .bottom) {
                Divider()
            }
        #endif
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 40)

                // Welcome illustration
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.appPrimary)
                        .symbolEffect(.pulse, options: .repeating)
                        .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text("Hi, I'm Carl!")
                            .font(.title.bold())

                        Text("I can help you find free and low-cost programs for food, healthcare, housing, utilities, and more.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }

                // Quick prompts section
                VStack(spacing: 16) {
                    Text("Try asking about:")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    quickPromptsGrid
                }
                .padding(.horizontal)

                // Privacy notice
                privacyNoticeView

                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
    }

    private var quickPromptsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(quickPrompts, id: \.query) { prompt in
                Button {
                    sendMessage(prompt.query)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: prompt.icon)
                            .font(.body)
                            .foregroundStyle(Color.appPrimary)
                            .frame(width: 24)

                        Text(prompt.label)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "arrow.up.circle.fill")
                            .font(.body)
                            .foregroundStyle(Color.appPrimary.opacity(0.6))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    #if os(iOS)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    #else
                    .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    #endif
                }
                .buttonStyle(.plain)
                .accessibilityLabel(prompt.label)
                .accessibilityHint("Ask Carl about \(prompt.label.lowercased())")
            }
        }
    }

    private var privacyNoticeView: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(Color.appSuccess)

            Text("Your questions are processed securely and never stored")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        #if os(iOS)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        #else
        .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
        #endif
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Privacy notice: Your questions are processed securely and never stored")
    }

    // MARK: - Messages List View

    private var messagesListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(assistantVM.messages) { message in
                        MessageBubbleView(
                            message: message,
                            onProgramTap: { program in
                                // Navigate to program detail
                            },
                            onPhoneCall: { phone in
                                callPhone(phone)
                            },
                            onTextMessage: { phone, message in
                                sendSMS(to: phone, body: message)
                            }
                        )
                        .id(message.id)
                    }

                    if assistantVM.isLoading {
                        typingIndicatorView
                            .id("typing-indicator")
                    }

                    // Show quick prompts after initial welcome or when not typing
                    if shouldShowQuickPrompts {
                        quickPromptsCompactView
                            .id("quick-prompts")
                    }
                }
                .padding()
            }
            .onChange(of: assistantVM.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: assistantVM.isLoading) { _, isLoading in
                if isLoading {
                    withAnimation {
                        proxy.scrollTo("typing-indicator", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var shouldShowQuickPrompts: Bool {
        !assistantVM.isLoading && assistantVM.messages.count <= 2
    }

    private var quickPromptsCompactView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick suggestions:")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 8) {
                ForEach(quickPrompts, id: \.query) { prompt in
                    Button {
                        sendMessage(prompt.query)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: prompt.icon)
                                .font(.caption)
                            Text(prompt.label)
                                .font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundStyle(Color.appPrimary)
                        .background(
                            Color.appPrimary.opacity(0.1),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.appPrimary.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 8)
    }

    private var typingIndicatorView: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Assistant avatar
            assistantAvatarView

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(assistantVM.isLoading ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: assistantVM.isLoading
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            #if os(iOS)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            #else
            .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
            #endif

            Spacer(minLength: 60)
        }
        .accessibilityLabel("Carl is typing")
    }

    private var assistantAvatarView: some View {
        Image(systemName: "sparkles")
            .font(.caption)
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(Color.appPrimary, in: Circle())
            .accessibilityHidden(true)
    }

    // MARK: - Input Bar View

    private var inputBarView: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                // Text field
                TextField("Ask Carl anything...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    #if os(iOS)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
                    #else
                    .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 22))
                    #endif
                    .onSubmit {
                        sendMessage(inputText)
                    }
                    .accessibilityLabel("Message input")
                    .accessibilityHint("Type your question for Carl")

                // Send button
                Button {
                    sendMessage(inputText)
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || assistantVM.isLoading
                            ? Color.secondary.opacity(0.5)
                            : Color.appPrimary
                        )
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || assistantVM.isLoading)
                .accessibilityLabel("Send message")
                .accessibilityHint(inputText.isEmpty ? "Enter a message first" : "Send your question to Carl")
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            #if os(iOS)
            .background(.regularMaterial)
            #else
            .background(Color(.systemBackground))
            #endif
        }
    }

    // MARK: - Crisis Alert

    private var crisisAlertMessage: String {
        switch assistantVM.detectedCrisisType {
        case .emergency:
            return "If you're in immediate danger, please call 911 right away."
        case .mentalHealth:
            return "If you're having thoughts of suicide or self-harm, help is available 24/7."
        case .none:
            return ""
        }
    }

    @ViewBuilder
    private var crisisAlertButtons: some View {
        switch assistantVM.detectedCrisisType {
        case .emergency:
            Button("Call 911", role: .destructive) {
                callPhone("911")
            }
            Button("Cancel", role: .cancel) { }

        case .mentalHealth:
            Button("Call 988 Crisis Line") {
                callPhone("988")
            }
            Button("Text HOME to 741741") {
                sendSMS(to: "741741", body: "HOME")
            }
            Button("Cancel", role: .cancel) { }

        case .none:
            Button("OK", role: .cancel) { }
        }
    }

    // MARK: - Helper Properties

    private var backgroundColor: Color {
        #if os(iOS)
        Color(.systemGroupedBackground)
        #else
        Color(.windowBackgroundColor)
        #endif
    }

    // MARK: - Actions

    private func sendMessage(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        inputText = ""

        Task {
            await assistantVM.sendMessage(trimmedText)
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            if let lastMessage = assistantVM.messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }

    private func callPhone(_ number: String) {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")

        if let url = URL(string: "tel:\(cleaned)") {
            openURL(url)
        }
    }

    private func sendSMS(to number: String, body: String) {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")

        if let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "sms:\(cleaned)?body=\(encodedBody)") {
            openURL(url)
        }
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let message: ChatMessage
    var onProgramTap: ((AIProgram) -> Void)?
    var onPhoneCall: ((String) -> Void)?
    var onTextMessage: ((String, String) -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser {
                Spacer(minLength: 60)
            } else {
                assistantAvatarView
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                // Message content
                messageBubble

                // Error indicator
                if message.isError {
                    errorIndicator
                }

                // Program results
                if let programs = message.programs, !programs.isEmpty {
                    programResultsView(programs: programs)
                }

                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Sent at \(message.timestamp.formatted(date: .omitted, time: .shortened))")
            }

            if !isUser {
                Spacer(minLength: 60)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isUser ? "You" : "Carl") said: \(message.content)")
    }

    private var assistantAvatarView: some View {
        Image(systemName: "sparkles")
            .font(.caption)
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(Color.appPrimary, in: Circle())
            .accessibilityHidden(true)
    }

    private var messageBubble: some View {
        Text(message.content)
            .font(.body)
            .foregroundStyle(isUser ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(bubbleBackground, in: bubbleShape)
    }

    private var bubbleBackground: some ShapeStyle {
        if isUser {
            return AnyShapeStyle(Color.appPrimary)
        } else if message.isError {
            return AnyShapeStyle(Color.appDanger.opacity(0.1))
        } else {
            #if os(iOS)
            return AnyShapeStyle(Material.regularMaterial)
            #else
            return AnyShapeStyle(Color.secondary.opacity(0.1))
            #endif
        }
    }

    private var bubbleShape: some InsettableShape {
        RoundedRectangle(cornerRadius: 18)
    }

    private var errorIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
            Text("Failed to load")
                .font(.caption2)
        }
        .foregroundStyle(Color.appDanger)
    }

    @ViewBuilder
    private func programResultsView(programs: [AIProgram]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggested Programs")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            ForEach(programs.prefix(5), id: \.id) { program in
                ProgramResultCard(
                    program: program,
                    onTap: { onProgramTap?(program) }
                )
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Program Result Card

struct ProgramResultCard: View {
    let program: AIProgram
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Category icon
                Image(systemName: categoryIcon)
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.categoryColor(for: program.category), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(program.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(program.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            #if os(iOS)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            #else
            .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            #endif
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(program.name), \(program.category)")
        .accessibilityHint("Tap to view program details")
    }

    private var categoryIcon: String {
        switch program.category.lowercased() {
        case "food", "food assistance":
            return "fork.knife"
        case "health", "healthcare", "medical":
            return "cross.case.fill"
        case "housing", "shelter":
            return "house.fill"
        case "utilities":
            return "bolt.fill"
        case "transportation", "transit":
            return "bus.fill"
        case "education", "learning", "training":
            return "book.fill"
        case "employment", "jobs", "career":
            return "briefcase.fill"
        case "legal", "legal aid":
            return "scale.3d"
        case "community", "community services":
            return "person.3.fill"
        default:
            return "star.fill"
        }
    }
}

// MARK: - Crisis Card View

struct CrisisCardView: View {
    let crisisType: CrisisType
    var onPhoneCall: ((String) -> Void)?
    var onTextMessage: ((String, String) -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.appDanger)
                Text(title)
                    .font(.headline)
                Spacer()
            }

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Action buttons
            VStack(spacing: 8) {
                primaryActionButton

                if crisisType == .mentalHealth {
                    secondaryActionButton
                }
            }
        }
        .padding()
        .background(
            Color.appDanger.opacity(0.1),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.appDanger.opacity(0.3), lineWidth: 1)
        )
    }

    private var title: String {
        switch crisisType {
        case .emergency:
            return "Emergency Help"
        case .mentalHealth:
            return "Crisis Support"
        }
    }

    private var message: String {
        switch crisisType {
        case .emergency:
            return "If you are in immediate danger, please call emergency services."
        case .mentalHealth:
            return "You are not alone. Free, confidential help is available 24/7."
        }
    }

    private var primaryActionButton: some View {
        Button {
            switch crisisType {
            case .emergency:
                onPhoneCall?("911")
            case .mentalHealth:
                onPhoneCall?("988")
            }
        } label: {
            HStack {
                Image(systemName: "phone.fill")
                Text(crisisType == .emergency ? "Call 911" : "Call 988 Suicide & Crisis Lifeline")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.appDanger, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(crisisType == .emergency ? "Call 911" : "Call 988 Suicide and Crisis Lifeline")
    }

    @ViewBuilder
    private var secondaryActionButton: some View {
        Button {
            onTextMessage?("741741", "HOME")
        } label: {
            HStack {
                Image(systemName: "message.fill")
                Text("Text HOME to 741741")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.appDanger)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Color.appDanger.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.appDanger.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Text HOME to 741741 for crisis support")
    }
}

// MARK: - Flow Layout

/// A simple flow layout for wrapping content horizontally
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, placement) in result.placements.enumerated() {
            subviews[index].place(
                at: CGPoint(
                    x: bounds.minX + placement.x,
                    y: bounds.minY + placement.y
                ),
                proposal: ProposedViewSize(placement.size)
            )
        }
    }

    private struct LayoutResult {
        var size: CGSize
        var placements: [(x: CGFloat, y: CGFloat, size: CGSize)]
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        let maxWidth = proposal.width ?? .infinity
        var placements: [(x: CGFloat, y: CGFloat, size: CGSize)] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            placements.append((x: currentX, y: currentY, size: size))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalWidth = max(totalWidth, currentX - spacing)
        }

        return LayoutResult(
            size: CGSize(width: totalWidth, height: currentY + lineHeight),
            placements: placements
        )
    }
}

// MARK: - Preview

#Preview {
    AskCarlView()
        .environment(SmartAssistantViewModel())
        .environment(ProgramsViewModel())
}
