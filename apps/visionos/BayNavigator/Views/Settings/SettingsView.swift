import SwiftUI

struct SettingsView: View {
    @Environment(ProgramsViewModel.self) private var programsViewModel
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @Environment(UserPrefsViewModel.self) private var userPrefsViewModel
    @Environment(\.openURL) private var openURL
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var cacheSize: String = "Calculating..."
    @State private var isRefreshing = false
    @State private var isImmersiveSpaceOpen = false

    // Privacy state
    @State private var showTorRequiredAlert = false
    @State private var showProxyConfigSheet = false
    @State private var isTestingConnection = false
    @State private var showConnectionTestResult = false
    @State private var connectionTestResult: PrivacyTestResult?
    @State private var proxyHost = ""
    @State private var proxyPort = "9050"
    @State private var proxyType: ProxyType = .socks5

    var body: some View {
        @Bindable var settings = settingsViewModel

        NavigationStack {
            List {
                // Spatial Experience Section
                Section {
                    Button {
                        Task {
                            if isImmersiveSpaceOpen {
                                await dismissImmersiveSpace()
                                isImmersiveSpaceOpen = false
                            } else {
                                let result = await openImmersiveSpace(id: "WelcomeSpace")
                                if case .opened = result {
                                    isImmersiveSpaceOpen = true
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Label(
                                isImmersiveSpaceOpen ? "Exit Spatial View" : "Enter Spatial View",
                                systemImage: isImmersiveSpaceOpen ? "arrow.down.right.and.arrow.up.left" : "cube.transparent"
                            )
                            Spacer()
                            if isImmersiveSpaceOpen {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                } header: {
                    Text("Spatial Experience")
                } footer: {
                    Text("Experience program categories in an immersive 3D space around you.")
                }

                // Your Profile Section
                Section {
                    Button {
                        userPrefsViewModel.reopenOnboarding()
                    } label: {
                        HStack {
                            Label("Set Up Profile", systemImage: "pencil")
                            Spacer()
                            if userPrefsViewModel.hasPreferences {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("Your Profile")
                } footer: {
                    if userPrefsViewModel.hasPreferences {
                        Text("Your profile is set up. Tap to edit your preferences.")
                    } else {
                        Text("Set up your profile to see personalized recommendations.")
                    }
                }

                // App Info Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(SettingsViewModel.appVersion)
                            .foregroundStyle(.secondary)
                    }

                    if let metadata = programsViewModel.metadata {
                        HStack {
                            Text("Database Version")
                            Spacer()
                            Text(metadata.version)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Last Updated")
                            Spacer()
                            Text(metadata.formattedGeneratedAt)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Total Programs")
                            Spacer()
                            Text("\(metadata.totalPrograms)")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        Task {
                            isRefreshing = true
                            AccessibilityAnnouncement.announce("Refreshing database")
                            await programsViewModel.loadData(forceRefresh: true)
                            isRefreshing = false
                            AccessibilityAnnouncement.announce("Database refresh complete")
                        }
                    } label: {
                        HStack {
                            Text("Refresh Database")
                            Spacer()
                            if isRefreshing {
                                ProgressView()
                                    .accessibilityLabel("Refreshing")
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                    .disabled(isRefreshing)
                    .accessibilityHint(isRefreshing ? "Currently refreshing" : "Double tap to check for updates")
                } header: {
                    Text("App Info")
                }

                // Appearance Section
                Section {
                    Picker("Theme", selection: $settings.themeMode) {
                        ForEach(SettingsViewModel.ThemeMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }

                    Toggle(isOn: $settings.warmModeEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Warm Mode")
                            Text("Reduces blue light for eye comfort")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.orange)
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Warm Mode applies a sepia tint to reduce eye strain. This is an in-app alternative since visionOS doesn't include Night Shift.")
                }

                // Search Section
                Section {
                    Toggle(isOn: $settings.aiSearchEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.purple)
                                Text("AI-Powered Search")
                                Text("Beta")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.3))
                                    .foregroundStyle(.secondary)
                                    .clipShape(Capsule())
                            }
                            Text(settings.aiSearchEnabled
                                ? "Natural language search enabled"
                                : "Using basic keyword search only")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.purple)
                } header: {
                    Text("Search")
                } footer: {
                    Text("When enabled, you can ask natural language questions like \"What programs help seniors with housing?\" The AI runs in the cloud and requires an internet connection.")
                }

                // Language Section
                Section {
                    ForEach(AppLocale.allCases) { locale in
                        Button {
                            settings.currentLocale = locale
                        } label: {
                            HStack {
                                Text(locale.flag)
                                    .font(.title2)
                                Text(locale.nativeName)
                                    .foregroundStyle(.primary)
                                if locale.name != locale.nativeName {
                                    Text("(\(locale.name))")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                                Spacer()
                                if settings.currentLocale == locale {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                        .accessibilityLabel("\(locale.nativeName), \(locale.name)")
                        .accessibilityHint(settings.currentLocale == locale ? "Currently selected" : "Double tap to select")
                    }
                } header: {
                    Text("Language")
                } footer: {
                    Text("Select your preferred language. Translations are provided by Azure AI Translator.")
                }

                // Advanced Privacy Section
                Section {
                    // Privacy status indicator
                    if let status = settings.privacyStatus {
                        HStack {
                            Image(systemName: status.level.systemImage)
                                .foregroundStyle(status.isActive ? .green : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(status.description)
                                if let warning = status.warning {
                                    Text(warning)
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }

                    // Tor/Onion toggle
                    Toggle(isOn: $settings.useOnion) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Use Tor Network")
                            Text("Route traffic through Tor hidden service")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onChange(of: settings.useOnion) { _, newValue in
                        if newValue && !settings.torAvailable {
                            showTorRequiredAlert = true
                        }
                    }

                    // Custom proxy toggle
                    Toggle(isOn: $settings.proxyEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Use Custom Proxy")
                            Text("Route traffic through SOCKS5 or HTTP proxy")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onChange(of: settings.proxyEnabled) { _, newValue in
                        if newValue && settings.proxyConfig == nil {
                            showProxyConfigSheet = true
                        }
                    }

                    // Show proxy config if enabled
                    if settings.proxyEnabled, let config = settings.proxyConfig {
                        HStack {
                            Text("Proxy")
                            Spacer()
                            Text(config.description)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Test connection button
                    Button {
                        Task {
                            isTestingConnection = true
                            AccessibilityAnnouncement.announce("Testing privacy connection")
                            let result = await settings.testPrivacyConnection()
                            isTestingConnection = false
                            connectionTestResult = result
                            showConnectionTestResult = true
                            AccessibilityAnnouncement.announce(result.success ? "Connection successful" : "Connection failed")
                        }
                    } label: {
                        HStack {
                            Label("Test Privacy Connection", systemImage: "network")
                            Spacer()
                            if isTestingConnection {
                                ProgressView()
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .disabled(isTestingConnection)
                } header: {
                    Text("Advanced Privacy")
                } footer: {
                    Text("Optional features to access Bay Navigator through Tor or a proxy for enhanced privacy. Similar to Signal's censorship circumvention.")
                }

                // Cache Section
                Section {
                    HStack {
                        Text("Cache Size")
                        Spacer()
                        Text(cacheSize)
                            .foregroundStyle(.secondary)
                    }

                    Button(role: .destructive) {
                        Task {
                            AccessibilityAnnouncement.announce("Clearing cache")
                            await settingsViewModel.clearCache()
                            await updateCacheSize()
                            AccessibilityAnnouncement.announce("Cache cleared successfully")
                        }
                    } label: {
                        Text("Clear Cache")
                    }
                    .accessibilityHint("Double tap to clear cached data")
                } header: {
                    Text("Storage")
                } footer: {
                    Text("Clearing the cache will require redownloading program data. Your favorites will be preserved.")
                }

                // Support Section
                Section {
                    Link(destination: SettingsViewModel.donateURL) {
                        HStack {
                            Label("Support Our Work", systemImage: "heart.fill")
                                .foregroundStyle(Color.appDanger)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("Support")
                }

                // Links Section
                Section {
                    Link(destination: SettingsViewModel.websiteURL) {
                        LinkRow(title: "Bay Navigator Website", icon: "globe")
                    }

                    Link(destination: SettingsViewModel.parentOrgURL) {
                        LinkRow(title: "Bay Tides", icon: "building.2")
                    }

                    Link(destination: SettingsViewModel.githubURL) {
                        LinkRow(title: "View Source Code", icon: "chevron.left.forwardslash.chevron.right")
                    }

                    Link(destination: SettingsViewModel.feedbackURL) {
                        LinkRow(title: "Report a Bug", icon: "ladybug")
                    }
                } header: {
                    Text("Links")
                }

                // Legal Section
                Section {
                    Link(destination: SettingsViewModel.termsURL) {
                        LinkRow(title: "Terms of Service", icon: "doc.text")
                    }

                    Link(destination: SettingsViewModel.privacyURL) {
                        LinkRow(title: "Privacy Policy", icon: "hand.raised")
                    }

                    Link(destination: SettingsViewModel.creditsURL) {
                        LinkRow(title: "Credits & Acknowledgments", icon: "heart.text.square")
                    }
                } header: {
                    Text("Legal")
                } footer: {
                    Text("Bay Navigator is a project of Bay Tides, a 501(c)(3) nonprofit organization.")
                }
            }
            .navigationTitle("Settings")
            .task {
                await updateCacheSize()
            }
            // Tor required alert
            .alert("Tor Client Required", isPresented: $showTorRequiredAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("To use Tor, you need a Tor client running on your Mac or network. The app will use the default SOCKS5 proxy at 127.0.0.1:9050.")
            }
            // Connection test result alert
            .alert(
                connectionTestResult?.success == true ? "Connection Successful" : "Connection Failed",
                isPresented: $showConnectionTestResult
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                if let result = connectionTestResult {
                    if result.success {
                        Text(result.usedOnion
                            ? "Connected via Tor (\(result.latencyMs)ms)"
                            : "Connection successful (\(result.latencyMs)ms)")
                    } else {
                        Text(result.message)
                    }
                }
            }
            // Proxy configuration sheet
            .sheet(isPresented: $showProxyConfigSheet) {
                NavigationStack {
                    Form {
                        Section {
                            Picker("Type", selection: $proxyType) {
                                ForEach(ProxyType.allCases) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }

                            TextField("Host", text: $proxyHost)
                                .textContentType(.URL)
                                .autocorrectionDisabled()

                            TextField("Port", text: $proxyPort)
                                .keyboardType(.numberPad)
                        } header: {
                            Text("Proxy Configuration")
                        } footer: {
                            Text("Configure a SOCKS5 or HTTP proxy to route app traffic through.")
                        }
                    }
                    .navigationTitle("Configure Proxy")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showProxyConfigSheet = false
                                // Reset proxy enabled if cancelled without config
                                if settingsViewModel.proxyConfig == nil {
                                    settingsViewModel.proxyEnabled = false
                                }
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                guard !proxyHost.isEmpty,
                                      let port = Int(proxyPort),
                                      port > 0 && port <= 65535 else {
                                    return
                                }

                                let config = ProxyConfig(host: proxyHost, port: port, type: proxyType)
                                Task {
                                    await settingsViewModel.setProxyConfig(config)
                                }
                                showProxyConfigSheet = false
                            }
                            .disabled(proxyHost.isEmpty || Int(proxyPort) == nil)
                        }
                    }
                }
            }
        }
    }

    private func updateCacheSize() async {
        cacheSize = await CacheService.shared.formattedCacheSize
    }
}

struct LinkRow: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "arrow.up.right")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .accessibilityLabel("\(title), opens in browser")
        .accessibilityHint("Double tap to open external link")
    }
}

#Preview(windowStyle: .automatic) {
    SettingsView()
        .environment(ProgramsViewModel())
        .environment(SettingsViewModel())
        .environment(UserPrefsViewModel())
}
