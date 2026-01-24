import SwiftUI

/// ViewModel for managing WCAG 2.2 AAA accessibility settings
@Observable
@MainActor
public final class AccessibilityViewModel {
    /// Current accessibility settings
    public var settings: AccessibilitySettings = .default {
        didSet {
            Task {
                await cache.setAccessibilitySettings(settings)
                await cache.synchronize()
            }
        }
    }

    /// System accessibility preferences (read-only)
    public private(set) var systemReduceMotion: Bool = false
    public private(set) var systemBoldText: Bool = false
    public private(set) var systemHighContrast: Bool = false
    public private(set) var systemReduceTransparency: Bool = false

    private let cache = CacheService.shared

    public init() {
        // Load settings synchronously from cache on init
        // This ensures the UI has correct values immediately
        let savedSettings = UserDefaults.standard.data(forKey: "baynavigator:accessibility_settings")
            .flatMap { try? JSONDecoder().decode(AccessibilitySettings.self, from: $0) }
        if let saved = savedSettings {
            settings = saved
        }
    }

    // MARK: - Loading

    public func loadSettings() async {
        settings = await cache.getAccessibilitySettings()
    }

    /// Update system preferences from environment (call from view)
    public func updateSystemPreferences(
        reduceMotion: Bool,
        boldText: Bool = false,
        highContrast: Bool = false,
        reduceTransparency: Bool = false
    ) {
        systemReduceMotion = reduceMotion
        systemBoldText = boldText
        systemHighContrast = highContrast
        systemReduceTransparency = reduceTransparency
    }

    // MARK: - Presets

    /// Apply a preset configuration
    public func applyPreset(_ preset: AccessibilityPreset) {
        settings = preset.settings
    }

    /// Clear the active preset (resets to default)
    public func clearPreset() {
        settings = .default
    }

    /// Check if current settings match a preset
    public func matchesPreset(_ preset: AccessibilityPreset) -> Bool {
        var presetSettings = preset.settings
        presetSettings.activePreset = settings.activePreset
        return settings == presetSettings
    }

    // MARK: - Individual Setting Updates
    // Note: All methods are implicitly @MainActor since the class is @MainActor

    public func setTextScale(_ scale: Double) {
        var newSettings = settings
        newSettings.textScale = max(0.8, min(2.0, scale))
        newSettings.activePreset = nil
        settings = newSettings
    }

    public func setBoldText(_ enabled: Bool) {
        var newSettings = settings
        newSettings.boldText = enabled
        newSettings.activePreset = nil
        settings = newSettings
    }

    public func setHighContrastMode(_ enabled: Bool) {
        var newSettings = settings
        newSettings.highContrastMode = enabled
        newSettings.activePreset = nil
        settings = newSettings
    }

    public func setReduceTransparency(_ enabled: Bool) {
        var newSettings = settings
        newSettings.reduceTransparency = enabled
        newSettings.activePreset = nil
        settings = newSettings
    }

    public func setDyslexiaFont(_ enabled: Bool) {
        var newSettings = settings
        newSettings.dyslexiaFont = enabled
        newSettings.activePreset = nil
        settings = newSettings
    }

    public func setReduceMotion(_ enabled: Bool) {
        var newSettings = settings
        newSettings.reduceMotion = enabled
        newSettings.activePreset = nil
        settings = newSettings
    }

    public func setPauseAnimations(_ enabled: Bool) {
        var newSettings = settings
        newSettings.pauseAnimations = enabled
        newSettings.activePreset = nil
        settings = newSettings
    }

    public func setLineHeightMultiplier(_ multiplier: Double) {
        var newSettings = settings
        newSettings.lineHeightMultiplier = max(1.0, min(2.0, multiplier))
        newSettings.activePreset = nil
        settings = newSettings
    }

    public func setLetterSpacing(_ spacing: Double) {
        var newSettings = settings
        newSettings.letterSpacing = max(0, min(0.1, spacing))
        newSettings.activePreset = nil
        settings = newSettings
    }

    public func setWordSpacing(_ spacing: Double) {
        var newSettings = settings
        newSettings.wordSpacing = max(0, min(0.2, spacing))
        newSettings.activePreset = nil
        settings = newSettings
    }

    public func setSimpleLanguageMode(_ enabled: Bool) {
        var newSettings = settings
        newSettings.simpleLanguageMode = enabled
        newSettings.activePreset = nil
        settings = newSettings
    }

    public func setLargerTouchTargets(_ enabled: Bool) {
        var newSettings = settings
        newSettings.largerTouchTargets = enabled
        newSettings.activePreset = nil
        settings = newSettings
    }

    public func setExtendedTimeouts(_ enabled: Bool) {
        var newSettings = settings
        newSettings.extendedTimeouts = enabled
        newSettings.activePreset = nil
        settings = newSettings
    }

    public func setPreferCaptions(_ enabled: Bool) {
        var newSettings = settings
        newSettings.preferCaptions = enabled
        newSettings.activePreset = nil
        settings = newSettings
    }

    public func setVisualAlerts(_ enabled: Bool) {
        var newSettings = settings
        newSettings.visualAlerts = enabled
        newSettings.activePreset = nil
        settings = newSettings
    }

    // MARK: - Reset

    public func resetToDefaults() async {
        settings = .default
        await cache.resetAccessibilitySettings()
    }

    // MARK: - Computed Properties

    /// Whether any accessibility features are currently enabled
    public var hasCustomizations: Bool {
        !settings.isDefault
    }

    /// Effective reduce motion (app setting OR system setting)
    public var effectiveReduceMotion: Bool {
        settings.reduceMotion || systemReduceMotion
    }

    /// Effective bold text (app setting OR system setting)
    public var effectiveBoldText: Bool {
        settings.boldText || systemBoldText
    }

    /// Effective high contrast (app setting OR system setting)
    public var effectiveHighContrast: Bool {
        settings.highContrastMode || systemHighContrast
    }

    /// Effective reduce transparency (app setting OR system setting)
    public var effectiveReduceTransparency: Bool {
        settings.reduceTransparency || systemReduceTransparency
    }
}

// MARK: - Environment Key

private struct AccessibilityViewModelKey: EnvironmentKey {
    static let defaultValue: AccessibilityViewModel? = nil
}

extension EnvironmentValues {
    public var accessibilityViewModel: AccessibilityViewModel? {
        get { self[AccessibilityViewModelKey.self] }
        set { self[AccessibilityViewModelKey.self] = newValue }
    }
}
