import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Haptic Manager

@Observable
class HapticManager {
    static let shared = HapticManager()

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "hapticsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "hapticsEnabled") }
    }

    #if os(iOS)
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    #endif

    init() {
        // Set default to enabled
        if UserDefaults.standard.object(forKey: "hapticsEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "hapticsEnabled")
        }

        #if os(iOS)
        // Prepare generators for faster response
        prepareGenerators()
        #endif
    }

    #if os(iOS)
    private func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
    #endif

    // MARK: - Haptic Types

    /// Light tap - for subtle interactions like hovering or minor selections
    func lightTap() {
        guard isEnabled else { return }
        #if os(iOS)
        impactLight.impactOccurred()
        #endif
    }

    /// Medium tap - for standard button presses and selections
    func tap() {
        guard isEnabled else { return }
        #if os(iOS)
        impactMedium.impactOccurred()
        #endif
    }

    /// Heavy tap - for significant actions like confirming or completing
    func heavyTap() {
        guard isEnabled else { return }
        #if os(iOS)
        impactHeavy.impactOccurred()
        #endif
    }

    /// Soft impact - for gentle feedback
    func soft() {
        guard isEnabled else { return }
        #if os(iOS)
        impactSoft.impactOccurred()
        #endif
    }

    /// Rigid impact - for crisp feedback
    func rigid() {
        guard isEnabled else { return }
        #if os(iOS)
        impactRigid.impactOccurred()
        #endif
    }

    /// Selection changed - for picker and list selections
    func selection() {
        guard isEnabled else { return }
        #if os(iOS)
        selectionFeedback.selectionChanged()
        #endif
    }

    /// Success feedback - for completed actions
    func success() {
        guard isEnabled else { return }
        #if os(iOS)
        notificationFeedback.notificationOccurred(.success)
        #endif
    }

    /// Warning feedback - for cautionary situations
    func warning() {
        guard isEnabled else { return }
        #if os(iOS)
        notificationFeedback.notificationOccurred(.warning)
        #endif
    }

    /// Error feedback - for failed actions
    func error() {
        guard isEnabled else { return }
        #if os(iOS)
        notificationFeedback.notificationOccurred(.error)
        #endif
    }

    // MARK: - Contextual Haptics

    /// Favorite added
    func favoriteAdded() {
        guard isEnabled else { return }
        #if os(iOS)
        // Double tap pattern for adding
        impactMedium.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impactLight.impactOccurred()
        }
        #endif
    }

    /// Favorite removed
    func favoriteRemoved() {
        guard isEnabled else { return }
        #if os(iOS)
        impactSoft.impactOccurred()
        #endif
    }

    /// Pull to refresh
    func pullToRefresh() {
        guard isEnabled else { return }
        #if os(iOS)
        impactMedium.impactOccurred()
        #endif
    }

    /// Swipe action triggered
    func swipeAction() {
        guard isEnabled else { return }
        #if os(iOS)
        impactRigid.impactOccurred()
        #endif
    }

    /// Long press activated
    func longPress() {
        guard isEnabled else { return }
        #if os(iOS)
        impactHeavy.impactOccurred()
        #endif
    }

    /// Tab changed
    func tabChanged() {
        guard isEnabled else { return }
        #if os(iOS)
        selectionFeedback.selectionChanged()
        #endif
    }

    /// Filter applied
    func filterApplied() {
        guard isEnabled else { return }
        #if os(iOS)
        impactLight.impactOccurred()
        #endif
    }

    /// Search submitted
    func searchSubmit() {
        guard isEnabled else { return }
        #if os(iOS)
        impactMedium.impactOccurred()
        #endif
    }

    /// Application status changed
    func statusChanged(isPositive: Bool) {
        guard isEnabled else { return }
        #if os(iOS)
        if isPositive {
            notificationFeedback.notificationOccurred(.success)
        } else {
            notificationFeedback.notificationOccurred(.warning)
        }
        #endif
    }

    /// Crisis alert - strong warning pattern
    func crisisAlert() {
        guard isEnabled else { return }
        #if os(iOS)
        // Triple strong haptic for crisis
        notificationFeedback.notificationOccurred(.error)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.notificationFeedback.notificationOccurred(.error)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.notificationFeedback.notificationOccurred(.error)
        }
        #endif
    }
}

// MARK: - SwiftUI View Modifiers

struct HapticOnTap: ViewModifier {
    let type: HapticType

    enum HapticType {
        case light, medium, heavy, soft, rigid, selection, success, warning, error
    }

