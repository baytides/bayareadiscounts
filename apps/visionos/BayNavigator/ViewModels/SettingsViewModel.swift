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

    /// Current locale for the app
    var currentLocale: AppLocale = .en {
        didSet {
            Task {
                await LocalizationService.shared.setLocale(currentLocale)
            }
        }
    }

    // MARK: - Privacy Settings

    /// Enable Tor/Onion routing for enhanced privacy
    var useOnion: Bool = false {
        didSet {
            Task {
                await PrivacyService.shared.setOnionEnabled(useOnion)
                await refreshPrivacyStatus()
            }
        }
    }

    /// Enable custom proxy
    var proxyEnabled: Bool = false {
        didSet {
            Task {
                await PrivacyService.shared.setProxyEnabled(proxyEnabled)
                await refreshPrivacyStatus()
            }
        }
    }

    /// Current proxy configuration
    var proxyConfig: ProxyConfig?

    /// Whether Tor is available on the system
    var torAvailable: Bool = false

    /// Current privacy status
    var privacyStatus: PrivacyStatus?

    var colorScheme: ColorScheme? {
        switch themeMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private let cache = CacheService.shared
    private let privacyService = PrivacyService.shared

    init() {
        Task {
            // Load theme settings
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

            // Load locale setting
            await LocalizationService.shared.initialize()
            let savedLocale = await LocalizationService.shared.currentLocale
            await MainActor.run {
                self.currentLocale = savedLocale
            }

            // Load privacy settings
            let onionEnabled = await privacyService.isOnionEnabled()
            let proxyEnabledValue = await privacyService.isProxyEnabled()
            let config = await privacyService.getProxyConfig()
            let tor = await privacyService.isTorAvailable()
            let status = await privacyService.getPrivacyStatus()

            await MainActor.run {
                self.useOnion = onionEnabled
                self.proxyEnabled = proxyEnabledValue
                self.proxyConfig = config
                self.torAvailable = tor
                self.privacyStatus = status
            }
        }
    }

    // MARK: - Privacy Methods

    /// Refresh privacy status (call when settings change or to update Tor availability)
    @MainActor
    func refreshPrivacyStatus() async {
        torAvailable = await privacyService.isTorAvailable()
        privacyStatus = await privacyService.getPrivacyStatus()
    }

    /// Save proxy configuration
    @MainActor
    func setProxyConfig(_ config: ProxyConfig) async {
        await privacyService.setProxyConfig(config)
        proxyConfig = config
        proxyEnabled = true
        await privacyService.setProxyEnabled(true)
        await refreshPrivacyStatus()
    }

    /// Clear proxy configuration
    @MainActor
    func clearProxyConfig() async {
        await privacyService.clearProxyConfig()
        proxyConfig = nil
        proxyEnabled = false
        await refreshPrivacyStatus()
    }

    /// Test privacy connection
    func testPrivacyConnection() async -> PrivacyTestResult {
        await privacyService.testPrivacyConnection()
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
    static let creditsURL = URL(string: "https://baynavigator.org/credits")!
    static let githubURL = URL(string: "https://github.com/baytides/baynavigator")!
    static let feedbackURL = URL(string: "https://github.com/baytides/baynavigator/issues")!
}
