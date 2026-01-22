import SwiftUI
import BayNavigatorCore

/// Safety settings view for configuring privacy and safety features
/// Designed for users who may need enhanced privacy, such as DV survivors or LGBTQ youth
struct SafetySettingsView: View {
    @StateObject private var viewModel = SafetySettingsViewModel()
    @State private var showingClearHistoryAlert = false
    @State private var showingClearDataAlert = false
    @State private var showingPINSetup = false
    @State private var showingPINChange = false
    @State private var showingPINRemove = false
    @State private var showingPanicWipeWarning = false
    @State private var showingOfflineModeInfo = false

    private var torStatusColor: Color {
        guard let status = viewModel.torStatus else { return .secondary }
        if status.isConnected {
            return .green
        } else if status.isEnabled && status.isOrbotInstalled {
            return .orange
        } else if status.isEnabled {
            return .red
        }
        return .secondary
    }

    var body: some View {
        List {
            // PIN Protection Section
            Section {
                if viewModel.hasPINSet {
                    HStack {
                        Label("PIN Protection", systemImage: "lock.fill")
                        Spacer()
                        Text("Enabled")
                            .foregroundStyle(.secondary)
                    }

                    Button("Change PIN") {
                        showingPINChange = true
                    }

                    Button("Remove PIN", role: .destructive) {
                        showingPINRemove = true
                    }
                } else {
                    Button {
                        showingPINSetup = true
                    } label: {
                        Label("Set Up PIN", systemImage: "lock")
                    }
                }

                if viewModel.hasPINSet {
                    let biometricType = viewModel.biometricType
                    if biometricType != .none {
                        Toggle(isOn: $viewModel.biometricEnabled) {
                            Label("Unlock with \(biometricType.displayName)", systemImage: biometricType.systemImage)
                        }
                        .onChange(of: viewModel.biometricEnabled) { _, newValue in
                            Task {
                                await viewModel.setBiometricEnabled(newValue)
                            }
                        }
                    }
                }
            } header: {
                Label("App Security", systemImage: "lock.shield")
            } footer: {
                Text("Protect the app with a PIN code to prevent unauthorized access to your saved programs and profile information.")
            }

            // Panic Wipe Section
            if viewModel.hasPINSet {
                Section {
                    Toggle("Enable Panic Wipe", isOn: $viewModel.panicWipeEnabled)
                        .onChange(of: viewModel.panicWipeEnabled) { _, newValue in
                            if newValue {
                                showingPanicWipeWarning = true
                            } else {
                                Task {
                                    await viewModel.setPanicWipeEnabled(false)
                                }
                            }
                        }

                    if viewModel.panicWipeEnabled {
                        Stepper(value: $viewModel.maxFailedAttempts, in: 3...10) {
                            HStack {
                                Text("Failed Attempts")
                                Spacer()
                                Text("\(viewModel.maxFailedAttempts)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onChange(of: viewModel.maxFailedAttempts) { _, newValue in
                            Task {
                                await viewModel.setMaxFailedAttempts(newValue)
                            }
                        }
                    }
                } header: {
                    Label("Emergency Protection", systemImage: "exclamationmark.shield")
                } footer: {
                    Text("Automatically delete all app data after \(viewModel.maxFailedAttempts) failed PIN attempts. This protects your information if someone tries to access your device.")
                }
            }

            // Encrypted Storage Section
            Section {
                Toggle("Encrypted Storage", isOn: $viewModel.encryptionEnabled)
                    .onChange(of: viewModel.encryptionEnabled) { _, newValue in
                        Task {
                            await viewModel.setEncryptionEnabled(newValue)
                        }
                    }
            } header: {
                Label("Data Encryption", systemImage: "lock.doc")
            } footer: {
                Text("Add an extra layer of encryption to sensitive data stored on your device, such as your profile and saved programs.")
            }

            // Offline Mode Section
            Section {
                Toggle("Offline Mode", isOn: $viewModel.offlineModeEnabled)
                    .onChange(of: viewModel.offlineModeEnabled) { _, newValue in
                        Task {
                            await viewModel.setOfflineModeEnabled(newValue)
                        }
                    }

                if viewModel.offlineModeEnabled {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundStyle(.orange)
                        Text("Network requests are blocked")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    Task {
                        await viewModel.refreshCache()
                    }
                } label: {
                    HStack {
                        Label("Update Cached Data", systemImage: "arrow.clockwise")
                        Spacer()
                        if viewModel.isRefreshingCache {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isRefreshingCache || viewModel.offlineModeEnabled)
            } header: {
                Label("Offline Mode", systemImage: "wifi.slash")
            } footer: {
                Text("When enabled, the app will only use cached data and won't make any network requests. This prevents anyone monitoring your network from seeing that you're using Bay Navigator. Update cached data regularly while online.")
            }

            // Quick Exit Section
            Section {
                Toggle("Enable Quick Exit", isOn: $viewModel.quickExitEnabled)
                    .onChange(of: viewModel.quickExitEnabled) { _, newValue in
                        Task {
                            await viewModel.setQuickExitEnabled(newValue)
                        }
                    }

                if viewModel.quickExitEnabled {
                    Picker("Exit Destination", selection: $viewModel.selectedQuickExitUrl) {
                        ForEach(SafetyService.quickExitDestinations) { destination in
                            Text(destination.name)
                                .tag(destination.url)
                        }
                    }
                    .onChange(of: viewModel.selectedQuickExitUrl) { _, newValue in
                        Task {
                            await viewModel.setQuickExitUrl(newValue)
                        }
                    }
                }
            } header: {
                Label("Quick Exit", systemImage: "escape")
            } footer: {
                Text("Shows a floating button to quickly navigate to a different website if you need to leave the app immediately.")
            }

            // Tor/Orbot Section
            Section {
                Toggle("Route Through Tor", isOn: $viewModel.torEnabled)
                    .onChange(of: viewModel.torEnabled) { _, newValue in
                        Task {
                            await viewModel.setTorEnabled(newValue)
                        }
                    }

                if viewModel.torEnabled {
                    // Show Tor status
                    HStack {
                        Image(systemName: viewModel.torStatus?.isConnected == true ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(torStatusColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.torStatus?.message ?? "Checking...")
                                .font(.subheadline)
                            if viewModel.torStatus?.isConnected == true {
                                Text("Using .onion address")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }

                    if viewModel.torStatus?.isOrbotInstalled == false {
                        Link(destination: URL(string: "https://apps.apple.com/app/orbot/id1609461599")!) {
                            HStack {
                                Label("Install Orbot", systemImage: "arrow.down.app")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                        }
                    } else if viewModel.torStatus?.isProxyAvailable == false {
                        Button {
                            Task {
                                await viewModel.openOrbot()
                            }
                        } label: {
                            HStack {
                                Label("Open Orbot", systemImage: "arrow.up.forward.app")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                        }
                    }

                    Button {
                        Task {
                            await viewModel.refreshTorStatus()
                        }
                    } label: {
                        Label("Refresh Status", systemImage: "arrow.clockwise")
                    }
                }
            } header: {
                Label("Tor Network", systemImage: "network.badge.shield.half.filled")
            } footer: {
                Text("When enabled and Orbot is running, the app connects through Tor to our .onion hidden service. This hides your activity from network monitors and provides end-to-end encryption.")
            }

            // Ask Carl Privacy Section
            Section {
                Toggle("Share Profile with Carl", isOn: $viewModel.shareProfileWithCarl)
                    .onChange(of: viewModel.shareProfileWithCarl) { _, newValue in
                        Task {
                            await viewModel.setShareProfileWithCarlEnabled(newValue)
                        }
                    }
            } header: {
                Label("Ask Carl", systemImage: "sparkles")
            } footer: {
                Text("When enabled, Carl can use your profile information (location, age, qualifications) to give more personalized program recommendations. Your data stays on-device and is only used to provide context to the AI - it is never stored or shared.")
            }

            // Analytics & Crash Reporting Section
            Section {
                Toggle("Send Crash Reports", isOn: $viewModel.crashReportingEnabled)
                    .onChange(of: viewModel.crashReportingEnabled) { _, newValue in
                        Task {
                            await viewModel.setCrashReportingEnabled(newValue)
                        }
                    }
            } header: {
                Label("Analytics", systemImage: "chart.bar")
            } footer: {
                Text("Help improve Bay Navigator by sending anonymous crash reports. No personal data is ever collected.")
            }

            // Clear Data Section
            Section {
                Button("Clear Browsing History") {
                    showingClearHistoryAlert = true
                }

                Button("Clear All App Data", role: .destructive) {
                    showingClearDataAlert = true
                }
            } header: {
                Label("Data Management", systemImage: "trash")
            } footer: {
                Text("Clear your browsing history or delete all app data including your profile, preferences, and saved programs.")
            }
        }
        .navigationTitle("Safety & Privacy")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .task {
            await viewModel.loadSettings()
        }
        .sheet(isPresented: $showingPINSetup) {
            NavigationStack {
                PINEntryView(mode: .setup) { success in
                    showingPINSetup = false
                    if success {
                        Task {
                            await viewModel.loadSettings()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingPINChange) {
            NavigationStack {
                PINEntryView(mode: .change) { success in
                    showingPINChange = false
                    if success {
                        Task {
                            await viewModel.loadSettings()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingPINRemove) {
            NavigationStack {
                PINEntryView(mode: .remove) { success in
                    showingPINRemove = false
                    if success {
                        Task {
                            await viewModel.loadSettings()
                        }
                    }
                }
            }
        }
        .alert("Clear History?", isPresented: $showingClearHistoryAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                Task {
                    await viewModel.clearHistory()
                }
            }
        } message: {
            Text("This will clear your browsing history and recently viewed programs.")
        }
        .alert("Clear All Data?", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                Task {
                    await viewModel.clearAllData()
                }
            }
        } message: {
            Text("This will permanently delete your profile, preferences, saved programs, and all history. This action cannot be undone.")
        }
        .alert("Enable Panic Wipe?", isPresented: $showingPanicWipeWarning) {
            Button("Cancel", role: .cancel) {
                viewModel.panicWipeEnabled = false
            }
            Button("Enable", role: .destructive) {
                Task {
                    await viewModel.setPanicWipeEnabled(true)
                }
            }
        } message: {
            Text("After \(viewModel.maxFailedAttempts) failed PIN attempts, ALL app data will be permanently deleted. Make sure you remember your PIN!")
        }
    }
}

// MARK: - View Model

@MainActor
class SafetySettingsViewModel: ObservableObject {
    @Published var hasPINSet = false
    @Published var biometricEnabled = false
    @Published var panicWipeEnabled = false
    @Published var maxFailedAttempts = 5
    @Published var quickExitEnabled = false
    @Published var selectedQuickExitUrl = SafetyService.quickExitDestinations[0].url
    @Published var encryptionEnabled = false
    @Published var offlineModeEnabled = false
    @Published var isRefreshingCache = false
    @Published var torEnabled = false
    @Published var torStatus: TorStatus?
    @Published var crashReportingEnabled = true
    @Published var shareProfileWithCarl = false

    var biometricType: BiometricType {
        SafetyService.shared.canUseBiometrics()
    }

    func loadSettings() async {
        let service = SafetyService.shared

        hasPINSet = await service.hasPinSet()
        biometricEnabled = await service.isBiometricEnabled()
        panicWipeEnabled = await service.isPanicWipeEnabled()
        maxFailedAttempts = await service.getMaxFailedAttempts()
        quickExitEnabled = await service.isQuickExitEnabled()
        selectedQuickExitUrl = await service.getQuickExitUrl()
        encryptionEnabled = await service.isEncryptionEnabled()
        offlineModeEnabled = await service.isOfflineModeEnabled()
        torEnabled = await service.isTorEnabled()
        crashReportingEnabled = await service.isCrashReportingEnabled()
        shareProfileWithCarl = await service.isShareProfileWithCarlEnabled()

        // Load Tor status if enabled
        if torEnabled {
            await refreshTorStatus()
        }
    }

    func setBiometricEnabled(_ enabled: Bool) async {
        await SafetyService.shared.setBiometricEnabled(enabled)
    }

    func setPanicWipeEnabled(_ enabled: Bool) async {
        await SafetyService.shared.setPanicWipeEnabled(enabled)
        panicWipeEnabled = enabled
    }

    func setMaxFailedAttempts(_ count: Int) async {
        await SafetyService.shared.setMaxFailedAttempts(count)
    }

    func setQuickExitEnabled(_ enabled: Bool) async {
        await SafetyService.shared.setQuickExitEnabled(enabled)
    }

    func setQuickExitUrl(_ url: String) async {
        await SafetyService.shared.setQuickExitUrl(url)
    }

    func setEncryptionEnabled(_ enabled: Bool) async {
        if enabled {
            let result = await SafetyService.shared.enableEncryption()
            if !result.success {
                encryptionEnabled = false
            }
        } else {
            let result = await SafetyService.shared.disableEncryption()
            if !result.success {
                encryptionEnabled = true
            }
        }
    }

    func setOfflineModeEnabled(_ enabled: Bool) async {
        await SafetyService.shared.setOfflineModeEnabled(enabled)
        offlineModeEnabled = enabled
    }

    func refreshCache() async {
        isRefreshingCache = true
        await APIService.shared.preCacheAllData()
        isRefreshingCache = false
    }

    func setTorEnabled(_ enabled: Bool) async {
        await SafetyService.shared.setTorEnabled(enabled)
        torEnabled = enabled
        if enabled {
            await refreshTorStatus()
        } else {
            torStatus = nil
        }
    }

    func refreshTorStatus() async {
        torStatus = await SafetyService.shared.getTorStatus()
    }

    func openOrbot() async {
        await SafetyService.shared.openOrbot()
        // Wait a moment then refresh status
        try? await Task.sleep(for: .seconds(1))
        await refreshTorStatus()
    }

    func clearHistory() async {
        await SafetyService.shared.clearAllHistory()
    }

    func clearAllData() async {
        await SafetyService.shared.clearAllData()
        await loadSettings()
    }

    func setCrashReportingEnabled(_ enabled: Bool) async {
        await SafetyService.shared.setCrashReportingEnabled(enabled)
        crashReportingEnabled = enabled
    }

    func setShareProfileWithCarlEnabled(_ enabled: Bool) async {
        await SafetyService.shared.setShareProfileWithCarlEnabled(enabled)
        shareProfileWithCarl = enabled
    }
}

#Preview {
    NavigationStack {
        SafetySettingsView()
    }
}
