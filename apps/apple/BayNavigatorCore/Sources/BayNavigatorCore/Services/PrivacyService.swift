import Foundation
import Network

/// Privacy service for Bay Navigator
/// Provides censorship circumvention features similar to Signal
/// - Tor/Onion routing (requires system Tor client)
/// - Custom proxy support (SOCKS5/HTTP)
/// - Privacy-first network configuration
public actor PrivacyService {
    public static let shared = PrivacyService()

    // MARK: - Constants

    /// Standard clearnet API endpoint
    public static let clearnetBaseURL = "https://baynavigator.org"

    /// Tor hidden service endpoint (requires Tor client)
    public static let onionBaseURL = "http://7u42bzioq3cbud5rmey3sfx4odvjfryjifwx4ozonihdtdrykwjifkad.onion"

    /// Default Tor SOCKS5 proxy port
    public static let torSocks5Port = 9050

    // MARK: - Cache Keys

    private let useOnionKey = "baynavigator:use_onion"
    private let proxyEnabledKey = "baynavigator:proxy_enabled"
    private let proxyHostKey = "baynavigator:proxy_host"
    private let proxyPortKey = "baynavigator:proxy_port"
    private let proxyTypeKey = "baynavigator:proxy_type"

    private init() {}

    // MARK: - Settings Persistence

    /// Check if onion routing is enabled
    public func isOnionEnabled() -> Bool {
        UserDefaults.standard.bool(forKey: useOnionKey)
    }

    /// Enable or disable onion routing
    public func setOnionEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: useOnionKey)
    }

    /// Check if custom proxy is enabled
    public func isProxyEnabled() -> Bool {
        UserDefaults.standard.bool(forKey: proxyEnabledKey)
    }

    /// Enable or disable custom proxy
    public func setProxyEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: proxyEnabledKey)
    }

    /// Get proxy configuration
    public func getProxyConfig() -> ProxyConfig? {
        guard let host = UserDefaults.standard.string(forKey: proxyHostKey),
              let typeStr = UserDefaults.standard.string(forKey: proxyTypeKey),
              let type = ProxyType(rawValue: typeStr) else {
            return nil
        }

        let port = UserDefaults.standard.integer(forKey: proxyPortKey)
        guard port > 0 && port <= 65535 else { return nil }

        return ProxyConfig(host: host, port: port, type: type)
    }

    /// Save proxy configuration
    public func setProxyConfig(_ config: ProxyConfig) {
        UserDefaults.standard.set(config.host, forKey: proxyHostKey)
        UserDefaults.standard.set(config.port, forKey: proxyPortKey)
        UserDefaults.standard.set(config.type.rawValue, forKey: proxyTypeKey)
    }

    /// Clear proxy configuration
    public func clearProxyConfig() {
        UserDefaults.standard.removeObject(forKey: proxyHostKey)
        UserDefaults.standard.removeObject(forKey: proxyPortKey)
        UserDefaults.standard.removeObject(forKey: proxyTypeKey)
        UserDefaults.standard.set(false, forKey: proxyEnabledKey)
    }

    // MARK: - Tor Detection

    /// Check if Tor is running and accessible on localhost
    /// Tests connection to the local SOCKS5 proxy
    public func isTorAvailable() async -> Bool {
        await isTorProxyReachable(host: "127.0.0.1", port: Self.torSocks5Port)
    }

    /// Check if a Tor proxy is reachable at the given address
    private func isTorProxyReachable(host: String, port: Int) async -> Bool {
        // Use NWConnection to test if the port is open
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: UInt16(port)))
        let connection = NWConnection(to: endpoint, using: .tcp)

        return await withCheckedContinuation { continuation in
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.cancel()
                    continuation.resume(returning: true)
                case .failed, .cancelled:
                    continuation.resume(returning: false)
                default:
                    break
                }
            }

            connection.start(queue: .global())

            // Timeout after 3 seconds
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                switch connection.state {
                case .ready, .cancelled:
                    break
                case .failed:
                    break
                default:
                    connection.cancel()
                }
            }
        }
    }

    // MARK: - URL Configuration

    /// Get the appropriate base URL based on privacy settings
    public func getBaseURL() async -> String {
        let useOnion = isOnionEnabled()

        if useOnion {
            let torAvailable = await isTorAvailable()
            if torAvailable {
                return Self.onionBaseURL
            }
            // Fall back to clearnet if Tor not available
        }

        return Self.clearnetBaseURL
    }

    // MARK: - Privacy Status

    /// Get current privacy status for UI display
    public func getPrivacyStatus() async -> PrivacyStatus {
        let useOnion = isOnionEnabled()
        let proxyEnabled = isProxyEnabled()
        let torAvailable = await isTorAvailable()

        if useOnion && torAvailable {
            return PrivacyStatus(
                level: .tor,
                description: "Connected via Tor hidden service",
                isActive: true
            )
        }

        if proxyEnabled, let config = getProxyConfig() {
            return PrivacyStatus(
                level: .proxy,
                description: "Using \(config.type.rawValue.uppercased()) proxy at \(config.host):\(config.port)",
                isActive: true
            )
        }

        if useOnion && !torAvailable {
            return PrivacyStatus(
                level: .standard,
                description: "Tor enabled but not running",
                isActive: false,
                warning: "Start Tor to use onion routing"
            )
        }

        return PrivacyStatus(
            level: .standard,
            description: "Standard connection",
            isActive: true
        )
    }

    /// Test the current privacy configuration
    public func testPrivacyConnection() async -> PrivacyTestResult {
        let startTime = Date()

        do {
            let baseURL = await getBaseURL()
            guard let url = URL(string: "\(baseURL)/api/metadata.json") else {
                throw URLError(.badURL)
            }

            let (_, response) = try await URLSession.shared.data(from: url)

            let latency = Int(Date().timeIntervalSince(startTime) * 1000)

            guard let httpResponse = response as? HTTPURLResponse else {
                return PrivacyTestResult(
                    success: false,
                    latencyMs: latency,
                    message: "Invalid response",
                    usedOnion: baseURL.contains(".onion")
                )
            }

            if httpResponse.statusCode == 200 {
                return PrivacyTestResult(
                    success: true,
                    latencyMs: latency,
                    message: "Connection successful",
                    usedOnion: baseURL.contains(".onion")
                )
            } else {
                return PrivacyTestResult(
                    success: false,
                    latencyMs: latency,
                    message: "Server returned \(httpResponse.statusCode)",
                    usedOnion: baseURL.contains(".onion")
                )
            }
        } catch {
            let latency = Int(Date().timeIntervalSince(startTime) * 1000)
            return PrivacyTestResult(
                success: false,
                latencyMs: latency,
                message: error.localizedDescription,
                usedOnion: false
            )
        }
    }
}

