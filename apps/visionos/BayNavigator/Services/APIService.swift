import Foundation

actor APIService {
    static let shared = APIService()

    private let baseURL = "https://baynavigator.org/api"
    private let session: URLSession
    private let cache = CacheService.shared
    private let cacheDuration: TimeInterval = 24 * 60 * 60 // 24 hours
    private let requestTimeout: TimeInterval = 12

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = requestTimeout
        self.session = URLSession(configuration: config)
    }

    // MARK: - API Calls

    func getPrograms(forceRefresh: Bool = false) async throws -> [Program] {
        if !forceRefresh, let cached: [Program] = await cache.get(forKey: .programs) {
            return cached
        }

        do {
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

    func getCategories(forceRefresh: Bool = false) async throws -> [ProgramCategory] {
        if !forceRefresh, let cached: [ProgramCategory] = await cache.get(forKey: .categories) {
            return cached
        }

        do {
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

    func getGroups(forceRefresh: Bool = false) async throws -> [ProgramGroup] {
        if !forceRefresh, let cached: [ProgramGroup] = await cache.get(forKey: .groups) {
            return cached
        }

        do {
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

    func getAreas(forceRefresh: Bool = false) async throws -> [Area] {
        if !forceRefresh, let cached: [Area] = await cache.get(forKey: .areas) {
            return cached
        }

        do {
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

    func getMetadata(forceRefresh: Bool = false) async throws -> APIMetadata {
        if !forceRefresh, let cached: APIMetadata = await cache.get(forKey: .metadata) {
            return cached
        }

        do {
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
}

enum APIError: LocalizedError {
    case httpError(Int)
    case decodingError
    case networkError

    var errorDescription: String? {
        switch self {
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network error"
        }
    }
}
