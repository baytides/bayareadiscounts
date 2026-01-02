import Foundation

// MARK: - Shared Program Model

struct SharedProgram: Identifiable, Codable {
    let id: String
    let name: String
    let category: String
    let description: String
    let website: String

    init(id: String, name: String, category: String, description: String, website: String) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.website = website
    }
}

// MARK: - Shared Data Manager

class SharedDataManager: ObservableObject {
    @Published var savedPrograms: [SharedProgram] = []

    // App Group identifier - must match the one in the main app
    private let appGroupIdentifier = "group.org.baytides.baynavigator"
    private let savedProgramsKey = "savedPrograms"

    init() {
        loadSavedPrograms()
    }

    func loadSavedPrograms() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            loadFallbackPrograms()
            return
        }

        if let data = sharedDefaults.data(forKey: savedProgramsKey) {
            do {
                let programs = try JSONDecoder().decode([SharedProgram].self, from: data)
                DispatchQueue.main.async {
                    self.savedPrograms = programs
                }
            } catch {
                loadFallbackPrograms()
            }
        } else {
            // No saved programs yet
            DispatchQueue.main.async {
                self.savedPrograms = []
            }
        }
    }

    private func loadFallbackPrograms() {
        // If App Groups aren't set up yet, show example programs for testing in debug builds
        #if DEBUG
        DispatchQueue.main.async {
            self.savedPrograms = [
                SharedProgram(
                    id: "sample-1",
                    name: "SF Parks Free Recreation Programs",
                    category: "Recreation",
                    description: "Free recreation programs at San Francisco parks including sports, fitness classes, and cultural activities.",
                    website: "https://sfrecpark.org"
                ),
                SharedProgram(
                    id: "sample-2",
                    name: "Medi-Cal Health Coverage",
                    category: "Health",
                    description: "Free or low-cost health coverage for eligible California residents.",
                    website: "https://www.medi-cal.ca.gov"
                ),
                SharedProgram(
                    id: "sample-3",
                    name: "CalFresh Food Benefits",
                    category: "Food",
                    description: "Monthly food benefits to help income-eligible households buy nutritious food.",
                    website: "https://www.getcalfresh.org"
                )
            ]
        }
        #else
        DispatchQueue.main.async {
            self.savedPrograms = []
        }
        #endif
    }
}

// MARK: - Extension for saving from main app

extension SharedDataManager {
    /// Call this from the main Flutter app to save programs for sharing
    static func savePrograms(_ programs: [SharedProgram]) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.org.baytides.baynavigator") else {
            return
        }

        do {
            let data = try JSONEncoder().encode(programs)
            sharedDefaults.set(data, forKey: "savedPrograms")
            sharedDefaults.synchronize()
        } catch {
            // Encoding failed, programs not saved
        }
    }
}
