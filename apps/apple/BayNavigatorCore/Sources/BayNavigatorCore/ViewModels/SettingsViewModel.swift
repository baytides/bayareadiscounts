import SwiftUI

@Observable
public final class SettingsViewModel {
    public enum ThemeMode: String, CaseIterable, Identifiable, Sendable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"

        public var id: String { rawValue }
    }

    public var themeMode: ThemeMode = .system {
        didSet {
            Task {
                await CacheService.shared.setThemeMode(themeMode.rawValue)
            }
        }
    }

    /// Warm Mode - shifts colors toward warmer tones (simulates Night Shift)
    /// Since visionOS doesn't have native Night Shift, this applies a warm color overlay
    public var warmModeEnabled: Bool = false {
        didSet {
            Task {
                await CacheService.shared.setWarmMode(warmModeEnabled)
            }
        }
    }

    /// Current locale for the app
    public var currentLocale: AppLocale = .en {
        didSet {
            Task {
                await LocalizationService.shared.setLocale(currentLocale)
            }
        }
    }

    /// AI-powered search enabled
    public var aiSearchEnabled: Bool = true {
        didSet {
            Task {
                await CacheService.shared.setAISearchEnabled(aiSearchEnabled)
            }
        }
    }

    // MARK: - Privacy Settings

    /// Enable Tor/Onion routing for enhanced privacy
    public var useOnion: Bool = false {
        didSet {
            Task {
                await PrivacyService.shared.setOnionEnabled(useOnion)
                await refreshPrivacyStatus()
            }
        }
    }

    /// Enable custom proxy
    public var proxyEnabled: Bool = false {
        didSet {
            Task {
                await PrivacyService.shared.setProxyEnabled(proxyEnabled)
                await refreshPrivacyStatus()
            }
        }
    }

    /// Current proxy configuration
    public var proxyConfig: ProxyConfig?

    /// Whether Tor is available on the system
    public var torAvailable: Bool = false

    /// Current privacy status
    public var privacyStatus: PrivacyStatus?

    public var colorScheme: ColorScheme? {
        switch themeMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private let cache = CacheService.shared
    private let privacyService = PrivacyService.shared

    public init() {
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

            // Load AI search setting
            let aiEnabled = await cache.getAISearchEnabled()
            await MainActor.run {
                self.aiSearchEnabled = aiEnabled
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
    public func refreshPrivacyStatus() async {
        torAvailable = await privacyService.isTorAvailable()
        privacyStatus = await privacyService.getPrivacyStatus()
    }

    /// Save proxy configuration
    @MainActor
    public func setProxyConfig(_ config: ProxyConfig) async {
        await privacyService.setProxyConfig(config)
        proxyConfig = config
        proxyEnabled = true
        await privacyService.setProxyEnabled(true)
        await refreshPrivacyStatus()
    }

    /// Clear proxy configuration
    @MainActor
    public func clearProxyConfig() async {
        await privacyService.clearProxyConfig()
        proxyConfig = nil
        proxyEnabled = false
        await refreshPrivacyStatus()
    }

    /// Test privacy connection
    public func testPrivacyConnection() async -> PrivacyTestResult {
        await privacyService.testPrivacyConnection()
    }

    public var cacheSize: String {
        get async {
            await cache.formattedCacheSize
        }
    }

    public func clearCache() async {
        await cache.clearCache()
    }
}

// MARK: - App Info

extension SettingsViewModel {
    public static let appVersion: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }()

    public static let websiteURL = URL(string: "https://baynavigator.org")!
    public static let donateURL = URL(string: "https://baytides.org/donate")!
    public static let parentOrgURL = URL(string: "https://baytides.org")!
    public static let termsURL = URL(string: "https://baynavigator.org/terms")!
    public static let privacyURL = URL(string: "https://baynavigator.org/privacy")!
    public static let creditsURL = URL(string: "https://baynavigator.org/credits")!
    public static let githubURL = URL(string: "https://github.com/baytides/baynavigator")!
    public static let feedbackURL = URL(string: "https://github.com/baytides/baynavigator/issues")!
}
