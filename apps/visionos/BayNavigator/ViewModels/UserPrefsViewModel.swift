import SwiftUI

@Observable
final class UserPrefsViewModel {
    var selectedGroups: [String] = []
    var selectedCounty: String?
    var onboardingComplete: Bool = false
    var showOnboarding: Bool = false

    private let cache = CacheService.shared

    var hasPreferences: Bool {
        !selectedGroups.isEmpty || selectedCounty != nil
    }

    init() {
        Task {
            await loadPreferences()
        }
    }

    @MainActor
    func loadPreferences() async {
        selectedGroups = await cache.getUserGroups()
        selectedCounty = await cache.getUserCounty()
        onboardingComplete = await cache.isOnboardingComplete()

        // Show onboarding if not complete
        if !onboardingComplete {
            showOnboarding = true
        }
    }

    func savePreferences(groups: [String], county: String?) async {
        await cache.setUserGroups(groups)
        await cache.setUserCounty(county)

        await MainActor.run {
            self.selectedGroups = groups
            self.selectedCounty = county
        }
    }

    func completeOnboarding() async {
        await cache.setOnboardingComplete(true)
        await MainActor.run {
            self.onboardingComplete = true
            self.showOnboarding = false
        }
    }

    func reopenOnboarding() {
        showOnboarding = true
    }

    func getGroupNames(from allGroups: [ProgramGroup]) -> [String] {
        selectedGroups.compactMap { groupId in
            allGroups.first { $0.id == groupId }?.name
        }
    }

    func getCountyName(from allAreas: [Area]) -> String? {
        guard let countyId = selectedCounty else { return nil }
        return allAreas.first { $0.id == countyId }?.name
    }
}
