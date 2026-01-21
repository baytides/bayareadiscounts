import Foundation

// MARK: - Transit Models

/// Represents a Bay Area transit agency
public struct TransitAgency: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let type: TransitType
    public let color: String
    public let stations: Int

    public init(id: String, name: String, type: TransitType, color: String, stations: Int) {
        self.id = id
        self.name = name
        self.type = type
        self.color = color
        self.stations = stations
    }

    /// Get the label for station count based on type
    public var stationLabel: String {
        switch type {
        case .ferry: return "terminals"
        case .bus: return "stops"
        case .rail: return "stations"
        }
    }

    /// Get agency website URL
    public var websiteURL: URL? {
        let urlString: String
        switch id {
        case "BA": urlString = "https://www.bart.gov"
        case "CT": urlString = "https://www.caltrain.com"
        case "SF": urlString = "https://www.sfmta.com"
        case "AC": urlString = "https://www.actransit.org"
        case "SC": urlString = "https://www.vta.org"
        case "SM": urlString = "https://www.samtrans.com"
        case "GG": urlString = "https://www.goldengate.org/bus"
        case "SA": urlString = "https://www.sonomamarintrain.org"
        case "GF": urlString = "https://www.goldengate.org/ferry"
        case "SB": urlString = "https://sanfranciscobayferry.com"
        case "CC": urlString = "https://countyconnection.com"
        case "WH": urlString = "https://www.wheelsbus.com"
        case "MA": urlString = "https://marintransit.org"
        case "3D": urlString = "https://trideltatransit.com"
        case "WC": urlString = "https://www.westcat.org"
        case "UC": urlString = "https://www.unioncity.org/transit"
        case "CE": urlString = "https://acerail.com"
        case "AM": urlString = "https://www.capitolcorridor.org"
        default: urlString = "https://511.org"
        }
        return URL(string: urlString)
    }

    /// Get alerts page URL
    public var alertsURL: URL? {
        let urlString: String
        switch id {
        case "BA": urlString = "https://www.bart.gov/schedules/advisories"
        case "CT": urlString = "https://www.caltrain.com/alerts"
        case "SF": urlString = "https://www.sfmta.com/getting-around/transit/routes-stops"
        case "AC": urlString = "https://www.actransit.org/service-notices"
        case "SC": urlString = "https://www.vta.org/go/alerts"
        case "SM": urlString = "https://www.samtrans.com/alerts"
        case "GG": urlString = "https://www.goldengate.org/alerts"
        case "SA": urlString = "https://www.sonomamarintrain.org/alerts"
        case "GF": urlString = "https://www.goldengate.org/alerts"
        case "SB": urlString = "https://sanfranciscobayferry.com/service-alerts"
        default: urlString = "https://511.org/transit/alerts"
        }
        return URL(string: urlString)
    }
}

/// Transit type enumeration
public enum TransitType: String, Codable, Sendable, CaseIterable {
    case rail
    case ferry
    case bus
}

/// Alert severity level
public enum AlertSeverity: String, Codable, Sendable {
    case severe
    case moderate
    case minor
    case info

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self).lowercased()
        switch value {
        case "severe", "critical", "emergency": self = .severe
        case "moderate", "warning": self = .moderate
        case "minor", "low": self = .minor
        default: self = .info
        }
    }
}

/// Represents a transit service alert
public struct TransitAlert: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let agencies: [String]
    public let url: URL?
    public let timeAgo: String
    public let startTime: Int
    public let severity: AlertSeverity

    public init(
        id: String,
        title: String,
        agencies: [String],
        url: URL? = nil,
        timeAgo: String = "",
        startTime: Int = 0,
        severity: AlertSeverity = .info
    ) {
        self.id = id
        self.title = title
        self.agencies = agencies
        self.url = url
        self.timeAgo = timeAgo
        self.startTime = startTime
        self.severity = severity
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: TransitAlert, rhs: TransitAlert) -> Bool {
        lhs.id == rhs.id
    }
}

/// Response from the transit alerts API
public struct TransitAlertsResponse: Codable, Sendable {
    public let alerts: [TransitAlert]
    public let totalAlerts: Int
    public let fetchedAt: String

    public init(alerts: [TransitAlert], totalAlerts: Int, fetchedAt: String) {
        self.alerts = alerts
        self.totalAlerts = totalAlerts
        self.fetchedAt = fetchedAt
    }
}

// MARK: - Transit Service

