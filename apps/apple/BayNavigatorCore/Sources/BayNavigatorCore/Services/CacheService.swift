import Foundation

public actor CacheService {
    public static let shared = CacheService()

    private let defaults = UserDefaults.standard
    private let cacheDuration: TimeInterval = 24 * 60 * 60 // 24 hours

    public enum CacheKey: String, Sendable {
        case programs = "baynavigator:programs"
        case categories = "baynavigator:categories"
        case groups = "baynavigator:groups"
        case areas = "baynavigator:areas"
        case metadata = "baynavigator:metadata"
        case programCoordinates = "baynavigator:program_coordinates"
        case favorites = "baynavigator:favorites"
        case themeMode = "baynavigator:theme_mode"
        case warmMode = "baynavigator:warm_mode"
        case locale = "baynavigator:locale"
        case userGroups = "baynavigator:user_groups"
        case userCounty = "baynavigator:user_county"
        case onboardingComplete = "baynavigator:onboarding_complete"
        case aiSearchEnabled = "baynavigator:ai_search_enabled"
        // New user profile fields
        case userFirstName = "baynavigator:user_first_name"
        case userCity = "baynavigator:user_city"
        case userZipCode = "baynavigator:user_zip_code"
        case userBirthYear = "baynavigator:user_birth_year"
        case userQualifications = "baynavigator:user_qualifications"
        case userIsMilitary = "baynavigator:user_is_military"
        case userProfileColorIndex = "baynavigator:user_profile_color_index"
        // Privacy settings
        case crashReportingEnabled = "baynavigator:crash_reporting_enabled"
        case shareProfileWithCarl = "baynavigator:share_profile_with_carl"
    }

    private struct CachedData<T: Codable>: Codable {
        let data: T
        let timestamp: TimeInterval
    }

    // MARK: - Generic Cache Operations

    public func get<T: Codable>(forKey key: CacheKey, allowStale: Bool = false) -> T? {
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

    public func set<T: Codable>(_ value: T, forKey key: CacheKey) {
        let cached = CachedData(data: value, timestamp: Date().timeIntervalSince1970)

        do {
            let jsonData = try JSONEncoder().encode(cached)
            defaults.set(jsonData, forKey: key.rawValue)
        } catch {
            // Cache write failed, continue silently
        }
    }

    public func remove(forKey key: CacheKey) {
        defaults.removeObject(forKey: key.rawValue)
    }

    // MARK: - Favorites (not time-cached)

    private static let favoriteItemsKey = "baynavigator:favorite_items"

    public func getFavorites() -> Set<String> {
        guard let data = defaults.data(forKey: CacheKey.favorites.rawValue),
              let favorites = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            return []
        }
        return favorites
    }

    public func setFavorites(_ favorites: Set<String>) {
        if let data = try? JSONEncoder().encode(favorites) {
            defaults.set(data, forKey: CacheKey.favorites.rawValue)
        }
    }

    /// Get all favorite items with status and notes
    public func getFavoriteItems() -> [FavoriteItem] {
        guard let data = defaults.data(forKey: Self.favoriteItemsKey),
              let items = try? JSONDecoder().decode([FavoriteItem].self, from: data) else {
            // Migrate from old format if needed
            let legacyFavorites = getFavorites()
            if !legacyFavorites.isEmpty {
                let items = legacyFavorites.map { FavoriteItem(programId: $0) }
                saveFavoriteItems(items)
                return items
            }
            return []
        }
        return items
    }

    private func saveFavoriteItems(_ items: [FavoriteItem]) {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: Self.favoriteItemsKey)
        }
        // Keep legacy format in sync
        setFavorites(Set(items.map { $0.programId }))
    }

    public func addFavorite(_ id: String) {
        var items = getFavoriteItems()
        if !items.contains(where: { $0.programId == id }) {
            items.append(FavoriteItem(programId: id))
            saveFavoriteItems(items)
        }
    }

    public func removeFavorite(_ id: String) {
        var items = getFavoriteItems()
        items.removeAll { $0.programId == id }
        saveFavoriteItems(items)
    }

    public func isFavorite(_ id: String) -> Bool {
        getFavoriteItems().contains { $0.programId == id }
    }

    /// Get favorite item for a specific program
    public func getFavoriteItem(_ programId: String) -> FavoriteItem? {
        getFavoriteItems().first { $0.programId == programId }
    }

    /// Update status for a favorite item
    public func updateFavoriteStatus(_ programId: String, status: FavoriteStatus) {
        var items = getFavoriteItems()
        if let index = items.firstIndex(where: { $0.programId == programId }) {
            items[index].status = status
            items[index].statusUpdatedAt = Date()
            saveFavoriteItems(items)
        }
    }

    /// Update notes for a favorite item
    public func updateFavoriteNotes(_ programId: String, notes: String?) {
        var items = getFavoriteItems()
        if let index = items.firstIndex(where: { $0.programId == programId }) {
            items[index].notes = notes
            items[index].statusUpdatedAt = Date()
            saveFavoriteItems(items)
        }
    }

    // MARK: - Theme

    public func getThemeMode() -> String? {
        defaults.string(forKey: CacheKey.themeMode.rawValue)
    }

    public func setThemeMode(_ mode: String) {
        defaults.set(mode, forKey: CacheKey.themeMode.rawValue)
    }

    // MARK: - Warm Mode (Night Shift alternative)

    public func getWarmMode() -> Bool {
        defaults.bool(forKey: CacheKey.warmMode.rawValue)
    }

    public func setWarmMode(_ enabled: Bool) {
        defaults.set(enabled, forKey: CacheKey.warmMode.rawValue)
    }

    // MARK: - Locale

    public func getLocale() -> String? {
        defaults.string(forKey: CacheKey.locale.rawValue)
    }

    public func setLocale(_ code: String) {
        defaults.set(code, forKey: CacheKey.locale.rawValue)
    }

    // MARK: - AI Search

    public func getAISearchEnabled() -> Bool {
        // Default to true if not set
        if defaults.object(forKey: CacheKey.aiSearchEnabled.rawValue) == nil {
            return true
        }
        return defaults.bool(forKey: CacheKey.aiSearchEnabled.rawValue)
    }

    public func setAISearchEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: CacheKey.aiSearchEnabled.rawValue)
    }

    // MARK: - User Preferences (Onboarding)

    public func getUserGroups() -> [String] {
        guard let data = defaults.data(forKey: CacheKey.userGroups.rawValue),
              let groups = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return groups
    }

    public func setUserGroups(_ groups: [String]) {
        if let data = try? JSONEncoder().encode(groups) {
            defaults.set(data, forKey: CacheKey.userGroups.rawValue)
        }
    }

    public func getUserCounty() -> String? {
        defaults.string(forKey: CacheKey.userCounty.rawValue)
    }

    public func setUserCounty(_ county: String?) {
        if let county = county {
            defaults.set(county, forKey: CacheKey.userCounty.rawValue)
        } else {
            defaults.removeObject(forKey: CacheKey.userCounty.rawValue)
        }
    }

    public func isOnboardingComplete() -> Bool {
        defaults.bool(forKey: CacheKey.onboardingComplete.rawValue)
    }

    public func setOnboardingComplete(_ complete: Bool) {
        defaults.set(complete, forKey: CacheKey.onboardingComplete.rawValue)
    }

    public func hasUserPreferences() -> Bool {
        !getUserGroups().isEmpty || getUserCounty() != nil || getUserFirstName() != nil
    }

    // MARK: - User Profile Fields

    public func getUserFirstName() -> String? {
        defaults.string(forKey: CacheKey.userFirstName.rawValue)
    }

    public func setUserFirstName(_ name: String?) {
        if let name = name {
            defaults.set(name, forKey: CacheKey.userFirstName.rawValue)
        } else {
            defaults.removeObject(forKey: CacheKey.userFirstName.rawValue)
        }
    }

    public func getUserCity() -> String? {
        defaults.string(forKey: CacheKey.userCity.rawValue)
    }

    public func setUserCity(_ city: String?) {
        if let city = city {
            defaults.set(city, forKey: CacheKey.userCity.rawValue)
        } else {
            defaults.removeObject(forKey: CacheKey.userCity.rawValue)
        }
    }

    public func getUserZipCode() -> String? {
        defaults.string(forKey: CacheKey.userZipCode.rawValue)
    }

    public func setUserZipCode(_ zipCode: String?) {
        if let zipCode = zipCode {
            defaults.set(zipCode, forKey: CacheKey.userZipCode.rawValue)
        } else {
            defaults.removeObject(forKey: CacheKey.userZipCode.rawValue)
        }
    }

    public func getUserBirthYear() -> Int? {
        let value = defaults.integer(forKey: CacheKey.userBirthYear.rawValue)
        return value > 0 ? value : nil
    }

    public func setUserBirthYear(_ year: Int?) {
        if let year = year {
            defaults.set(year, forKey: CacheKey.userBirthYear.rawValue)
        } else {
            defaults.removeObject(forKey: CacheKey.userBirthYear.rawValue)
        }
    }

    public func getUserQualifications() -> [String] {
        guard let data = defaults.data(forKey: CacheKey.userQualifications.rawValue),
              let qualifications = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return qualifications
    }

    public func setUserQualifications(_ qualifications: [String]) {
        if let data = try? JSONEncoder().encode(qualifications) {
            defaults.set(data, forKey: CacheKey.userQualifications.rawValue)
        }
    }

    public func getUserIsMilitary() -> Bool? {
        if defaults.object(forKey: CacheKey.userIsMilitary.rawValue) == nil {
            return nil
        }
        return defaults.bool(forKey: CacheKey.userIsMilitary.rawValue)
    }

    public func setUserIsMilitary(_ isMilitary: Bool?) {
        if let isMilitary = isMilitary {
            defaults.set(isMilitary, forKey: CacheKey.userIsMilitary.rawValue)
        } else {
            defaults.removeObject(forKey: CacheKey.userIsMilitary.rawValue)
        }
    }

    public func getUserProfileColorIndex() -> Int {
        let value = defaults.integer(forKey: CacheKey.userProfileColorIndex.rawValue)
        return value
    }

    public func setUserProfileColorIndex(_ index: Int) {
        defaults.set(index, forKey: CacheKey.userProfileColorIndex.rawValue)
    }

    // MARK: - Privacy Settings

    public func getCrashReportingEnabled() -> Bool {
        // Default to true (opt-in by default) if not set
        if defaults.object(forKey: CacheKey.crashReportingEnabled.rawValue) == nil {
            return true
        }
        return defaults.bool(forKey: CacheKey.crashReportingEnabled.rawValue)
    }

    public func setCrashReportingEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: CacheKey.crashReportingEnabled.rawValue)
    }

    public func getShareProfileWithCarl() -> Bool {
        // Default to false (opt-in required) if not set
        if defaults.object(forKey: CacheKey.shareProfileWithCarl.rawValue) == nil {
            return false
        }
        return defaults.bool(forKey: CacheKey.shareProfileWithCarl.rawValue)
    }

    public func setShareProfileWithCarl(_ enabled: Bool) {
        defaults.set(enabled, forKey: CacheKey.shareProfileWithCarl.rawValue)
    }

    // MARK: - Cache Management

    public func clearCache() {
        let keys: [CacheKey] = [.programs, .categories, .groups, .areas, .metadata]
        for key in keys {
            remove(forKey: key)
        }
    }

    public func getCacheSize() -> Int {
        let keys: [CacheKey] = [.programs, .categories, .groups, .areas, .metadata, .favorites]
        var totalSize = 0

        for key in keys {
            if let data = defaults.data(forKey: key.rawValue) {
                totalSize += data.count
            }
        }

        return totalSize
    }

    public var formattedCacheSize: String {
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
