import SwiftUI
import BayNavigatorCore

struct SettingsView: View {
    @Environment(SettingsViewModel.self) private var settingsVM
    @Environment(ProgramsViewModel.self) private var programsVM
    @Environment(UserPrefsViewModel.self) private var userPrefsVM
    @Environment(\.openURL) private var openURL

    #if os(visionOS)
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var showImmersiveSpace = false
    #endif

    @State private var showProxyConfig = false
    @State private var proxyHost = ""
    @State private var proxyPort = ""
    @State private var proxyType: ProxyType = .socks5
    @State private var testingConnection = false
    @State private var connectionTestResult: PrivacyTestResult?
    @State private var cacheSize = "Calculating..."

    var body: some View {
        NavigationStack {
            Form {
                #if os(visionOS)
                spatialExperienceSection
                #endif

                profileSection
                appInfoSection
                appearanceSection
                searchSection
                languageSection
                privacySection
                storageSection
                supportSection
                legalSection
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .task {
                cacheSize = await settingsVM.cacheSize
            }
        }
    }

    // MARK: - Sections

    #if os(visionOS)
    private var spatialExperienceSection: some View {
        Section {
            Toggle(isOn: $showImmersiveSpace) {
                Label("Immersive Welcome Space", systemImage: "visionpro")
            }
            .onChange(of: showImmersiveSpace) { _, newValue in
                Task {
                    if newValue {
                        await openImmersiveSpace(id: "WelcomeSpace")
                    } else {
                        await dismissImmersiveSpace()
                    }
                }
            }
        } header: {
            Text("Spatial Experience")
        } footer: {
            Text("Open an immersive environment with floating program categories.")
        }
    }
    #endif

    private var profileSection: some View {
        Section("Your Profile") {
            Button {
                userPrefsVM.reopenOnboarding()
            } label: {
                HStack {
                    Image(systemName: "person.crop.circle")
                        .foregroundStyle(Color.appPrimary)
                    Text("Edit Profile")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var appInfoSection: some View {
        Section("App Info") {
            LabeledContent("Version", value: SettingsViewModel.appVersion)

            if let metadata = programsVM.metadata {
                LabeledContent("Database Version", value: metadata.version)
                LabeledContent("Last Updated", value: metadata.formattedGeneratedAt)
                LabeledContent("Programs", value: "\(metadata.totalPrograms)")
            }

            Button {
                Task {
                    await programsVM.loadData(forceRefresh: true)
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(Color.appPrimary)
                    Text("Refresh Data")
                }
            }
            .disabled(programsVM.isLoading)
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: Binding(
                get: { settingsVM.themeMode },
                set: { settingsVM.themeMode = $0 }
            )) {
                ForEach(SettingsViewModel.ThemeMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }

            #if os(visionOS)
            Toggle(isOn: Binding(
                get: { settingsVM.warmModeEnabled },
                set: { settingsVM.warmModeEnabled = $0 }
            )) {
                Label("Warm Mode", systemImage: "sun.max")
            }
            #endif
        }
    }

    private var searchSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { settingsVM.aiSearchEnabled },
                set: { settingsVM.aiSearchEnabled = $0 }
            )) {
                HStack {
                    Label("AI-Powered Search", systemImage: "sparkles")
                    Text("BETA")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.appAccent)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        } header: {
            Text("Search")
        } footer: {
            Text("Use AI to understand natural language queries like \"food help for seniors\"")
        }
    }

    private var languageSection: some View {
        Section("Language") {
            Picker("Language", selection: Binding(
                get: { settingsVM.currentLocale },
                set: { settingsVM.currentLocale = $0 }
            )) {
                ForEach(AppLocale.allCases) { locale in
                    HStack {
                        Text(locale.flag)
                        Text(locale.nativeName)
                    }
                    .tag(locale)
                }
            }
        }
    }

    private var privacySection: some View {
        Section {
            // Tor toggle
            Toggle(isOn: Binding(
                get: { settingsVM.useOnion },
                set: { settingsVM.useOnion = $0 }
            )) {
                HStack {
                    Image(systemName: "network.badge.shield.half.filled")
                        .foregroundStyle(.purple)
                    VStack(alignment: .leading) {
                        Text("Tor Network")
                        if !settingsVM.torAvailable {
                            Text("Tor not detected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .disabled(!settingsVM.torAvailable)

            // Custom proxy
            Button {
                showProxyConfig = true
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundStyle(Color.appPrimary)
                    VStack(alignment: .leading) {
                        Text("Custom Proxy")
                        if let config = settingsVM.proxyConfig {
                            Text(config.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            // Connection test
            Button {
                Task {
                    testingConnection = true
                    connectionTestResult = await settingsVM.testPrivacyConnection()
                    testingConnection = false
                }
            } label: {
                HStack {
                    if testingConnection {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundStyle(Color.appInfo)
                    }
                    Text("Test Connection")
                }
            }
            .disabled(testingConnection)

            // Test result
            if let result = connectionTestResult {
                HStack {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(result.success ? Color.appSuccess : Color.appDanger)
                    VStack(alignment: .leading) {
                        Text(result.message)
                            .font(.caption)
                        Text("\(result.latencyMs)ms latency")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Advanced Privacy")
        } footer: {
            Text("Enhanced privacy options for censorship circumvention.")
        }
        .sheet(isPresented: $showProxyConfig) {
            ProxyConfigSheet(
                host: $proxyHost,
                port: $proxyPort,
                type: $proxyType
            )
            .environment(settingsVM)
        }
    }

    private var storageSection: some View {
        Section {
            LabeledContent("Cache Size", value: cacheSize)

            Button(role: .destructive) {
                Task {
                    await settingsVM.clearCache()
                    cacheSize = await settingsVM.cacheSize
                }
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear Cache")
                }
                .foregroundStyle(Color.appDanger)
            }
        } header: {
            Text("Storage")
        }
    }

    private var supportSection: some View {
        Section("Support") {
            Link(destination: SettingsViewModel.donateURL) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                    Text("Donate")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Link(destination: SettingsViewModel.websiteURL) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundStyle(Color.appPrimary)
                    Text("Website")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Link(destination: SettingsViewModel.githubURL) {
                HStack {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .foregroundStyle(.secondary)
                    Text("Source Code")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Link(destination: SettingsViewModel.feedbackURL) {
                HStack {
                    Image(systemName: "ladybug.fill")
                        .foregroundStyle(Color.appDanger)
                    Text("Report a Bug")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var legalSection: some View {
        Section("Legal") {
            Link(destination: SettingsViewModel.termsURL) {
                HStack {
                    Text("Terms of Service")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Link(destination: SettingsViewModel.privacyURL) {
                HStack {
                    Text("Privacy Policy")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Link(destination: SettingsViewModel.creditsURL) {
                HStack {
                    Text("Credits")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Proxy Config Sheet

struct ProxyConfigSheet: View {
    @Binding var host: String
    @Binding var port: String
    @Binding var type: ProxyType

    @Environment(SettingsViewModel.self) private var settingsVM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Proxy Type") {
                    Picker("Type", selection: $type) {
                        ForEach(ProxyType.allCases) { proxyType in
                            Text(proxyType.displayName).tag(proxyType)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Connection") {
                    TextField("Host (e.g., 127.0.0.1)", text: $host)
                        .textContentType(.URL)
                        #if os(iOS)
                        .keyboardType(.URL)
                        #endif

                    TextField("Port (e.g., 9050)", text: $port)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }

                Section {
                    Button("Save Configuration") {
                        if let portNum = Int(port), portNum > 0, portNum <= 65535, !host.isEmpty {
                            Task {
                                await settingsVM.setProxyConfig(ProxyConfig(host: host, port: portNum, type: type))
                                dismiss()
                            }
                        }
                    }
                    .disabled(host.isEmpty || port.isEmpty)

                    if settingsVM.proxyConfig != nil {
                        Button("Clear Configuration", role: .destructive) {
                            Task {
                                await settingsVM.clearProxyConfig()
                                host = ""
                                port = ""
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Proxy Configuration")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            if let config = settingsVM.proxyConfig {
                host = config.host
                port = String(config.port)
                type = config.type
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(SettingsViewModel())
        .environment(ProgramsViewModel())
        .environment(UserPrefsViewModel())
}