// MARK: - Data Models

public enum ProxyType: String, CaseIterable, Identifiable, Sendable {
    case socks5 = "socks5"
    case http = "http"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .socks5: return "SOCKS5"
        case .http: return "HTTP"
        }
    }
}

public struct ProxyConfig: Equatable, Sendable {
    public let host: String
    public let port: Int
    public let type: ProxyType

    public var description: String {
        "\(type.displayName)://\(host):\(port)"
    }

    public init(host: String, port: Int, type: ProxyType) {
        self.host = host
        self.port = port
        self.type = type
    }
}

public enum PrivacyLevel: Sendable {
    case standard
    case proxy
    case tor

    public var icon: String {
        switch self {
        case .tor: return "network.badge.shield.half.filled"
        case .proxy: return "arrow.triangle.branch"
        case .standard: return "globe"
        }
    }

    public var emoji: String {
        switch self {
        case .tor: return "\u{1F9C5}"      // Onion for Tor
        case .proxy: return "\u{1F500}"    // Proxy
        case .standard: return "\u{1F310}" // Standard
        }
    }
}

public struct PrivacyStatus: Sendable {
    public let level: PrivacyLevel
    public let description: String
    public let isActive: Bool
    public var warning: String?

    public init(level: PrivacyLevel, description: String, isActive: Bool, warning: String? = nil) {
        self.level = level
        self.description = description
        self.isActive = isActive
        self.warning = warning
    }
}

public struct PrivacyTestResult: Sendable {
    public let success: Bool
    public let latencyMs: Int
    public let message: String
    public let usedOnion: Bool

    public init(success: Bool, latencyMs: Int, message: String, usedOnion: Bool) {
        self.success = success
        self.latencyMs = latencyMs
        self.message = message
        self.usedOnion = usedOnion
    }
}
