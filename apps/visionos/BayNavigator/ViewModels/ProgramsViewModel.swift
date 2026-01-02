import SwiftUI

@Observable
final class ProgramsViewModel {
    // MARK: - Data
    private(set) var programs: [Program] = []
    private(set) var categories: [ProgramCategory] = []
    private(set) var groups: [ProgramGroup] = []
    private(set) var areas: [Area] = []
    private(set) var metadata: APIMetadata?

    // MARK: - State
    private(set) var isLoading = false
    private(set) var error: String?
    var filterState = FilterState()
    var sortOption: SortOption = .recentlyVerified

    // MARK: - Favorites
    private(set) var favorites: Set<String> = []

    private let api = APIService.shared
    private let cache = CacheService.shared

    // Names for "Other" areas (what programs actually store)
    private static let otherAreaNames: Set<String> = ["Bay Area", "Statewide", "Nationwide"]

    init() {
        Task {
            favorites = await cache.getFavorites()
        }
    }

    // MARK: - Helper Methods

    /// Convert area ID to area name (programs store names, not IDs)
    private func getAreaName(_ areaId: String) -> String? {
        areas.first { $0.id == areaId }?.name
    }

    // MARK: - Computed Properties

    var filteredPrograms: [Program] {
        var result = programs

        // Apply search query
        if !filterState.searchQuery.isEmpty {
            let query = filterState.searchQuery.lowercased()
            result = result.filter { program in
                program.name.lowercased().contains(query) ||
                program.description.lowercased().contains(query)
            }
        }

        // Apply category filter
        if !filterState.categories.isEmpty {
            result = result.filter { filterState.categories.contains($0.category) }
        }

        // Apply groups filter (formerly eligibility)
        if !filterState.groups.isEmpty {
            result = result.filter { program in
                filterState.groups.contains { program.groups.contains($0) }
            }
        }

        // Apply area filter
        if !filterState.areas.isEmpty {
            // Check if "Other" is selected (any of bay-area, statewide, nationwide)
            let hasOtherSelected = filterState.areas.contains { FilterState.otherAreaIds.contains($0) }
            // Get selected county IDs and convert to names for comparison
            let selectedCountyIds = filterState.areas.filter { !FilterState.otherAreaIds.contains($0) }
            let selectedCountyNames = Set(selectedCountyIds.compactMap { getAreaName($0) })

            result = result.filter { program in
                // Programs store area names like "Bay Area", "Statewide", "San Francisco"
                let isUniversal = program.areas.contains { Self.otherAreaNames.contains($0) }
                let matchesCounty = program.areas.contains { selectedCountyNames.contains($0) }

                if hasOtherSelected && selectedCountyNames.isEmpty {
                    // Only "Other" selected: show only universal programs
                    return isUniversal
                } else if hasOtherSelected && !selectedCountyNames.isEmpty {
                    // Both "Other" and counties selected: show universal + matching counties
                    return isUniversal || matchesCounty
                } else {
                    // Only counties selected: show matching counties + universal (they apply everywhere)
                    return matchesCounty || isUniversal
                }
            }
        }

        // Apply sorting
        switch sortOption {
        case .recentlyVerified:
            result.sort { ($0.lastUpdatedDate ?? .distantPast) > ($1.lastUpdatedDate ?? .distantPast) }
        case .nameAsc:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDesc:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .categoryAsc:
            result.sort { $0.category.localizedCaseInsensitiveCompare($1.category) == .orderedAscending }
        }

        return result
    }

    var favoritePrograms: [Program] {
        programs.filter { favorites.contains($0.id) }
    }

    var countyAreas: [Area] {
        areas.filter { $0.isCounty }
    }

    // MARK: - Data Loading

    @MainActor
    func loadData(forceRefresh: Bool = false) async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            async let programsTask = api.getPrograms(forceRefresh: forceRefresh)
            async let categoriesTask = api.getCategories(forceRefresh: forceRefresh)
            async let groupsTask = api.getGroups(forceRefresh: forceRefresh)
            async let areasTask = api.getAreas(forceRefresh: forceRefresh)
            async let metadataTask = api.getMetadata(forceRefresh: forceRefresh)

