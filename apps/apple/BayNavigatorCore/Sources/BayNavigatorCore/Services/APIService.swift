import Foundation

public actor APIService {
    public static let shared = APIService()

    private let cache = CacheService.shared
    private let privacyService = PrivacyService.shared
    private let safetyService = SafetyService.shared
    private let cacheDuration: TimeInterval = 24 * 60 * 60 // 24 hours

    /// URLSession cache - recreated when privacy mode changes
    private var currentSession: URLSession?
    private var currentPrivacyMode: PrivacyService.PrivacyMode?

    private init() {}

    // MARK: - Session Management

    /// Get the appropriate base URL based on privacy settings
    private func getBaseURL() async -> String {
        let baseURL = await privacyService.getBaseURL()
        // Append /api path for API calls
        return "\(baseURL)/api"
    }

    /// Get the appropriate URLSession based on privacy settings
    private func getSession() async -> URLSession {
        let mode = await privacyService.getPrivacyMode()

        // Reuse session if mode hasn't changed
        if let session = currentSession, mode == currentPrivacyMode {
            return session
        }

        // Create new session for current privacy mode
        let config = await privacyService.createURLSessionConfiguration()
        let session = URLSession(configuration: config)
        currentSession = session
        currentPrivacyMode = mode
        return session
    }

    /// Invalidate cached session (call when privacy settings change)
    public func invalidateSession() {
        currentSession?.invalidateAndCancel()
        currentSession = nil
        currentPrivacyMode = nil
    }

    /// Check if requests should be blocked (offline mode)
    private func shouldBlockRequests() async -> Bool {
        await safetyService.isOfflineModeEnabled()
    }

    // MARK: - API Calls

    public func getPrograms(forceRefresh: Bool = false) async throws -> [Program] {
        // Check cache first
        if !forceRefresh, let cached: [Program] = await cache.get(forKey: .programs) {
            return cached
        }

        // In offline mode, only use cache
        if await shouldBlockRequests() {
            if let cached: [Program] = await cache.get(forKey: .programs, allowStale: true) {
                return cached
            }
            throw APIError.offlineMode
        }

        do {
            let baseURL = await getBaseURL()
            let session = await getSession()
            let url = URL(string: "\(baseURL)/programs.json")!
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
            }

            let decoded = try JSONDecoder().decode(ProgramsResponse.self, from: data)
            await cache.set(decoded.programs, forKey: .programs)
            return decoded.programs
        } catch {
            // Try stale cache on error
            if let cached: [Program] = await cache.get(forKey: .programs, allowStale: true) {
                return cached
            }
            throw error
        }
    }

    public func getCategories(forceRefresh: Bool = false) async throws -> [ProgramCategory] {
        if !forceRefresh, let cached: [ProgramCategory] = await cache.get(forKey: .categories) {
            return cached
        }

        if await shouldBlockRequests() {
            if let cached: [ProgramCategory] = await cache.get(forKey: .categories, allowStale: true) {
                return cached
            }
            throw APIError.offlineMode
        }

        do {
            let baseURL = await getBaseURL()
            let session = await getSession()
            let url = URL(string: "\(baseURL)/categories.json")!
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
            }

            let decoded = try JSONDecoder().decode(CategoriesResponse.self, from: data)
            await cache.set(decoded.categories, forKey: .categories)
            return decoded.categories
        } catch {
            if let cached: [ProgramCategory] = await cache.get(forKey: .categories, allowStale: true) {
                return cached
            }
            throw error
        }
    }

    public func getGroups(forceRefresh: Bool = false) async throws -> [ProgramGroup] {
        if !forceRefresh, let cached: [ProgramGroup] = await cache.get(forKey: .groups) {
            return cached
        }

        if await shouldBlockRequests() {
            if let cached: [ProgramGroup] = await cache.get(forKey: .groups, allowStale: true) {
                return cached
            }
            throw APIError.offlineMode
        }

        do {
            let baseURL = await getBaseURL()
            let session = await getSession()
            let url = URL(string: "\(baseURL)/groups.json")!
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
            }

            let decoded = try JSONDecoder().decode(GroupsResponse.self, from: data)
            await cache.set(decoded.groups, forKey: .groups)
            return decoded.groups
        } catch {
            if let cached: [ProgramGroup] = await cache.get(forKey: .groups, allowStale: true) {
                return cached
            }
            throw error
        }
    }

    public func getAreas(forceRefresh: Bool = false) async throws -> [Area] {
        if !forceRefresh, let cached: [Area] = await cache.get(forKey: .areas) {
            return cached
        }

        if await shouldBlockRequests() {
            if let cached: [Area] = await cache.get(forKey: .areas, allowStale: true) {
                return cached
            }
            throw APIError.offlineMode
        }

        do {
            let baseURL = await getBaseURL()
            let session = await getSession()
            let url = URL(string: "\(baseURL)/areas.json")!
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
            }

            let decoded = try JSONDecoder().decode(AreasResponse.self, from: data)
            await cache.set(decoded.areas, forKey: .areas)
            return decoded.areas
        } catch {
            if let cached: [Area] = await cache.get(forKey: .areas, allowStale: true) {
                return cached
            }
            throw error
        }
    }

    public func getMetadata(forceRefresh: Bool = false) async throws -> APIMetadata {
        if !forceRefresh, let cached: APIMetadata = await cache.get(forKey: .metadata) {
            return cached
        }

        if await shouldBlockRequests() {
            if let cached: APIMetadata = await cache.get(forKey: .metadata, allowStale: true) {
                return cached
            }
            throw APIError.offlineMode
        }

        do {
            let baseURL = await getBaseURL()
            let session = await getSession()
            let url = URL(string: "\(baseURL)/metadata.json")!
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
            }

            let decoded = try JSONDecoder().decode(APIMetadata.self, from: data)
            await cache.set(decoded, forKey: .metadata)
            return decoded
        } catch {
            if let cached: APIMetadata = await cache.get(forKey: .metadata, allowStale: true) {
                return cached
            }
            throw error
        }
    }

    /// Fetch program coordinates from GeoJSON file
    public func getProgramCoordinates(forceRefresh: Bool = false) async throws -> [String: (latitude: Double, longitude: Double)] {
        if !forceRefresh, let cached: [String: [Double]] = await cache.get(forKey: .programCoordinates) {
            var result: [String: (latitude: Double, longitude: Double)] = [:]
            for (id, coords) in cached where coords.count == 2 {
                result[id] = (latitude: coords[1], longitude: coords[0])
            }
            return result
        }

        if await shouldBlockRequests() {
            if let cached: [String: [Double]] = await cache.get(forKey: .programCoordinates, allowStale: true) {
                var result: [String: (latitude: Double, longitude: Double)] = [:]
                for (id, coords) in cached where coords.count == 2 {
                    result[id] = (latitude: coords[1], longitude: coords[0])
                }
                return result
            }
            throw APIError.offlineMode
        }

        do {
            let baseURL = await getBaseURL()
            let session = await getSession()
            let url = URL(string: "\(baseURL)/programs.geojson")!
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
            }

            let decoded = try JSONDecoder().decode(GeoJSONFeatureCollection.self, from: data)

            // Extract coordinates keyed by program ID
            var result: [String: (latitude: Double, longitude: Double)] = [:]
            var cacheData: [String: [Double]] = [:]

            for feature in decoded.features {
                let id = feature.properties.id
                let coords = feature.geometry.coordinates
                // GeoJSON uses [longitude, latitude] order
                result[id] = (latitude: coords[1], longitude: coords[0])
                cacheData[id] = coords
            }

            await cache.set(cacheData, forKey: .programCoordinates)
            return result
        } catch {
            if let cached: [String: [Double]] = await cache.get(forKey: .programCoordinates, allowStale: true) {
                var result: [String: (latitude: Double, longitude: Double)] = [:]
                for (id, coords) in cached where coords.count == 2 {
                    result[id] = (latitude: coords[1], longitude: coords[0])
                }
                return result
            }
            throw error
        }
    }

    /// Pre-cache all data for offline use
    /// Call this when the app launches or when user enables offline mode
    public func preCacheAllData() async {
        // Fetch all data types to populate cache
        _ = try? await getPrograms(forceRefresh: true)
        _ = try? await getCategories(forceRefresh: true)
        _ = try? await getGroups(forceRefresh: true)
        _ = try? await getAreas(forceRefresh: true)
        _ = try? await getMetadata(forceRefresh: true)
        _ = try? await getProgramCoordinates(forceRefresh: true)
    }
}

// MARK: - GeoJSON Models

struct GeoJSONFeatureCollection: Codable, Sendable {
    let type: String
    let features: [GeoJSONFeature]
}

struct GeoJSONFeature: Codable, Sendable {
    let type: String
    let geometry: GeoJSONGeometry
    let properties: GeoJSONProperties
}

struct GeoJSONGeometry: Codable, Sendable {
    let type: String
    let coordinates: [Double]
}

struct GeoJSONProperties: Codable, Sendable {
    let id: String
    let name: String
    let category: String
}

public enum APIError: LocalizedError, Sendable {
    case httpError(Int)
    case decodingError
    case networkError
    case offlineMode

    public var errorDescription: String? {
        switch self {
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network error"
        case .offlineMode:
            return "Offline mode is enabled. Using cached data."
        }
    }
}