    func body(content: Content) -> some View {
        content.onTapGesture {
            switch type {
            case .light: HapticManager.shared.lightTap()
            case .medium: HapticManager.shared.tap()
            case .heavy: HapticManager.shared.heavyTap()
            case .soft: HapticManager.shared.soft()
            case .rigid: HapticManager.shared.rigid()
            case .selection: HapticManager.shared.selection()
            case .success: HapticManager.shared.success()
            case .warning: HapticManager.shared.warning()
            case .error: HapticManager.shared.error()
            }
        }
    }
}

extension View {
    func hapticOnTap(_ type: HapticOnTap.HapticType = .medium) -> some View {
        modifier(HapticOnTap(type: type))
    }
}

// MARK: - Haptic Button Style

struct HapticButtonStyle: ButtonStyle {
    var hapticType: HapticOnTap.HapticType = .medium

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    switch hapticType {
                    case .light: HapticManager.shared.lightTap()
                    case .medium: HapticManager.shared.tap()
                    case .heavy: HapticManager.shared.heavyTap()
                    case .soft: HapticManager.shared.soft()
                    case .rigid: HapticManager.shared.rigid()
                    case .selection: HapticManager.shared.selection()
                    case .success: HapticManager.shared.success()
                    case .warning: HapticManager.shared.warning()
                    case .error: HapticManager.shared.error()
                    }
                }
            }
    }
}

// MARK: - Accessibility-Aware Animations

struct AccessibilityAnimation {
    @Environment(\.accessibilityReduceMotion) static var reduceMotion: Bool

    /// Returns an animation respecting reduce motion preference
    static func standard(_ animation: Animation = .easeInOut(duration: 0.3)) -> Animation? {
        reduceMotion ? nil : animation
    }

    /// Spring animation with reduced motion fallback
    static func spring(response: Double = 0.5, dampingFraction: Double = 0.7) -> Animation? {
        reduceMotion ? nil : .spring(response: response, dampingFraction: dampingFraction)
    }

    /// Quick animation for micro-interactions
    static var quick: Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.15)
    }

    /// Smooth animation for larger transitions
    static var smooth: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.4)
    }
}

// MARK: - Animated View Modifier

struct AnimatedAppearance: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isVisible = false

    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(reduceMotion ? 1 : (isVisible ? 1 : 0))
            .offset(y: reduceMotion ? 0 : (isVisible ? 0 : 20))
            .onAppear {
                if reduceMotion {
                    isVisible = true
                } else {
                    withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                        isVisible = true
                    }
                }
            }
    }
}

extension View {
    func animatedAppearance(delay: Double = 0) -> some View {
        modifier(AnimatedAppearance(delay: delay))
    }
}

// MARK: - Pulse Animation

struct PulseAnimation: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isPulsing = false

    let duration: Double
    let minScale: CGFloat
    let maxScale: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(reduceMotion ? 1 : (isPulsing ? maxScale : minScale))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulse(duration: Double = 1.0, minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05) -> some View {
        modifier(PulseAnimation(duration: duration, minScale: minScale, maxScale: maxScale))
    }
}

// MARK: - Shake Animation (for errors)

struct ShakeAnimation: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Binding var trigger: Bool

    func body(content: Content) -> some View {
        content
            .offset(x: trigger && !reduceMotion ? -10 : 0)
            .animation(
                trigger && !reduceMotion
                    ? .interpolatingSpring(stiffness: 3000, damping: 10).repeatCount(3, autoreverses: true)
                    : .default,
                value: trigger
            )
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    HapticManager.shared.error()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        trigger = false
                    }
                }
            }
    }
}

extension View {
    func shake(trigger: Binding<Bool>) -> some View {
        modifier(ShakeAnimation(trigger: trigger))
    }
}

// MARK: - Loading Shimmer

struct ShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(reduceMotion ? 0 : 0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
            )
            .clipped()
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Haptic Settings View

struct HapticSettingsView: View {
    @State private var hapticManager = HapticManager.shared
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        Form {
            Section {
                Toggle("Haptic Feedback", isOn: $hapticsEnabled)
                    .onChange(of: hapticsEnabled) { _, enabled in
                        hapticManager.isEnabled = enabled
                        if enabled {
                            hapticManager.success()
                        }
                    }
            } header: {
                Text("Haptics")
            } footer: {
                Text("Feel tactile feedback when interacting with the app.")
            }

            if hapticsEnabled {
                Section {
                    Button("Test Light Tap") {
                        hapticManager.lightTap()
                    }
                    Button("Test Medium Tap") {
                        hapticManager.tap()
                    }
                    Button("Test Success") {
                        hapticManager.success()
                    }
                    Button("Test Warning") {
                        hapticManager.warning()
                    }
                    Button("Test Error") {
                        hapticManager.error()
                    }
                } header: {
                    Text("Test Haptics")
                }
            }
        }
        .navigationTitle("Haptics")
    }
}
