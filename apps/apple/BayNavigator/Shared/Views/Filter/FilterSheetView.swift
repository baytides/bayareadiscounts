import SwiftUI
import BayNavigatorCore

struct FilterSheetView: View {
    @Environment(ProgramsViewModel.self) private var programsVM
    @Environment(\.dismiss) private var dismiss

    @State private var localFilter: FilterState
    @State private var localSortOption: SortOption

    init(filter: FilterState) {
        _localFilter = State(initialValue: filter)
        _localSortOption = State(initialValue: .recentlyVerified)
    }

    var body: some View {
        NavigationStack {
            Form {
                categoriesSection
                groupsSection
                areasSection
                sortSection
            }
            .navigationTitle("Filters")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        programsVM.filterState = localFilter
                        programsVM.sortOption = localSortOption
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .safeAreaInset(edge: .bottom) {
                clearFiltersButton
            }
            .onAppear {
                localSortOption = programsVM.sortOption
            }
        }
        #if os(iOS)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        #endif
    }

    // MARK: - Sections

    private var categoriesSection: some View {
        Section {
            ForEach(programsVM.categories) { category in
                Toggle(isOn: Binding(
                    get: { localFilter.categories.contains(category.id) },
                    set: { isSelected in
                        if isSelected {
                            localFilter.categories.insert(category.id)
                        } else {
                            localFilter.categories.remove(category.id)
                        }
                    }
                )) {
                    HStack {
                        categoryIcon(for: category.name)
                        Text(category.name)
                    }
                }
                .tint(Color.appPrimary)
            }
        } header: {
            HStack {
                Text("Categories")
                Spacer()
                if !localFilter.categories.isEmpty {
                    Text("\(localFilter.categories.count) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var groupsSection: some View {
        Section {
            ForEach(programsVM.groups) { group in
                Toggle(isOn: Binding(
                    get: { localFilter.groups.contains(group.id) },
                    set: { isSelected in
                        if isSelected {
                            localFilter.groups.insert(group.id)
                        } else {
                            localFilter.groups.remove(group.id)
                        }
                    }
                )) {
                    HStack {
                        groupIcon(for: group.name)
                        Text(group.name)
                    }
                }
                .tint(Color.appPrimary)
            }
        } header: {
            HStack {
                Text("Target Groups")
                Spacer()
                if !localFilter.groups.isEmpty {
                    Text("\(localFilter.groups.count) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var areasSection: some View {
        Section {
            // "Other" areas toggle (Bay Area, Statewide, Nationwide)
            Toggle(isOn: Binding(
                get: { localFilter.hasOtherAreasSelected },
                set: { _ in localFilter.toggleOtherAreas() }
            )) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundStyle(Color.appInfo)
                        .frame(width: 24)
                    Text("Bay Area / Statewide / Nationwide")
                }
            }
            .tint(Color.appPrimary)

            // County areas
            ForEach(programsVM.countyAreas) { area in
                Toggle(isOn: Binding(
                    get: { localFilter.areas.contains(area.id) },
                    set: { isSelected in
                        if isSelected {
                            localFilter.areas.insert(area.id)
                        } else {
                            localFilter.areas.remove(area.id)
                        }
                    }
                )) {
                    HStack {
                        Image(systemName: "mappin.circle")
                            .foregroundStyle(Color.appAccent)
                            .frame(width: 24)
                        Text(area.name)
                    }
                }
                .tint(Color.appPrimary)
            }
        } header: {
            HStack {
                Text("Location")
                Spacer()
                if localFilter.selectedAreaDisplayCount > 0 {
                    Text("\(localFilter.selectedAreaDisplayCount) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } footer: {
            Text("Filter programs by the area they serve.")
        }
    }

    private var sortSection: some View {
        Section {
            Picker("Sort By", selection: $localSortOption) {
                ForEach(SortOption.allCases) { option in
                    HStack {
                        Image(systemName: sortIcon(for: option))
                        Text(option.rawValue)
                    }
                    .tag(option)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Sorting")
        }
    }

    private var clearFiltersButton: some View {
        Button(role: .destructive) {
            localFilter = FilterState()
            localSortOption = .recentlyVerified
        } label: {
            HStack {
                Image(systemName: "xmark.circle.fill")
                Text("Clear All Filters")
            }
            .frame(maxWidth: .infinity)
            .padding()
            #if os(iOS)
            .background(.regularMaterial)
            #endif
        }
        .disabled(!localFilter.hasFilters && localSortOption == .recentlyVerified)
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func categoryIcon(for name: String) -> some View {
        let iconName: String
        switch name.lowercased() {
        case let n where n.contains("food"):
            iconName = "fork.knife"
        case let n where n.contains("housing"):
            iconName = "house"
        case let n where n.contains("health"):
            iconName = "heart"
        case let n where n.contains("employment"):
            iconName = "briefcase"
        case let n where n.contains("education"):
            iconName = "book"
        case let n where n.contains("legal"):
            iconName = "scale.3d"
        case let n where n.contains("money"), let n where n.contains("financial"):
            iconName = "dollarsign.circle"
        default:
            iconName = "folder"
        }
        return Image(systemName: iconName)
            .foregroundStyle(Color.appPrimary)
            .frame(width: 24)
    }

    private func groupIcon(for name: String) -> some View {
        let iconName: String
        switch name.lowercased() {
        case let n where n.contains("senior") || n.contains("older"):
            iconName = "person.crop.circle"
        case let n where n.contains("child") || n.contains("youth"):
            iconName = "figure.child"
        case let n where n.contains("family"):
            iconName = "figure.2.and.child.holdinghands"
        case let n where n.contains("veteran"):
            iconName = "shield.checkered"
        case let n where n.contains("disabled") || n.contains("disability"):
            iconName = "figure.roll"
        case let n where n.contains("immigrant"):
            iconName = "globe.americas"
        case let n where n.contains("homeless"):
            iconName = "house.lodge"
        default:
            iconName = "person.3"
        }
        return Image(systemName: iconName)
            .foregroundStyle(Color.appAccent)
            .frame(width: 24)
    }

    private func sortIcon(for option: SortOption) -> String {
        switch option {
        case .recentlyVerified:
            return "clock"
        case .nameAsc:
            return "textformat.abc"
        case .nameDesc:
            return "textformat.abc"
        case .categoryAsc:
            return "folder"
        case .distanceAsc:
            return "location"
        }
    }
}

#Preview {
    FilterSheetView(filter: FilterState())
        .environment(ProgramsViewModel())
}
