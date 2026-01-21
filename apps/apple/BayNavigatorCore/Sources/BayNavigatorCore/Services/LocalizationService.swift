import Foundation

/// Supported locales in Bay Navigator
/// Matches the web and Flutter i18n configuration (10 languages)
public enum AppLocale: String, CaseIterable, Identifiable, Sendable {
    case en = "en"
    case es = "es"
    case zhHans = "zh-Hans"
    case zhHant = "zh-Hant"
    case vi = "vi"
    case fil = "fil"
    case ko = "ko"
    case ru = "ru"
    case fr = "fr"
    case ar = "ar"

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .en: return "English"
        case .es: return "Spanish"
        case .zhHans: return "Chinese (Simplified)"
        case .zhHant: return "Chinese (Traditional)"
        case .vi: return "Vietnamese"
        case .fil: return "Filipino"
        case .ko: return "Korean"
        case .ru: return "Russian"
        case .fr: return "French"
        case .ar: return "Arabic"
        }
    }

    public var nativeName: String {
        switch self {
        case .en: return "English"
        case .es: return "Espanol"
        case .zhHans: return "简体中文"
        case .zhHant: return "繁體中文"
        case .vi: return "Tieng Viet"
        case .fil: return "Filipino"
        case .ko: return "한국어"
        case .ru: return "Русский"
        case .fr: return "Francais"
        case .ar: return "العربية"
        }
    }

    public var flag: String {
        switch self {
        case .en: return "\u{1F1FA}\u{1F1F8}"
        case .es: return "\u{1F1EA}\u{1F1F8}"
        case .zhHans: return "\u{1F1E8}\u{1F1F3}"
        case .zhHant: return "\u{1F1F9}\u{1F1FC}"
        case .vi: return "\u{1F1FB}\u{1F1F3}"
        case .fil: return "\u{1F1F5}\u{1F1ED}"
        case .ko: return "\u{1F1F0}\u{1F1F7}"
        case .ru: return "\u{1F1F7}\u{1F1FA}"
        case .fr: return "\u{1F1EB}\u{1F1F7}"
        case .ar: return "\u{1F1F8}\u{1F1E6}"
        }
    }

    public var isRtl: Bool {
        self == .ar
    }

    /// Create from language code, handling common browser/system codes
    public static func from(code: String) -> AppLocale {
        let normalized = code.lowercased()

        // Map common system codes to our locale codes
        switch normalized {
        case "zh-cn", "zh-sg", "zh-hans":
            return .zhHans
        case "zh-tw", "zh-hk", "zh-mo", "zh-hant":
            return .zhHant
        case "tl": // Tagalog -> Filipino
            return .fil
        default:
            // Try direct match
            if let locale = AppLocale(rawValue: code) {
                return locale
            }
            // Try base language match
            let baseLang = normalized.split(separator: "-").first.map(String.init) ?? normalized
            return AppLocale.allCases.first { $0.rawValue.hasPrefix(baseLang) } ?? .en
        }
    }
}