/// Service for fetching transit agency info and alerts
public actor TransitService {
    public static let shared = TransitService()

    private let alertsAPIURL = "https://baytides-integrity.azurewebsites.net/api/transit-alerts"
    private let session: URLSession
    private let cacheDuration: TimeInterval = 5 * 60 // 5 minutes
    private let requestTimeout: TimeInterval = 10

    // In-memory cache
    private var cachedResponse: TransitAlertsResponse?
    private var cacheTimestamp: Date?

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = requestTimeout
        self.session = URLSession(configuration: config)
    }

    // MARK: - Static Agency Data

    /// Get the list of Bay Area transit agencies
    public nonisolated func getAgencies() -> [TransitAgency] {
        [
            // Rail services
            TransitAgency(id: "BA", name: "BART", type: .rail, color: "#009bda", stations: 50),
            TransitAgency(id: "CT", name: "Caltrain", type: .rail, color: "#e31837", stations: 30),
            TransitAgency(id: "SA", name: "SMART", type: .rail, color: "#0072bc", stations: 14),
            TransitAgency(id: "CE", name: "ACE Rail", type: .rail, color: "#8b4513", stations: 10),
            TransitAgency(id: "AM", name: "Capitol Corridor", type: .rail, color: "#00467f", stations: 20),

            // Ferry services
            TransitAgency(id: "GF", name: "Golden Gate Ferry", type: .ferry, color: "#c41230", stations: 6),
            TransitAgency(id: "SB", name: "SF Bay Ferry", type: .ferry, color: "#1e3a5f", stations: 11),

            // Bus services
            TransitAgency(id: "SF", name: "SF Muni", type: .bus, color: "#bc2026", stations: 3243),
            TransitAgency(id: "AC", name: "AC Transit", type: .bus, color: "#00a94f", stations: 4717),
            TransitAgency(id: "SC", name: "VTA", type: .bus, color: "#0065b8", stations: 3134),
            TransitAgency(id: "SM", name: "SamTrans", type: .bus, color: "#e31837", stations: 1882),
            TransitAgency(id: "GG", name: "Golden Gate Transit", type: .bus, color: "#c41230", stations: 275),
            TransitAgency(id: "CC", name: "County Connection", type: .bus, color: "#0072bb", stations: 1182),
            TransitAgency(id: "WH", name: "Wheels (Livermore)", type: .bus, color: "#00a859", stations: 666),
            TransitAgency(id: "MA", name: "Marin Transit", type: .bus, color: "#00529b", stations: 545),
            TransitAgency(id: "3D", name: "Tri Delta Transit", type: .bus, color: "#e21f26", stations: 440),
            TransitAgency(id: "WC", name: "WestCAT", type: .bus, color: "#ed1c24", stations: 211),
            TransitAgency(id: "UC", name: "Union City Transit", type: .bus, color: "#0072bc", stations: 159),
        ]
    }

    /// Get agencies by type
    public nonisolated func getAgenciesByType(_ type: TransitType) -> [TransitAgency] {
        getAgencies().filter { $0.type == type }
    }

    /// Get agency by ID
    public nonisolated func getAgency(byId id: String) -> TransitAgency? {
        getAgencies().first { $0.id == id }
    }

    // MARK: - Alert Fetching

    /// Fetch live transit alerts from the API
    public func fetchAlerts(forceRefresh: Bool = false) async throws -> TransitAlertsResponse {
        // Check cache first
        if !forceRefresh, let cached = cachedResponse, let timestamp = cacheTimestamp {
            let age = Date().timeIntervalSince(timestamp)
            if age < cacheDuration {
                return cached
            }
        }

        do {
            guard let url = URL(string: alertsAPIURL) else {
                throw TransitServiceError.invalidURL
            }

            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw TransitServiceError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw TransitServiceError.httpError(httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            let alertsResponse = try decoder.decode(TransitAlertsResponse.self, from: data)

            // Update cache
            cachedResponse = alertsResponse
            cacheTimestamp = Date()

            return alertsResponse
        } catch let error as TransitServiceError {
            // Try to return stale cache on error
            if let cached = cachedResponse {
                return cached
            }
            throw error
        } catch {
            // Try to return stale cache on error
            if let cached = cachedResponse {
                return cached
            }
            throw TransitServiceError.networkError(error)
        }
    }

    /// Get alerts for a specific agency
    public func getAlertsForAgency(_ agencyId: String) async throws -> [TransitAlert] {
        let response = try await fetchAlerts()
        return response.alerts.filter { $0.agencies.contains(agencyId) }
    }

    /// Get count of alerts per agency
    public func getAlertCounts() async throws -> [String: Int] {
        let response = try await fetchAlerts()
        var counts: [String: Int] = [:]

        for alert in response.alerts {
            for agencyId in alert.agencies {
                counts[agencyId, default: 0] += 1
            }
        }

        return counts
    }

    /// Clear the in-memory cache
    public func clearCache() {
        cachedResponse = nil
        cacheTimestamp = nil
    }
}

// MARK: - Errors

public enum TransitServiceError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case networkError(Error)
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