            let (loadedPrograms, loadedCategories, loadedGroups, loadedAreas, loadedMetadata) =
                try await (programsTask, categoriesTask, groupsTask, areasTask, metadataTask)

            self.programs = loadedPrograms
            self.categories = loadedCategories
            self.groups = loadedGroups
            self.areas = loadedAreas
            self.metadata = loadedMetadata
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    func refreshMetadata() async {
        do {
            metadata = try await api.getMetadata(forceRefresh: true)
        } catch {
            // Silently fail
        }
    }

    // MARK: - Filtering

    func setSearchQuery(_ query: String) {
        filterState.searchQuery = query
    }

    func toggleCategory(_ id: String) {
        if filterState.categories.contains(id) {
            filterState.categories.remove(id)
        } else {
            filterState.categories.insert(id)
        }
    }

    func toggleGroup(_ id: String) {
        if filterState.groups.contains(id) {
            filterState.groups.remove(id)
        } else {
            filterState.groups.insert(id)
        }
    }

    func toggleArea(_ id: String) {
        if filterState.areas.contains(id) {
            filterState.areas.remove(id)
        } else {
            filterState.areas.insert(id)
        }
    }

    func toggleOtherAreas() {
        filterState.toggleOtherAreas()
    }

    func clearFilters() {
        filterState.clear()
    }

    // MARK: - Dynamic Filter Counts

    func getCategoryCount(_ id: String) -> Int {
        var tempFilter = filterState
        tempFilter.categories.removeAll()

        return programsMatchingFilter(tempFilter).filter { $0.category == id }.count
    }

    func getGroupCount(_ id: String) -> Int {
        var tempFilter = filterState
        tempFilter.groups.removeAll()

        return programsMatchingFilter(tempFilter).filter { $0.groups.contains(id) }.count
    }

    func getAreaCount(_ id: String) -> Int {
        guard let areaName = getAreaName(id) else { return 0 }
        var tempFilter = filterState
        tempFilter.areas.removeAll()

        return programsMatchingFilter(tempFilter).filter { $0.areas.contains(areaName) }.count
    }

    func getOtherAreasCount() -> Int {
        var tempFilter = filterState
        tempFilter.areas.removeAll()

        return programsMatchingFilter(tempFilter).filter { program in
            program.areas.contains { Self.otherAreaNames.contains($0) }
        }.count
    }

    private func programsMatchingFilter(_ filter: FilterState) -> [Program] {
        var result = programs

        if !filter.searchQuery.isEmpty {
            let query = filter.searchQuery.lowercased()
            result = result.filter { program in
                program.name.lowercased().contains(query) ||
                program.description.lowercased().contains(query)
            }
        }

        if !filter.categories.isEmpty {
            result = result.filter { filter.categories.contains($0.category) }
        }

        if !filter.groups.isEmpty {
            result = result.filter { program in
                filter.groups.contains { program.groups.contains($0) }
            }
        }

        if !filter.areas.isEmpty {
            // Check if "Other" is selected (any of bay-area, statewide, nationwide)
            let hasOtherSelected = filter.areas.contains { FilterState.otherAreaIds.contains($0) }
            // Get selected county IDs and convert to names for comparison
            let selectedCountyIds = filter.areas.filter { !FilterState.otherAreaIds.contains($0) }
            let selectedCountyNames = Set(selectedCountyIds.compactMap { getAreaName($0) })

            result = result.filter { program in
                let isUniversal = program.areas.contains { Self.otherAreaNames.contains($0) }
                let matchesCounty = program.areas.contains { selectedCountyNames.contains($0) }

                if hasOtherSelected && selectedCountyNames.isEmpty {
                    return isUniversal
                } else if hasOtherSelected && !selectedCountyNames.isEmpty {
                    return isUniversal || matchesCounty
                } else {
                    return matchesCounty || isUniversal
                }
            }
        }

        return result
    }

    // MARK: - Favorites

    func isFavorite(_ id: String) -> Bool {
        favorites.contains(id)
    }

    func toggleFavorite(_ id: String) {
        if favorites.contains(id) {
            favorites.remove(id)
            Task {
                await cache.removeFavorite(id)
            }
        } else {
            favorites.insert(id)
            Task {
                await cache.addFavorite(id)
            }
        }
    }
}
