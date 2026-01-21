import SwiftUI
import BayNavigatorCore

struct DirectoryView: View {
    @Environment(ProgramsViewModel.self) private var programsVM
    @Environment(SettingsViewModel.self) private var settingsVM

    @State private var searchText = ""
    @State private var showFilters = false
    @State private var showSort = false

    var body: some View {
        NavigationStack {
            Group {
                if programsVM.isLoading && programsVM.programs.isEmpty {
                    loadingView
                } else if let error = programsVM.error, programsVM.programs.isEmpty {
                    errorView(error)
                } else {
                    programsList
                }
            }
            .navigationTitle("Directory")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search programs...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterButton
                }
            }
            #elseif os(macOS)
            .searchable(text: $searchText, placement: .toolbar, prompt: "Search programs...")
            .toolbar {
                ToolbarItem {
                    filterButton
                }
            }
            #elseif os(visionOS)
            .searchable(text: $searchText, prompt: "Search programs...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterButton
                }
            }
            #endif
            .refreshable {
                await programsVM.loadData(forceRefresh: true)
            }
            .onChange(of: searchText) { _, newValue in
                programsVM.setSearchQuery(newValue)
            }
            .sheet(isPresented: $showFilters) {
                FilterSheetView(filter: programsVM.filterState)
                    .environment(programsVM)
            }
            .confirmationDialog("Sort By", isPresented: $showSort) {
                ForEach(SortOption.allCases) { option in
                    Button(option.rawValue) {
                        programsVM.sortOption = option
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var filterButton: some View {
        Menu {
            Button {
                showFilters = true
            } label: {
                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
            }

            Divider()

            Menu("Sort By") {
                ForEach(SortOption.allCases) { option in
                    Button {
                        programsVM.sortOption = option
                    } label: {
                        if programsVM.sortOption == option {
                            Label(option.rawValue, systemImage: "checkmark")
                        } else {
                            Text(option.rawValue)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: programsVM.filterState.hasFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.appPrimary)
        }
    }

    private var programsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // AI Search message banner
                if let aiMessage = programsVM.aiSearchMessage {
                    aiMessageBanner(aiMessage)
                }

                // Active filters summary
                if programsVM.filterState.hasFilters {
                    activeFiltersBanner
                }

                // Results count
                resultsHeader

                // Programs
                ForEach(programsVM.filteredPrograms) { program in
                    NavigationLink(value: program) {
                        ProgramCard(program: program)
                    }
                    .buttonStyle(.plain)
                }

                // Empty state
                if programsVM.filteredPrograms.isEmpty {
                    noResultsView
                }
            }
            .padding()
        }
        .navigationDestination(for: Program.self) { program in
            ProgramDetailView(program: program)
        }
    }

    private func aiMessageBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.appAccent)

            VStack(alignment: .leading, spacing: 4) {
                Text("AI Assistant")
                    .font(.caption.bold())
                    .foregroundStyle(Color.appAccent)
                Text(message)
                    .font(.subheadline)
            }

            Spacer()

            Button {
                programsVM.clearAISearch()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        #if os(iOS)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        #else
        .background(Color.appAccent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        #endif
    }

    private var activeFiltersBanner: some View {
        HStack {
            Text("\(programsVM.filterState.filterCount) filters active")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Clear All") {
                programsVM.clearFilters()
            }
            .font(.subheadline)
            .foregroundStyle(Color.appPrimary)
        }
        .padding(.horizontal)
    }

    private var resultsHeader: some View {
        HStack {
            Text("\(programsVM.filteredPrograms.count) programs")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(programsVM.sortOption.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading programs...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(Color.appDanger)

            Text("Unable to Load Programs")
                .font(.headline)

            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await programsVM.loadData(forceRefresh: true)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.appPrimary)
        }
        .padding()
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Programs Found")
                .font(.headline)

            Text("Try adjusting your search or filters.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if programsVM.filterState.hasFilters {
                Button("Clear Filters") {
                    programsVM.clearFilters()
                }
                .buttonStyle(.bordered)
                .tint(.appPrimary)
            }
        }
        .padding(40)
    }
}

#Preview {
    DirectoryView()
        .environment(ProgramsViewModel())
        .environment(SettingsViewModel())
}
