import SwiftUI

@Observable
@MainActor
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
                await CacheService.shared.synchronize()
            }
        }
    }

    /// Warm Mode - shifts colors toward warmer tones (simulates Night Shift)
    /// Since visionOS doesn't have native Night Shift, this applies a warm color overlay
    public var warmModeEnabled: Bool = false {
        didSet {
            Task {
                await CacheService.shared.setWarmMode(warmModeEnabled)
                await CacheService.shared.synchronize()
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

    /// AI-powered search is now always enabled (toggle removed)
    /// Users can access Ask Carl for interactive AI assistance
    public var aiSearchEnabled: Bool {
        get { true }
        set { /* No-op: AI is always enabled */ }
    }

    // MARK: - Privacy Settings

    /// Current privacy mode (standard, domain fronting, or Tor)
    public var privacyMode: PrivacyService.PrivacyMode = .standard {
        didSet {
            Task {
                await privacyService.setPrivacyMode(privacyMode)
                await refreshPrivacyStatus()
            }
        }
    }

    /// Auto-detect censorship and switch to domain fronting
    public var autoDetectCensorship: Bool = false {
        didSet {
            Task {
                await privacyService.setAutoDetectCensorship(autoDetectCensorship)
            }
        }
    }

    /// Selected CDN provider for domain fronting
    public var cdnProvider: PrivacyService.CDNProvider = .cloudflare {
        didSet {
            Task {
                await privacyService.setCDNProvider(cdnProvider)
                await refreshPrivacyStatus()
            }
        }
    }

    /// Whether Tor/Orbot is available on the system
    public var torAvailable: Bool = false

    /// Current privacy status for UI display
    public var privacyStatus: PrivacyStatus?

    #if os(iOS)
    /// Whether Orbot app is installed (iOS only)
    public var orbotInstalled: Bool = false
    #endif

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
        // Load settings synchronously from UserDefaults on init
        // This ensures the UI has correct values immediately
        let defaults = UserDefaults.standard

        // Theme mode
        if let savedMode = defaults.string(forKey: "baynavigator:theme_mode"),
           let mode = ThemeMode(rawValue: savedMode) {
            themeMode = mode
        }

        // Warm mode
        warmModeEnabled = defaults.bool(forKey: "baynavigator:warm_mode")

        // Locale - use the localization service's sync method
        currentLocale = LocalizationService.shared.getCurrentLocale()

        // AI search
        aiSearchEnabled = defaults.object(forKey: "baynavigator:ai_search_enabled") as? Bool ?? true

        // Privacy mode - load synchronously
        if let savedMode = defaults.string(forKey: "baynavigator:privacy_mode"),
           let mode = PrivacyService.PrivacyMode(rawValue: savedMode) {
            privacyMode = mode
        }
        autoDetectCensorship = defaults.bool(forKey: "baynavigator:auto_detect_censorship")

        // CDN provider
        if let savedProvider = defaults.string(forKey: "baynavigator:cdn_provider"),
           let provider = PrivacyService.CDNProvider(rawValue: savedProvider) {
            cdnProvider = provider
        }

        // Privacy settings that require async calls
        Task {
            await loadPrivacySettings()
            // Also ensure localization service is initialized for translations
            await LocalizationService.shared.initialize()
        }
    }

    /// Load privacy settings asynchronously
    private func loadPrivacySettings() async {
        torAvailable = await privacyService.isTorAvailable()
        privacyStatus = await privacyService.getPrivacyStatus()

        #if os(iOS)
        orbotInstalled = await privacyService.isOrbotInstalled()
        #endif
    }

    // MARK: - Privacy Methods

    /// Refresh privacy status (call when settings change or to update Tor availability)
    public func refreshPrivacyStatus() async {
        torAvailable = await privacyService.isTorAvailable()
        privacyStatus = await privacyService.getPrivacyStatus()

        #if os(iOS)
        orbotInstalled = await privacyService.isOrbotInstalled()
        #endif
    }

    /// Test privacy connection
    public func testPrivacyConnection() async -> PrivacyTestResult {
        await privacyService.testPrivacyConnection()
    }

    #if os(iOS)
    /// Open Orbot app (iOS only)
    public func openOrbot() async {
        await privacyService.openOrbot()
    }

    /// Get Orbot App Store URL
    public var orbotAppStoreURL: URL {
        get async {
            await privacyService.orbotAppStoreURL
        }
    }
    #endif

    // MARK: - Cache Management

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