/// Localization service for Bay Navigator apps
/// Fetches translations from the web API and caches them locally
public actor LocalizationService {
    public static let shared = LocalizationService()

    private let baseUrl = "https://baynavigator.org/i18n/json"
    private let localeKey = "baynavigator:locale"
    private let translationsCachePrefix = "baynavigator:i18n_"
    private let cacheDuration: TimeInterval = 7 * 24 * 60 * 60 // 7 days

    private let defaults = UserDefaults.standard

    // In-memory cache of loaded translations
    private var translations: [String: [String: Any]] = [:]

    // Current locale
    public private(set) var currentLocale: AppLocale = .en

    private init() {}

    // MARK: - Initialization

    /// Initialize the localization service
    /// Loads saved locale preference or detects from system
    public func initialize() async {
        // Check for saved locale preference
        if let savedCode = defaults.string(forKey: localeKey) {
            currentLocale = AppLocale.from(code: savedCode)
        } else {
            // Use system locale if supported
            let preferredLanguages = Locale.preferredLanguages
            for lang in preferredLanguages {
                let locale = AppLocale.from(code: lang)
                if locale != .en || lang.hasPrefix("en") {
                    currentLocale = locale
                    break
                }
            }
        }

        // Load translations for current locale
        await loadTranslations(for: currentLocale)
    }

    // MARK: - Locale Management

    /// Set the current locale and persist preference
    public func setLocale(_ locale: AppLocale) async {
        currentLocale = locale
        defaults.set(locale.rawValue, forKey: localeKey)

        // Load translations if not already loaded
        await loadTranslations(for: locale)
    }

    /// Get the current locale (for non-async contexts)
    nonisolated public func getCurrentLocale() -> AppLocale {
        if let savedCode = UserDefaults.standard.string(forKey: "baynavigator:locale") {
            return AppLocale.from(code: savedCode)
        }
        return .en
    }

    // MARK: - Translation Loading

    /// Load translations for a locale
    /// First checks cache, then fetches from web if needed
    public func loadTranslations(for locale: AppLocale) async {
        // Check if already loaded in memory
        if translations[locale.rawValue] != nil {
            return
        }

        // Try to load from cache
        if let cached = loadFromCache(locale.rawValue) {
            translations[locale.rawValue] = cached
            return
        }

        // Fetch from web
        await fetchTranslations(locale.rawValue)
    }

    /// Fetch translations from web API
    private func fetchTranslations(_ localeCode: String) async {
        guard let url = URL(string: "\(baseUrl)/\(localeCode)-ui.json") else {
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                // Try stale cache on error
                if let stale = loadFromCache(localeCode, allowStale: true) {
                    translations[localeCode] = stale
                }
                return
            }

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                translations[localeCode] = json
                saveToCache(localeCode, data: json)
            }
        } catch {
            // Try stale cache on error
            if let stale = loadFromCache(localeCode, allowStale: true) {
                translations[localeCode] = stale
            }
        }
    }

    // MARK: - Cache Management

    private struct CachedTranslations: Codable {
        let timestamp: TimeInterval
        let data: Data
    }

    private func loadFromCache(_ localeCode: String, allowStale: Bool = false) -> [String: Any]? {
        guard let data = defaults.data(forKey: "\(translationsCachePrefix)\(localeCode)") else {
            return nil
        }

        do {
            let cached = try JSONDecoder().decode(CachedTranslations.self, from: data)
            let age = Date().timeIntervalSince1970 - cached.timestamp

            if !allowStale && age > cacheDuration {
                return nil
            }

            return try JSONSerialization.jsonObject(with: cached.data) as? [String: Any]
        } catch {
            return nil
        }
    }

    private func saveToCache(_ localeCode: String, data: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let cached = CachedTranslations(
                timestamp: Date().timeIntervalSince1970,
                data: jsonData
            )
            let encodedData = try JSONEncoder().encode(cached)
            defaults.set(encodedData, forKey: "\(translationsCachePrefix)\(localeCode)")
        } catch {
            // Ignore cache write errors
        }
    }

    /// Clear all cached translations
    public func clearCache() {
        for locale in AppLocale.allCases {
            defaults.removeObject(forKey: "\(translationsCachePrefix)\(locale.rawValue)")
        }
        translations.removeAll()
    }

    // MARK: - Translation Lookup

    /// Get a translation by key
    /// Supports dot notation (e.g., "common.search")
    /// Falls back to English if translation not found
    public func t(_ key: String, params: [String: Any]? = nil) -> String {
        // Try current locale first
        var value = getNestedValue(translations[currentLocale.rawValue], key: key)

        // Fall back to English if not found
        if value == nil && currentLocale != .en {
            value = getNestedValue(translations[AppLocale.en.rawValue], key: key)
        }

        // Return key if still not found
        guard var result = value else {
            return key
        }

        // Interpolate parameters
        if let params = params {
            for (paramKey, paramValue) in params {
                result = result.replacingOccurrences(of: "{\(paramKey)}", with: "\(paramValue)")
            }
        }

        return result
    }

    /// Get nested value from dictionary using dot notation
    private func getNestedValue(_ dict: [String: Any]?, key: String) -> String? {
        guard let dict = dict else { return nil }

        let keys = key.split(separator: ".").map(String.init)
        var current: Any = dict

        for k in keys {
            guard let currentDict = current as? [String: Any],
                  let next = currentDict[k] else {
                return nil
            }
            current = next
        }

        return current as? String
    }

    /// Preload translations for all supported locales
    /// Useful for offline support
    public func preloadAllTranslations() async {
        for locale in AppLocale.allCases {
            await loadTranslations(for: locale)
        }
    }
}
