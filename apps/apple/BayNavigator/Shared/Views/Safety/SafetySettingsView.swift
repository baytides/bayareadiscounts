import SwiftUI
import BayNavigatorCore

/// Safety settings view for configuring privacy and safety features
struct SafetySettingsView: View {
    @StateObject private var viewModel = SafetySettingsViewModel()
    @State private var showingClearDataAlert = false
    @State private var showingPINSetup = false
    @State private var showingPINChange = false
    @State private var showingPINRemove = false
    @State private var showingPanicWipeWarning = false

    var body: some View {
        List {
            // Incognito Mode Section
            Section {
                Toggle("Incognito Mode", isOn: $viewModel.incognitoModeEnabled)
                    .onChange(of: viewModel.incognitoModeEnabled) { _, newValue in
                        Task {
                            await viewModel.setIncognitoMode(newValue)
                        }
                    }
            } header: {
                Label("Privacy Mode", systemImage: "eye.slash")
            } footer: {
                Text("When enabled, your browsing history, searches, and viewed programs will not be saved. Data is cleared when you exit the app.")
            }

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
                Label("PIN Protection", systemImage: "lock.shield")
            } footer: {
                Text("Protect the app with a 6-8 digit PIN. You can also enable biometric authentication for faster access.")
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
                        Stepper(value: $viewModel.maxFailedAttempts, in: 1...10) {
                            HStack {
                                Text("Failed Attempts Limit")
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
                    Label("Emergency Wipe", systemImage: "exclamationmark.triangle")
                } footer: {
                    Text("Automatically delete all app data after \(viewModel.maxFailedAttempts) failed PIN attempts. Use this if you're concerned someone may try to access your data.")
                }
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
                Text("Quickly navigate to a safe website and clear app state. The quick exit button appears on sensitive screens.")
            }

            // Shake to Clear Section
            Section {
                Toggle("Shake to Clear", isOn: $viewModel.shakeToClearEnabled)
                    .onChange(of: viewModel.shakeToClearEnabled) { _, newValue in
                        Task {
                            await viewModel.setShakeToClearEnabled(newValue)
                        }
                    }
            } header: {
                Label("Shake Detection", systemImage: "iphone.radiowaves.left.and.right")
            } footer: {
                Text("Shake your device 3 times to quickly clear your browsing history and recent activity. A confirmation dialog will appear first.")
            }

            // Network Privacy Section
            Section {
                Toggle("Network Monitoring", isOn: $viewModel.networkMonitoringEnabled)
                    .onChange(of: viewModel.networkMonitoringEnabled) { _, newValue in
                        Task {
                            await viewModel.setNetworkMonitoringEnabled(newValue)
                        }
                    }

                if viewModel.networkMonitoringEnabled {
                    Toggle("Show Warnings", isOn: $viewModel.networkWarningsEnabled)
                        .onChange(of: viewModel.networkWarningsEnabled) { _, newValue in
                            Task {
                                await viewModel.setNetworkWarningsEnabled(newValue)
                            }
                        }

                    if let status = viewModel.networkStatus {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: status.level.systemImage)
                                    .foregroundStyle(colorForPrivacyLevel(status.level))
                                Text(status.connectionType)
                                Spacer()
                                if status.warning != nil {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                }
                            }

                            if let suggestion = status.suggestion {
                                Text(suggestion)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            // Show trust button if we have SSID and it's not already trusted
                            if let ssid = status.ssid, status.level != .good {
                                Button {
                                    Task {
                                        await viewModel.trustCurrentNetwork(ssid)
                                    }
                                } label: {
                                    Label("Trust \"\(ssid)\"", systemImage: "checkmark.shield")
                                }
                                .buttonStyle(.bordered)
                                .tint(.green)
                                .controlSize(.small)
                            }
                        }
                    }
                }
            } header: {
                Label("Network Privacy", systemImage: "wifi.exclamationmark")
            } footer: {
                Text("Monitor your network connection and receive warnings when using public WiFi networks. You can mark your home/work networks as trusted.\n\nNetwork identification uses location permission on-device only — your location is never sent to any server.")
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
                Text("Store sensitive data with additional encryption using your device's secure enclave.")
            }

