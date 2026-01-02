import SwiftUI

@main
struct BayNavigatorApp: App {
    @State private var programsViewModel = ProgramsViewModel()
    @State private var settingsViewModel = SettingsViewModel()
    @State private var userPrefsViewModel = UserPrefsViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(programsViewModel)
                .environment(settingsViewModel)
                .environment(userPrefsViewModel)
                .preferredColorScheme(settingsViewModel.colorScheme)
                .warmMode(settingsViewModel.warmModeEnabled)
        }
        .defaultSize(width: 1200, height: 900)

        // Immersive space for spatial experience
        ImmersiveSpace(id: "WelcomeSpace") {
            ImmersiveWelcomeView()
                .environment(programsViewModel)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
