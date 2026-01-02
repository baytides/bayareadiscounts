import SwiftUI

struct ForYouView: View {
    @Environment(ProgramsViewModel.self) private var programsViewModel
    @Environment(UserPrefsViewModel.self) private var userPrefsViewModel
    @State private var selectedProgram: Program?

    private var personalizedPrograms: [Program] {
        var programs = programsViewModel.programs

        // Filter by user's selected groups
        if !userPrefsViewModel.selectedGroups.isEmpty {
            programs = programs.filter { program in
                userPrefsViewModel.selectedGroups.contains { program.groups.contains($0) }
            }
        }

        // Filter by user's county
        if let countyId = userPrefsViewModel.selectedCounty,
           let county = programsViewModel.areas.first(where: { $0.id == countyId }) {
            programs = programs.filter { program in
                program.areas.contains(county.name) ||
                program.areas.contains("Bay Area") ||
                program.areas.contains("Statewide") ||
                program.areas.contains("Nationwide")
            }
        }

        // Sort by recently verified
        return programs.sorted { ($0.lastUpdatedDate ?? .distantPast) > ($1.lastUpdatedDate ?? .distantPast) }
    }

    private var recommendedPrograms: [Program] {
        Array(personalizedPrograms.prefix(5))
    }

    var body: some View {
        NavigationStack {
            Group {
                if programsViewModel.isLoading && programsViewModel.programs.isEmpty {
                    ProgressView("Loading programs...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !userPrefsViewModel.hasPreferences {
                    noPreferencesView
                } else {
                    personalizedContent
                }
            }
            .navigationTitle("For You")
            .navigationDestination(item: $selectedProgram) { program in
                ProgramDetailView(program: program)
            }
            .refreshable {
                await programsViewModel.loadData(forceRefresh: true)
            }
        }
    }

    // MARK: - No Preferences View

    private var noPreferencesView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.accent)

            Text("Set up your profile")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tell us about yourself to see personalized recommendations.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                userPrefsViewModel.reopenOnboarding()
            } label: {
                Label("Set up profile", systemImage: "pencil")
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
    }

    // MARK: - Personalized Content

    private var personalizedContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                // Preferences summary
                preferencesSummary
                    .padding(.horizontal)

                // Top Picks section
                if !recommendedPrograms.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("Top Picks for You")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(recommendedPrograms) { program in
                                    ProgramCardView(
                                        program: program,
                                        isFavorite: programsViewModel.isFavorite(program.id),
                                        onTap: { selectedProgram = program },
                                        onFavoriteToggle: { programsViewModel.toggleFavorite(program.id) }
                                    )
                                    .frame(width: 320)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // All Matching Programs section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("All Matching Programs")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("\(personalizedPrograms.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.accent.opacity(0.2), in: Capsule())
                            .foregroundStyle(.accent)
                    }
                    .padding(.horizontal)

                    if personalizedPrograms.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 320, maximum: 400), spacing: 16)], spacing: 16) {
                            ForEach(personalizedPrograms) { program in
                                ProgramCardView(
                                    program: program,
                                    isFavorite: programsViewModel.isFavorite(program.id),
                                    onTap: { selectedProgram = program },
                                    onFavoriteToggle: { programsViewModel.toggleFavorite(program.id) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Preferences Summary

    private var preferencesSummary: some View {
        let groupNames = userPrefsViewModel.getGroupNames(from: programsViewModel.groups)
        let countyName = userPrefsViewModel.getCountyName(from: programsViewModel.areas)

        return HStack {
            Image(systemName: "person.fill")
                .foregroundStyle(.accent)

            Group {
                Text("Showing programs for ")
                + Text(groupNames.isEmpty ? "" : groupNames.joined(separator: ", "))
                    .fontWeight(.semibold)
                + Text(groupNames.isEmpty || countyName == nil ? "" : " in ")
                + Text(countyName ?? "")
                    .fontWeight(.semibold)
            }
            .lineLimit(2)

            Spacer()

            Button {
                userPrefsViewModel.reopenOnboarding()
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No matching programs")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Try updating your profile preferences")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Update Profile") {
                userPrefsViewModel.reopenOnboarding()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview(windowStyle: .automatic) {
    ForYouView()
        .environment(ProgramsViewModel())
        .environment(UserPrefsViewModel())
}
