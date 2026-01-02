import SwiftUI

/// A view modifier that applies a warm sepia tint overlay to reduce blue light
/// This serves as an in-app alternative to Night Shift since visionOS doesn't include it
struct WarmModeModifier: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if isEnabled {
                    Color.orange
                        .opacity(0.08)
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }
            }
            .colorMultiply(isEnabled ? Color(red: 1.0, green: 0.95, blue: 0.88) : .white)
    }
}

extension View {
    /// Applies a warm sepia tint to reduce blue light exposure
    /// - Parameter isEnabled: Whether warm mode should be active
    func warmMode(_ isEnabled: Bool) -> some View {
        modifier(WarmModeModifier(isEnabled: isEnabled))
    }
}
