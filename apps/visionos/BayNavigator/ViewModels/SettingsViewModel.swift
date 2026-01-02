import SwiftUI

@Observable
final class SettingsViewModel {
    enum ThemeMode: String, CaseIterable, Identifiable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"

        var id: String { rawValue }
    }

    var themeMode: ThemeMode = .system {
        didSet {
            Task {
                await CacheService.shared.setThemeMode(themeMode.rawValue)
            }
        }
    }

    /// Warm Mode - shifts colors toward warmer tones (simulates Night Shift)
    /// Since visionOS doesn't have native Night Shift, this applies a warm color overlay
    var warmModeEnabled: Bool = false {
        didSet {
            Task {
                await CacheService.shared.setWarmMode(warmModeEnabled)
            }
        }
    }

    var colorScheme: ColorScheme? {
        switch themeMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private let cache = CacheService.shared

    init() {
        Task {
            if let savedMode = await cache.getThemeMode(),
               let mode = ThemeMode(rawValue: savedMode) {
                await MainActor.run {
                    self.themeMode = mode
                }
            }
            let warmMode = await cache.getWarmMode()
            await MainActor.run {
                self.warmModeEnabled = warmMode
            }
        }
    }

    var cacheSize: String {
        get async {
            await cache.formattedCacheSize
        }
    }

    func clearCache() async {
        await cache.clearCache()
    }
}

// MARK: - App Info

extension SettingsViewModel {
    static let appVersion: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }()

    static let websiteURL = URL(string: "https://baynavigator.org")!
    static let donateURL = URL(string: "https://baytides.org/donate")!
    static let parentOrgURL = URL(string: "https://baytides.org")!
    static let termsURL = URL(string: "https://baynavigator.org/terms")!
    static let privacyURL = URL(string: "https://baynavigator.org/privacy")!
    static let githubURL = URL(string: "https://github.com/baytides/baynavigator")!
    static let feedbackURL = URL(string: "https://github.com/baytides/baynavigator/issues")!
}
