import SwiftUI

struct HomeView: View {
    @Environment(ProgramsViewModel.self) private var viewModel
    @State private var showingFilters = false
    @State private var showingSort = false
    @State private var selectedProgram: Program?

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.programs.isEmpty {
                    ProgressView("Loading programs...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error, viewModel.programs.isEmpty {
                    ErrorView(message: error) {
                        Task {
                            await viewModel.loadData(forceRefresh: true)
                        }
                    }
                } else {
                    programList
                }
            }
            .navigationTitle("Bay Navigator")
            .navigationDestination(item: $selectedProgram) { program in
                ProgramDetailView(program: program)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingFilters = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            if viewModel.filterState.filterCount > 0 {
                                Text("\(viewModel.filterState.filterCount)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }

                ToolbarItem(placement: .secondaryAction) {
                    Menu {
                        Picker("Sort by", selection: $viewModel.sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterSheetView()
            }
            .refreshable {
                await viewModel.loadData(forceRefresh: true)
            }
        }
    }

    // Adaptive grid columns for visionOS spatial layout
    private let gridColumns = [
        GridItem(.adaptive(minimum: 320, maximum: 400), spacing: 16)
    ]

    private var programList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Search bar
                searchBar
                    .padding(.horizontal)
                    .padding(.bottom, 12)

                // Results count
                HStack {
                    Text("\(viewModel.filteredPrograms.count) program\(viewModel.filteredPrograms.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if viewModel.filterState.hasFilters {
                        Button("Clear") {
                            viewModel.clearFilters()
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)

                if viewModel.filteredPrograms.isEmpty {
                    emptyState
                } else {
                    // Grid layout for tiles
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(viewModel.filteredPrograms) { program in
                            ProgramCardView(
                                program: program,
                                isFavorite: viewModel.isFavorite(program.id),
                                onTap: {
                                    selectedProgram = program
                                },
                                onFavoriteToggle: {
                                    viewModel.toggleFavorite(program.id)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private var searchBar: some View {
        @Bindable var viewModel = viewModel

        return HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search programs...", text: $viewModel.filterState.searchQuery)
                .textFieldStyle(.plain)

            if !viewModel.filterState.searchQuery.isEmpty {
                Button {
                    viewModel.filterState.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No programs found")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if viewModel.filterState.hasFilters {
                Button("Clear Filters") {
                    viewModel.clearFilters()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Failed to load programs")
                .font(.title3)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    HomeView()
        .environment(ProgramsViewModel())
        .environment(SettingsViewModel())
}