            // Clear Data Section
            Section {
                Button("Clear All History", role: .destructive) {
                    Task {
                        await viewModel.clearHistory()
                    }
                }

                Button("Clear All App Data", role: .destructive) {
                    showingClearDataAlert = true
                }
            } header: {
                Label("Data Management", systemImage: "trash")
            } footer: {
                Text("Clearing all app data will remove your profile, preferences, favorites, and history. This cannot be undone.")
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
        .alert("Clear All Data?", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                Task {
                    await viewModel.clearAllData()
                }
            }
        } message: {
            Text("This will permanently delete your profile, preferences, favorites, and all history. This action cannot be undone.")
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

    private func colorForPrivacyLevel(_ level: NetworkPrivacyLevel) -> Color {
        switch level {
        case .good: return .green
        case .moderate: return .blue
        case .caution: return .orange
        case .offline: return .gray
        case .unknown: return .gray
        }
    }
}

// MARK: - View Model

@MainActor
class SafetySettingsViewModel: ObservableObject {
    @Published var incognitoModeEnabled = false
    @Published var hasPINSet = false
    @Published var biometricEnabled = false
    @Published var panicWipeEnabled = false
    @Published var maxFailedAttempts = 3
    @Published var quickExitEnabled = false
    @Published var selectedQuickExitUrl = SafetyService.quickExitDestinations[0].url
    @Published var shakeToClearEnabled = false
    @Published var networkMonitoringEnabled = false
    @Published var networkWarningsEnabled = false
    @Published var networkStatus: NetworkPrivacyStatus?
    @Published var encryptionEnabled = false

    var biometricType: BiometricType {
        SafetyService.shared.canUseBiometrics()
    }

    func loadSettings() async {
        let service = SafetyService.shared

        incognitoModeEnabled = await service.isIncognitoModeEnabled()
        hasPINSet = await service.hasPinSet()
        biometricEnabled = await service.isBiometricEnabled()
        panicWipeEnabled = await service.isPanicWipeEnabled()
        maxFailedAttempts = await service.getMaxFailedAttempts()
        quickExitEnabled = await service.isQuickExitEnabled()
        selectedQuickExitUrl = await service.getQuickExitUrl()
        shakeToClearEnabled = await service.isShakeToClearEnabled()
        networkMonitoringEnabled = await service.isNetworkMonitoringEnabled()
        networkWarningsEnabled = await service.isNetworkWarningsEnabled()
        encryptionEnabled = await service.isEncryptionEnabled()

        if networkMonitoringEnabled {
            networkStatus = await service.getNetworkPrivacyStatus()
        }
    }

    func setIncognitoMode(_ enabled: Bool) async {
        await SafetyService.shared.setIncognitoModeEnabled(enabled)
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

    func setShakeToClearEnabled(_ enabled: Bool) async {
        await SafetyService.shared.setShakeToClearEnabled(enabled)
    }

    func setNetworkMonitoringEnabled(_ enabled: Bool) async {
        await SafetyService.shared.setNetworkMonitoringEnabled(enabled)
        if enabled {
            networkStatus = await SafetyService.shared.getNetworkPrivacyStatus()
        } else {
            networkStatus = nil
        }
    }

    func setNetworkWarningsEnabled(_ enabled: Bool) async {
        await SafetyService.shared.setNetworkWarningsEnabled(enabled)
    }

    func trustCurrentNetwork(_ ssid: String) async {
        await SafetyService.shared.addTrustedNetwork(ssid)
        // Refresh network status
        networkStatus = await SafetyService.shared.getNetworkPrivacyStatus()
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

    func clearHistory() async {
        await SafetyService.shared.clearAllHistory()
    }

    func clearAllData() async {
        await SafetyService.shared.clearAllData()
        await loadSettings()
    }
}

#Preview {
    NavigationStack {
        SafetySettingsView()
    }
}
