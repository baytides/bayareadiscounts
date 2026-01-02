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
                            await programsViewModel.loadData(forceRefresh: true)
                            isRefreshing = false
                        }
                    } label: {
                        HStack {
                            Text("Refresh Database")
                            Spacer()
                            if isRefreshing {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                    }
                    .disabled(isRefreshing)
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
                            await settingsViewModel.clearCache()
                            await updateCacheSize()
                        }
                    } label: {
                        Text("Clear Cache")
                    }
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
        }
    }
}

#Preview(windowStyle: .automatic) {
    SettingsView()
        .environment(ProgramsViewModel())
        .environment(SettingsViewModel())
        .environment(UserPrefsViewModel())
}
