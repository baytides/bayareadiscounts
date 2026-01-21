import Foundation
import SwiftUI

// MARK: - User Profile Model

/// Represents a user profile for multi-profile support
/// Each household member can have their own profile with saved programs
public struct UserProfile: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var city: String?
    public var zipCode: String?
    public var county: String?  // Derived from city/zip, used for filtering
    public var birthYear: Int?
    public var relationship: ProfileRelationship
    public var colorIndex: Int
    public var qualifications: [String]
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        name: String,
        city: String? = nil,
        zipCode: String? = nil,
        county: String? = nil,
        birthYear: Int? = nil,
        relationship: ProfileRelationship = .myself,
        colorIndex: Int = 0,
        qualifications: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.city = city
        self.zipCode = zipCode
        self.county = county
        self.birthYear = birthYear
        self.relationship = relationship
        self.colorIndex = colorIndex
        self.qualifications = qualifications
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var initial: String {
        name.first.map(String.init) ?? "?"
    }

    public var color: Color {
        Self.profileColors[safe: colorIndex] ?? Self.profileColors[0]
    }

    /// Get the display location text
    public var locationDisplay: String? {
        if let city = city, let zip = zipCode {
            return "\(city), \(zip)"
        }
        return city ?? zipCode ?? county
    }

    /// Calculate approximate age from birth year
    public var approximateAge: Int? {
        guard let birthYear = birthYear else { return nil }
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear - birthYear
    }

    // MARK: - Static Data

    public static let profileColors: [Color] = [
        Color(hex: "00ACC1"),   // Teal (primary)
        Color(hex: "FF6F00"),   // Orange
        Color(hex: "8B5CF6"),   // Purple
        Color(hex: "22C55E"),   // Green
        Color(hex: "3B82F6"),   // Blue
        Color(hex: "EF4444"),   // Red
        Color(hex: "F59E0B"),   // Amber
        Color(hex: "EC4899"),   // Pink
        Color(hex: "6366F1"),   // Indigo
        Color(hex: "14B8A6"),   // Cyan
    ]

    public static let maxProfiles = 6
    public static let maxSavedPerProfile = 50
}

// MARK: - Profile Relationship

public enum ProfileRelationship: String, Codable, CaseIterable, Identifiable, Sendable {
    case myself = "Self"
    case child = "Child"
    case parent = "Parent"
    case spouse = "Spouse"
    case sibling = "Sibling"
    case other = "Other"

    public var id: String { rawValue }

    public var displayName: String { rawValue }

    public var systemImage: String {
        switch self {
        case .myself: return "person.fill"
        case .child: return "figure.and.child.holdinghands"
        case .parent: return "person.2.fill"
        case .spouse: return "heart.fill"
        case .sibling: return "person.2"
        case .other: return "person.crop.circle"
        }
    }
}

// MARK: - Profile Qualification

public enum ProfileQualification: String, Codable, CaseIterable, Identifiable, Sendable {
    case veteran = "veteran"
    case lgbtq = "lgbtq"
    case immigrant = "immigrant"
    case firstResponder = "first-responder"
    case educator = "educator"
    case unemployed = "unemployed"
    case publicAssistance = "public-assistance"
    case student = "student"
    case disability = "disability"
    case caregiver = "caregiver"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .veteran: return "Veteran/Military"
        case .lgbtq: return "LGBTQ+"
        case .immigrant: return "Immigrant"
        case .firstResponder: return "First Responder"
        case .educator: return "Educator"
        case .unemployed: return "Job Seeking"
        case .publicAssistance: return "Public Assistance"
        case .student: return "Student"
        case .disability: return "Disability"
        case .caregiver: return "Caregiver"
        }
    }

    public var systemImage: String {
        switch self {
        case .veteran: return "shield.fill"
        case .lgbtq: return "heart.circle.fill"
        case .immigrant: return "globe.americas.fill"
        case .firstResponder: return "cross.circle.fill"
        case .educator: return "book.fill"
        case .unemployed: return "briefcase"
        case .publicAssistance: return "banknote"
        case .student: return "graduationcap.fill"
        case .disability: return "figure.roll"
        case .caregiver: return "hand.raised.fill"
        }
    }

    /// Qualifications that may contain sensitive information
    public static let sensitiveQualifications: Set<ProfileQualification> = [
        .lgbtq, .immigrant, .disability
    ]

    public var isSensitive: Bool {
        Self.sensitiveQualifications.contains(self)
    }
}

