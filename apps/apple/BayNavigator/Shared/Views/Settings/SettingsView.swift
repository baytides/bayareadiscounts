import SwiftUI
import BayNavigatorCore

/// Full Settings view with NavigationStack (use when displayed as a tab)
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            SettingsViewContent()
        }
    }
}

/// Settings content without NavigationStack (use when pushed onto existing navigation)
struct SettingsViewContent: View {
    @Environment(SettingsViewModel.self) private var settingsVM
    @Environment(ProgramsViewModel.self) private var programsVM
    @Environment(UserPrefsViewModel.self) private var userPrefsVM
    @Environment(AccessibilityViewModel.self) private var accessibilityVM
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    #if os(visionOS)
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var showImmersiveSpace = false
    #endif

    @State private var showProfileEdit = false
    @State private var testingConnection = false
    @State private var connectionTestResult: PrivacyTestResult?
    @State private var cacheSize = "Calculating..."

    var body: some View {
        Form {
            #if os(visionOS)
            spatialExperienceSection
            #endif

            profileSection
            appInfoSection
            appearanceSection
            accessibilitySection
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
            // Show saved profile information if available
            if userPrefsVM.hasPreferences {
                // Profile header with avatar
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(userPrefsVM.profileColor)
                            .frame(width: 50, height: 50)

                        Text(userPrefsVM.firstName?.prefix(1).uppercased() ?? "?")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        if let firstName = userPrefsVM.firstName, !firstName.isEmpty {
                            Text(firstName)
                                .font(.headline)
                        }

                        if let location = userPrefsVM.displayLocation {
                            Text(location)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)

                // Birth Year / Age
                if let birthYear = userPrefsVM.birthYear {
                    let currentYear = Calendar.current.component(.year, from: Date())
                    let age = currentYear - birthYear
                    LabeledContent {
                        Text("\(age) years old")
                    } label: {
                        Label("Age", systemImage: "calendar")
                    }
                }

                // Interests/Groups
                if !userPrefsVM.selectedGroups.isEmpty {
                    let groupNames = userPrefsVM.getGroupNames(from: programsVM.groups)
                    if !groupNames.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Interests", systemImage: "heart.fill")
                            FlowLayout(spacing: 6) {
                                ForEach(groupNames, id: \.self) { name in
                                    Text(name)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.appPrimary.opacity(0.1))
                                        .foregroundStyle(Color.appPrimary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Qualifications
                if !userPrefsVM.qualifications.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Qualifications", systemImage: "checkmark.seal.fill")
                        FlowLayout(spacing: 6) {
                            ForEach(userPrefsVM.qualifications, id: \.self) { qual in
                                Text(formatQualification(qual))
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.appAccent.opacity(0.1))
                                    .foregroundStyle(Color.appAccent)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                // No profile set up yet
                HStack {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .foregroundStyle(.secondary)
                    Text("No profile set up yet")
                        .foregroundStyle(.secondary)
                }
            }

            // Edit button - use lightweight sheet for existing profiles, onboarding for new users
            Button {
                if userPrefsVM.hasPreferences {
                    showProfileEdit = true
                } else {
                    userPrefsVM.reopenOnboarding()
                }
            } label: {
                HStack {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundStyle(Color.appPrimary)
                    Text(userPrefsVM.hasPreferences ? "Edit Profile" : "Set Up Profile")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    /// Format qualification ID to display name
    private func formatQualification(_ qual: String) -> String {
        qual.split(separator: "_")
            .map { String($0).capitalized }
            .joined(separator: " ")
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

    private var accessibilitySection: some View {
        Section {
            NavigationLink {
                AccessibilitySettingsView()
                    .environment(accessibilityVM)
            } label: {
                HStack {
                    Label("Accessibility", systemImage: "accessibility")
                    Spacer()
                    if accessibilityVM.hasCustomizations {
                        Text("Customized")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Accessibility")
        } footer: {
            Text("WCAG 2.2 AAA compliant settings for vision, motion, reading, and interaction.")
        }
    }

    // AI search toggle removed - AI features are always enabled
    // Users can access Ask Carl for interactive AI assistance
    private var searchSection: some View {
        Section {
            NavigationLink {
                AskCarlView()
            } label: {
                HStack {
                    Label("Ask Carl", systemImage: "bubble.left.and.bubble.right.fill")
                        .foregroundStyle(Color.appPrimary)
                    Spacer()
                    Text("AI Assistant")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("AI")
        } footer: {
            Text("Carl is your AI-powered assistant for finding Bay Area programs and resources.")
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
            // Privacy mode picker
            Picker("Privacy Mode", selection: Binding(
                get: { settingsVM.privacyMode },
                set: { settingsVM.privacyMode = $0 }
            )) {
                ForEach(PrivacyService.PrivacyMode.allCases) { mode in
                    Label(mode.displayName, systemImage: mode.icon)
                        .tag(mode)
                }
            }

            // Current mode description
            if let status = settingsVM.privacyStatus {
                HStack(spacing: 12) {
                    Image(systemName: status.icon)
                        .foregroundStyle(status.isActive ? Color.appSuccess : Color.appWarning)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(status.description)
                            .font(.subheadline)
                        if let warning = status.warning {
                            Text(warning)
                                .font(.caption)
                                .foregroundStyle(Color.appWarning)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // CDN Provider picker (shown for domain fronting or when auto-detect is enabled)
            if settingsVM.privacyMode == .domainFronting || settingsVM.autoDetectCensorship {
                Picker("CDN Provider", selection: Binding(
                    get: { settingsVM.cdnProvider },
                    set: { settingsVM.cdnProvider = $0 }
                )) {
                    ForEach(PrivacyService.CDNProvider.allCases) { provider in
                        Label(provider.displayName, systemImage: provider.icon)
                            .tag(provider)
                    }
                }

                // Provider description
                Text(settingsVM.cdnProvider.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Auto-detect censorship toggle
            Toggle(isOn: Binding(
                get: { settingsVM.autoDetectCensorship },
                set: { settingsVM.autoDetectCensorship = $0 }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Detect Censorship")
                    Text("Automatically use CDN routing if direct connection fails")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(settingsVM.privacyMode != .standard)

            #if os(iOS)
            // Orbot integration (iOS only)
            if settingsVM.privacyMode == .tor {
                if settingsVM.orbotInstalled {
                    Button {
                        Task {
                            await settingsVM.openOrbot()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.forward.app")
                                .foregroundStyle(Color.appPrimary)
                            Text("Open Orbot")
                            Spacer()
                            if settingsVM.torAvailable {
                                Text("Connected")
                                    .font(.caption)
                                    .foregroundStyle(Color.appSuccess)
                            } else {
                                Text("Not Running")
                                    .font(.caption)
                                    .foregroundStyle(Color.appWarning)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    Link(destination: URL(string: "https://apps.apple.com/app/orbot/id1609461599")!) {
                        HStack {
                            Image(systemName: "arrow.down.app")
                                .foregroundStyle(Color.appPrimary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Install Orbot")
                                Text("Required for Tor network access")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            #endif

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
                        Text("\(result.latencyMs)ms • \(result.mode.displayName)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Privacy & Censorship Circumvention")
        } footer: {
            switch settingsVM.privacyMode {
            case .standard:
                Text("Direct connection to Bay Navigator servers. Enable auto-detect for automatic fallback if blocked.")
            case .domainFronting:
                Text("Routes through Cloudflare CDN. Traffic appears as normal web browsing, bypassing most censorship.")
            case .tor:
                Text("Routes through Tor network for maximum privacy. Requires the Orbot app on iOS.")
            }
        }
        .sheet(isPresented: $showProfileEdit) {
            ProfileEditSheet()
                .environment(userPrefsVM)
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
            NavigationLink {
                WebContentView(title: "Terms of Service", url: SettingsViewModel.termsURL)
            } label: {
                Text("Terms of Service")
            }

            NavigationLink {
                WebContentView(title: "Privacy Policy", url: SettingsViewModel.privacyURL)
            } label: {
                Text("Privacy Policy")
            }

            NavigationLink {
                WebContentView(title: "Credits", url: SettingsViewModel.creditsURL)
            } label: {
                Text("Credits")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(SettingsViewModel())
        .environment(ProgramsViewModel())
        .environment(UserPrefsViewModel())
        .environment(AccessibilityViewModel())
}
