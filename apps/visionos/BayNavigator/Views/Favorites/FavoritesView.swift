import SwiftUI

struct FavoritesView: View {
    @Environment(ProgramsViewModel.self) private var viewModel
    @State private var selectedProgram: Program?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.favoritePrograms.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.favoritePrograms) { program in
                                ProgramCardView(
                                    program: program,
                                    isFavorite: true,
                                    onTap: {
                                        selectedProgram = program
                                    },
                                    onFavoriteToggle: {
                                        viewModel.toggleFavorite(program.id)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationDestination(item: $selectedProgram) { program in
                ProgramDetailView(program: program)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No favorites yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Tap the heart icon on any program to save it here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    FavoritesView()
        .environment(ProgramsViewModel())
}
