import Foundation

actor CacheService {
    static let shared = CacheService()

    private let defaults = UserDefaults.standard
    private let cacheDuration: TimeInterval = 24 * 60 * 60 // 24 hours

    enum CacheKey: String {
        case programs = "bay_area_discounts:programs"
        case categories = "bay_area_discounts:categories"
        case groups = "bay_area_discounts:groups"
        case areas = "bay_area_discounts:areas"
        case metadata = "bay_area_discounts:metadata"
        case favorites = "bay_area_discounts:favorites"
        case themeMode = "bay_area_discounts:theme_mode"
        case warmMode = "bay_area_discounts:warm_mode"
        case userGroups = "bay_area_discounts:user_groups"
        case userCounty = "bay_area_discounts:user_county"
        case onboardingComplete = "bay_area_discounts:onboarding_complete"
    }

    private struct CachedData<T: Codable>: Codable {
        let data: T
        let timestamp: TimeInterval
    }

    // MARK: - Generic Cache Operations

    func get<T: Codable>(forKey key: CacheKey, allowStale: Bool = false) -> T? {
        guard let jsonData = defaults.data(forKey: key.rawValue) else {
            return nil
        }

        do {
            let cached = try JSONDecoder().decode(CachedData<T>.self, from: jsonData)
            let age = Date().timeIntervalSince1970 - cached.timestamp

            if !allowStale && age > cacheDuration {
                return nil
            }

            return cached.data
        } catch {
            return nil
        }
    }

    func set<T: Codable>(_ value: T, forKey key: CacheKey) {
        let cached = CachedData(data: value, timestamp: Date().timeIntervalSince1970)

        do {
            let jsonData = try JSONEncoder().encode(cached)
            defaults.set(jsonData, forKey: key.rawValue)
        } catch {
            // Cache write failed, continue silently
        }
    }

    func remove(forKey key: CacheKey) {
        defaults.removeObject(forKey: key.rawValue)
    }

    // MARK: - Favorites (not time-cached)

    func getFavorites() -> Set<String> {
        guard let data = defaults.data(forKey: CacheKey.favorites.rawValue),
              let favorites = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            return []
        }
        return favorites
    }

    func setFavorites(_ favorites: Set<String>) {
        if let data = try? JSONEncoder().encode(favorites) {
            defaults.set(data, forKey: CacheKey.favorites.rawValue)
        }
    }

    func addFavorite(_ id: String) {
        var favorites = getFavorites()
        favorites.insert(id)
        setFavorites(favorites)
    }

    func removeFavorite(_ id: String) {
        var favorites = getFavorites()
        favorites.remove(id)
        setFavorites(favorites)
    }

    func isFavorite(_ id: String) -> Bool {
        getFavorites().contains(id)
    }

    // MARK: - Theme

    func getThemeMode() -> String? {
        defaults.string(forKey: CacheKey.themeMode.rawValue)
    }

    func setThemeMode(_ mode: String) {
        defaults.set(mode, forKey: CacheKey.themeMode.rawValue)
    }

    // MARK: - Warm Mode (Night Shift alternative)

    func getWarmMode() -> Bool {
        defaults.bool(forKey: CacheKey.warmMode.rawValue)
    }

    func setWarmMode(_ enabled: Bool) {
        defaults.set(enabled, forKey: CacheKey.warmMode.rawValue)
    }

    // MARK: - User Preferences (Onboarding)

    func getUserGroups() -> [String] {
        guard let data = defaults.data(forKey: CacheKey.userGroups.rawValue),
              let groups = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return groups
    }

    func setUserGroups(_ groups: [String]) {
        if let data = try? JSONEncoder().encode(groups) {
            defaults.set(data, forKey: CacheKey.userGroups.rawValue)
        }
    }

    func getUserCounty() -> String? {
        defaults.string(forKey: CacheKey.userCounty.rawValue)
    }

    func setUserCounty(_ county: String?) {
        if let county = county {
            defaults.set(county, forKey: CacheKey.userCounty.rawValue)
        } else {
            defaults.removeObject(forKey: CacheKey.userCounty.rawValue)
        }
    }

    func isOnboardingComplete() -> Bool {
        defaults.bool(forKey: CacheKey.onboardingComplete.rawValue)
    }

    func setOnboardingComplete(_ complete: Bool) {
        defaults.set(complete, forKey: CacheKey.onboardingComplete.rawValue)
    }

    func hasUserPreferences() -> Bool {
        !getUserGroups().isEmpty || getUserCounty() != nil
    }

    // MARK: - Cache Management

    func clearCache() {
        let keys: [CacheKey] = [.programs, .categories, .groups, .areas, .metadata]
        for key in keys {
            remove(forKey: key)
        }
    }

    func getCacheSize() -> Int {
        let keys: [CacheKey] = [.programs, .categories, .groups, .areas, .metadata, .favorites]
        var totalSize = 0

        for key in keys {
            if let data = defaults.data(forKey: key.rawValue) {
                totalSize += data.count
            }
        }

        return totalSize
    }

    var formattedCacheSize: String {
        let size = getCacheSize()
        if size < 1024 {
            return "\(size) B"
        } else if size < 1024 * 1024 {
            return String(format: "%.1f KB", Double(size) / 1024)
        } else {
            return String(format: "%.1f MB", Double(size) / (1024 * 1024))
        }
    }
}