// MARK: - Profile Saved Programs

/// Tracks saved programs for a specific profile
public struct ProfileSavedProgram: Codable, Identifiable, Sendable {
    public let programId: String
    public let savedAt: Date
    public var status: FavoriteStatus
    public var notes: String?
    public var statusUpdatedAt: Date?

    public var id: String { programId }

    public init(
        programId: String,
        savedAt: Date = Date(),
        status: FavoriteStatus = .saved,
        notes: String? = nil,
        statusUpdatedAt: Date? = nil
    ) {
        self.programId = programId
        self.savedAt = savedAt
        self.status = status
        self.notes = notes
        self.statusUpdatedAt = statusUpdatedAt
    }
}

// MARK: - Profile Service

/// Service for managing user profiles
/// Supports up to 6 profiles with individual saved programs per profile
public actor ProfileService {
    public static let shared = ProfileService()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let profiles = "baynavigator:profiles"
        static let activeProfileId = "baynavigator:active_profile_id"
        static func savedPrograms(profileId: String) -> String {
            "baynavigator:profile_saved:\(profileId)"
        }
    }

    // MARK: - Profile Management

    /// Get all profiles
    public func getProfiles() -> [UserProfile] {
        guard let data = defaults.data(forKey: Keys.profiles),
              let profiles = try? JSONDecoder().decode([UserProfile].self, from: data) else {
            return []
        }
        return profiles.sorted { $0.createdAt < $1.createdAt }
    }

    /// Save all profiles
    private func saveProfiles(_ profiles: [UserProfile]) {
        if let data = try? JSONEncoder().encode(profiles) {
            defaults.set(data, forKey: Keys.profiles)
        }
    }

    /// Create a new profile
    public func createProfile(
        name: String,
        city: String? = nil,
        zipCode: String? = nil,
        county: String? = nil,
        birthYear: Int? = nil,
        relationship: ProfileRelationship = .myself,
        colorIndex: Int = 0,
        qualifications: [String] = []
    ) -> UserProfile? {
        var profiles = getProfiles()

        // Check limit
        guard profiles.count < UserProfile.maxProfiles else {
            return nil
        }

        let profile = UserProfile(
            name: name,
            city: city,
            zipCode: zipCode,
            county: county,
            birthYear: birthYear,
            relationship: relationship,
            colorIndex: colorIndex,
            qualifications: qualifications
        )

        profiles.append(profile)
        saveProfiles(profiles)

        // If this is the first profile, make it active
        if profiles.count == 1 {
            setActiveProfileId(profile.id)
        }

        return profile
    }

    /// Update an existing profile
    public func updateProfile(_ profile: UserProfile) {
        var profiles = getProfiles()
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            var updated = profile
            updated.updatedAt = Date()
            profiles[index] = updated
            saveProfiles(profiles)
        }
    }

    /// Delete a profile and its saved programs
    public func deleteProfile(_ profileId: String) {
        var profiles = getProfiles()
        profiles.removeAll { $0.id == profileId }
        saveProfiles(profiles)

        // Remove saved programs for this profile
        defaults.removeObject(forKey: Keys.savedPrograms(profileId: profileId))

        // If deleted profile was active, switch to first available
        if getActiveProfileId() == profileId {
            if let first = profiles.first {
                setActiveProfileId(first.id)
            } else {
                defaults.removeObject(forKey: Keys.activeProfileId)
            }
        }
    }

    /// Get profile by ID
    public func getProfile(_ id: String) -> UserProfile? {
        getProfiles().first { $0.id == id }
    }

    // MARK: - Active Profile

    /// Get the active profile ID
    public func getActiveProfileId() -> String? {
        defaults.string(forKey: Keys.activeProfileId)
    }

    /// Set the active profile ID
    public func setActiveProfileId(_ id: String?) {
        if let id = id {
            defaults.set(id, forKey: Keys.activeProfileId)
        } else {
            defaults.removeObject(forKey: Keys.activeProfileId)
        }
    }

    /// Get the active profile
    public func getActiveProfile() -> UserProfile? {
        guard let id = getActiveProfileId() else {
            // Default to first profile if none active
            let profiles = getProfiles()
            if let first = profiles.first {
                setActiveProfileId(first.id)
                return first
            }
            return nil
        }
        return getProfile(id)
    }

    // MARK: - Saved Programs Per Profile

    /// Get saved programs for a profile
    public func getSavedPrograms(for profileId: String) -> [ProfileSavedProgram] {
        let key = Keys.savedPrograms(profileId: profileId)
        guard let data = defaults.data(forKey: key),
              let programs = try? JSONDecoder().decode([ProfileSavedProgram].self, from: data) else {
            return []
        }
        return programs
    }

    /// Save programs for a profile
    private func saveProgramsForProfile(_ programs: [ProfileSavedProgram], profileId: String) {
        let key = Keys.savedPrograms(profileId: profileId)
        if let data = try? JSONEncoder().encode(programs) {
            defaults.set(data, forKey: key)
        }
    }

    /// Add a saved program to a profile
    public func addSavedProgram(_ programId: String, to profileId: String) -> Bool {
        var programs = getSavedPrograms(for: profileId)

        // Check limit
        guard programs.count < UserProfile.maxSavedPerProfile else {
            return false
        }

        // Check if already saved
        guard !programs.contains(where: { $0.programId == programId }) else {
            return true
        }

        let saved = ProfileSavedProgram(programId: programId)
        programs.append(saved)
        saveProgramsForProfile(programs, profileId: profileId)
        return true
    }

    /// Remove a saved program from a profile
    public func removeSavedProgram(_ programId: String, from profileId: String) {
        var programs = getSavedPrograms(for: profileId)
        programs.removeAll { $0.programId == programId }
        saveProgramsForProfile(programs, profileId: profileId)
    }

    /// Check if a program is saved for a profile
    public func isProgramSaved(_ programId: String, for profileId: String) -> Bool {
        getSavedPrograms(for: profileId).contains { $0.programId == programId }
    }

    /// Update status for a saved program
    public func updateProgramStatus(_ programId: String, for profileId: String, status: FavoriteStatus) {
        var programs = getSavedPrograms(for: profileId)
        if let index = programs.firstIndex(where: { $0.programId == programId }) {
            programs[index].status = status
            programs[index].statusUpdatedAt = Date()
            saveProgramsForProfile(programs, profileId: profileId)
        }
    }

    /// Update notes for a saved program
    public func updateProgramNotes(_ programId: String, for profileId: String, notes: String?) {
        var programs = getSavedPrograms(for: profileId)
        if let index = programs.firstIndex(where: { $0.programId == programId }) {
            programs[index].notes = notes
            programs[index].statusUpdatedAt = Date()
            saveProgramsForProfile(programs, profileId: profileId)
        }
    }

    /// Get saved program count for a profile
    public func getSavedProgramCount(for profileId: String) -> Int {
        getSavedPrograms(for: profileId).count
    }

    // MARK: - Convenience for Active Profile

    /// Add saved program to active profile
    public func addSavedProgramToActive(_ programId: String) -> Bool {
        guard let activeId = getActiveProfileId() else { return false }
        return addSavedProgram(programId, to: activeId)
    }

    /// Remove saved program from active profile
    public func removeSavedProgramFromActive(_ programId: String) {
        guard let activeId = getActiveProfileId() else { return }
        removeSavedProgram(programId, from: activeId)
    }

    /// Check if program is saved in active profile
    public func isProgramSavedInActive(_ programId: String) -> Bool {
        guard let activeId = getActiveProfileId() else { return false }
        return isProgramSaved(programId, for: activeId)
    }

    /// Get saved programs for active profile
    public func getActiveSavedPrograms() -> [ProfileSavedProgram] {
        guard let activeId = getActiveProfileId() else { return [] }
        return getSavedPrograms(for: activeId)
    }
}

// MARK: - Array Extension

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
