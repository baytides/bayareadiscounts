import SwiftUI

@Observable
public final class UserPrefsViewModel {
    // Legacy fields
    public var selectedGroups: [String] = []
    public var selectedCounty: String?
    public var onboardingComplete: Bool = false
    public var showOnboarding: Bool = false

    // New profile fields
    public var firstName: String?
    public var city: String?
    public var zipCode: String?
    public var birthYear: Int?
    public var qualifications: [String] = []
    public var isMilitaryOrVeteran: Bool?

    private let cache = CacheService.shared

    public var hasPreferences: Bool {
        !selectedGroups.isEmpty || selectedCounty != nil || firstName != nil
    }

    /// Display location: city name, or county name if no city
    public var displayLocation: String? {
        if let city = city, !city.isEmpty {
            return city
        }
        if let county = selectedCounty {
            return countyIdToDisplayName(county)
        }
        return nil
    }

    public init() {
        Task {
            await loadPreferences()
        }
    }

    @MainActor
    public func loadPreferences() async {
        selectedGroups = await cache.getUserGroups()
        selectedCounty = await cache.getUserCounty()
        onboardingComplete = await cache.isOnboardingComplete()

        // Load new profile fields
        firstName = await cache.getUserFirstName()
        city = await cache.getUserCity()
        zipCode = await cache.getUserZipCode()
        birthYear = await cache.getUserBirthYear()
        qualifications = await cache.getUserQualifications()
        isMilitaryOrVeteran = await cache.getUserIsMilitary()

        // Show onboarding if not complete
        if !onboardingComplete {
            showOnboarding = true
        }
    }

    /// Save all profile preferences (new comprehensive method)
    public func savePreferences(
        firstName: String? = nil,
        city: String? = nil,
        zipCode: String? = nil,
        county: String? = nil,
        birthYear: Int? = nil,
        isMilitaryOrVeteran: Bool? = nil,
        qualifications: [String] = [],
        groups: [String] = []
    ) async {
        await cache.setUserFirstName(firstName)
        await cache.setUserCity(city)
        await cache.setUserZipCode(zipCode)
        await cache.setUserCounty(county)
        await cache.setUserBirthYear(birthYear)
        await cache.setUserIsMilitary(isMilitaryOrVeteran)
        await cache.setUserQualifications(qualifications)
        await cache.setUserGroups(groups)

        await MainActor.run {
            self.firstName = firstName
            self.city = city
            self.zipCode = zipCode
            self.selectedCounty = county
            self.birthYear = birthYear
            self.isMilitaryOrVeteran = isMilitaryOrVeteran
            self.qualifications = qualifications
            self.selectedGroups = groups
        }
    }

    /// Legacy save method for backward compatibility
    public func savePreferences(groups: [String], county: String?) async {
        await cache.setUserGroups(groups)
        await cache.setUserCounty(county)

        await MainActor.run {
            self.selectedGroups = groups
            self.selectedCounty = county
        }
    }

    public func completeOnboarding() async {
        await cache.setOnboardingComplete(true)
        await MainActor.run {
            self.onboardingComplete = true
            self.showOnboarding = false
        }
    }

    public func reopenOnboarding() {
        showOnboarding = true
    }

    public func getGroupNames(from allGroups: [ProgramGroup]) -> [String] {
        selectedGroups.compactMap { groupId in
            allGroups.first { $0.id == groupId }?.name
        }
    }

    public func getCountyName(from allAreas: [Area]) -> String? {
        guard let countyId = selectedCounty else { return nil }
        return allAreas.first { $0.id == countyId }?.name
    }

    /// Convert county ID to display name (e.g., "alameda-county" -> "Alameda County")
    private func countyIdToDisplayName(_ countyId: String) -> String {
        countyId.split(separator: "-")
            .map { String($0).capitalized }
            .joined(separator: " ")
    }
}
