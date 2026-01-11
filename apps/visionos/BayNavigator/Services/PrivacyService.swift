import Foundation
import Network

/// Privacy service for Bay Navigator
/// Provides censorship circumvention features similar to Signal
/// - Tor/Onion routing (requires system Tor client)
/// - Custom proxy support (SOCKS5/HTTP)
/// - Privacy-first network configuration
actor PrivacyService {
    static let shared = PrivacyService()

    // MARK: - Constants

    /// Standard clearnet API endpoint
    static let clearnetBaseURL = "https://baynavigator.org"

    /// Tor hidden service endpoint (requires Tor client)
    static let onionBaseURL = "http://7u42bzioq3cbud5rmey3sfx4odvjfryjifwx4ozonihdtdrykwjifkad.onion"

    /// Default Tor SOCKS5 proxy port
    static let torSocks5Port = 9050

    // MARK: - Cache Keys

    private let useOnionKey = "baynavigator:use_onion"
    private let proxyEnabledKey = "baynavigator:proxy_enabled"
    private let proxyHostKey = "baynavigator:proxy_host"
    private let proxyPortKey = "baynavigator:proxy_port"
    private let proxyTypeKey = "baynavigator:proxy_type"

    private init() {}

    // MARK: - Settings Persistence

    /// Check if onion routing is enabled
    func isOnionEnabled() -> Bool {
        UserDefaults.standard.bool(forKey: useOnionKey)
    }

    /// Enable or disable onion routing
    func setOnionEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: useOnionKey)
    }

    /// Check if custom proxy is enabled
    func isProxyEnabled() -> Bool {
        UserDefaults.standard.bool(forKey: proxyEnabledKey)
    }

    /// Enable or disable custom proxy
    func setProxyEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: proxyEnabledKey)
    }

    /// Get proxy configuration
    func getProxyConfig() -> ProxyConfig? {
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
    func setProxyConfig(_ config: ProxyConfig) {
        UserDefaults.standard.set(config.host, forKey: proxyHostKey)
        UserDefaults.standard.set(config.port, forKey: proxyPortKey)
        UserDefaults.standard.set(config.type.rawValue, forKey: proxyTypeKey)
    }

    /// Clear proxy configuration
    func clearProxyConfig() {
        UserDefaults.standard.removeObject(forKey: proxyHostKey)
        UserDefaults.standard.removeObject(forKey: proxyPortKey)
        UserDefaults.standard.removeObject(forKey: proxyTypeKey)
        UserDefaults.standard.set(false, forKey: proxyEnabledKey)
    }

    // MARK: - Tor Detection

    /// Check if Tor is running and accessible on localhost
    /// Tests connection to the local SOCKS5 proxy
    func isTorAvailable() async -> Bool {
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
                if connection.state != .ready && connection.state != .failed {
                    connection.cancel()
                }
            }
        }
    }

    // MARK: - URL Configuration

    /// Get the appropriate base URL based on privacy settings
    func getBaseURL() async -> String {
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
    func getPrivacyStatus() async -> PrivacyStatus {
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
    func testPrivacyConnection() async -> PrivacyTestResult {
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

enum ProxyType: String, CaseIterable, Identifiable {
    case socks5 = "socks5"
    case http = "http"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .socks5: return "SOCKS5"
        case .http: return "HTTP"
        }
    }
}

struct ProxyConfig: Equatable {
    let host: String
    let port: Int
    let type: ProxyType

    var description: String {
        "\(type.displayName)://\(host):\(port)"
    }
}

enum PrivacyLevel {
    case standard
    case proxy
    case tor

    var icon: String {
        switch self {
        case .tor: return "🧅"      // Onion for Tor
        case .proxy: return "🔀"    // Proxy
        case .standard: return "🌐" // Standard
        }
    }

    var systemImage: String {
        switch self {
        case .tor: return "network.badge.shield.half.filled"
        case .proxy: return "arrow.triangle.branch"
        case .standard: return "globe"
        }
    }
}

struct PrivacyStatus {
    let level: PrivacyLevel
    let description: String
    let isActive: Bool
    var warning: String?
}

struct PrivacyTestResult {
    let success: Bool
    let latencyMs: Int
    let message: String
    let usedOnion: Bool
}
