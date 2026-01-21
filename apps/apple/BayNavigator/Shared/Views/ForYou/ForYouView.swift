import SwiftUI
import BayNavigatorCore

struct ForYouView: View {
    @Environment(ProgramsViewModel.self) private var programsVM
    @Environment(UserPrefsViewModel.self) private var userPrefsVM

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // User profile summary card
                    if userPrefsVM.hasPreferences {
                        profileCard
                    }

                    // Top picks section
                    if !topPicks.isEmpty {
                        topPicksSection
                    }

                    // All matching programs
                    if !matchingPrograms.isEmpty {
                        allMatchingSection
                    }

                    // Empty state
                    if !userPrefsVM.hasPreferences {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationTitle("For You")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .refreshable {
                await programsVM.loadData(forceRefresh: true)
            }
        }
    }

    // MARK: - Computed Properties

    private var matchingPrograms: [Program] {
        var result = programsVM.programs

        // Filter by user's selected groups
        if !userPrefsVM.selectedGroups.isEmpty {
            result = result.filter { program in
                userPrefsVM.selectedGroups.contains { program.groups.contains($0) }
            }
        }

        // Filter by user's county
        if let county = userPrefsVM.selectedCounty,
           let countyName = userPrefsVM.getCountyName(from: programsVM.areas) {
            result = result.filter { program in
                program.areas.contains(countyName) ||
                program.areas.contains("Bay Area") ||
                program.areas.contains("Statewide") ||
                program.areas.contains("Nationwide")
            }
        }

        return result
    }

    private var topPicks: [Program] {
        Array(matchingPrograms.prefix(5))
    }

    // MARK: - Views

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.appPrimary)

                Text("Your Profile")
                    .font(.headline)

                Spacer()

                Button("Edit") {
                    userPrefsVM.reopenOnboarding()
                }
                .buttonStyle(.bordered)
                .tint(.appPrimary)
            }

            if !userPrefsVM.selectedGroups.isEmpty {
                let groupNames = userPrefsVM.getGroupNames(from: programsVM.groups)
                Text("Groups: \(groupNames.joined(separator: ", "))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let countyName = userPrefsVM.getCountyName(from: programsVM.areas) {
                Text("Location: \(countyName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        #if os(iOS)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        #else
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        #endif
    }

    private var topPicksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.appAccent)
                Text("Top Picks for You")
                    .font(.title2.bold())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(topPicks) { program in
                        NavigationLink(value: program) {
                            TopPickCard(program: program)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationDestination(for: Program.self) { program in
            ProgramDetailView(program: program)
        }
    }

    private var allMatchingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Matching Programs")
                .font(.title2.bold())

            LazyVStack(spacing: 12) {
                ForEach(matchingPrograms) { program in
                    NavigationLink(value: program) {
                        ProgramCard(program: program)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Set Up Your Profile")
                .font(.title2.bold())

            Text("Tell us about yourself to get personalized program recommendations.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Get Started") {
                userPrefsVM.reopenOnboarding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.appPrimary)
        }
        .padding(40)
    }
}

// MARK: - Top Pick Card

struct TopPickCard: View {
    let program: Program
    @Environment(ProgramsViewModel.self) private var programsVM

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category icon
            Circle()
                .fill(Color.categoryColor(for: program.category).gradient)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: categoryIcon(for: program.category))
                        .font(.title3)
                        .foregroundStyle(.white)
                }

            Text(program.name)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text(program.category)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Color.appPrimary)
                Text(program.locationText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 160, height: 180)
        .padding()
        #if os(iOS)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        #else
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        #endif
        #if os(visionOS)
        .hoverEffect(.highlight)
        #endif
    }

    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "food", "food assistance": return "fork.knife"
        case "health", "healthcare": return "heart.fill"
        case "housing": return "house.fill"
        case "transportation": return "bus.fill"
        case "education": return "graduationcap.fill"
        case "employment": return "briefcase.fill"
        case "utilities": return "bolt.fill"
        case "legal": return "building.columns.fill"
        default: return "star.fill"
        }
    }
}

#Preview {
    ForYouView()
        .environment(ProgramsViewModel())
        .environment(UserPrefsViewModel())
}
