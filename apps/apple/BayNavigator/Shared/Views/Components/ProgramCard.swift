import SwiftUI
import BayNavigatorCore

struct ProgramCard: View {
    let program: Program
    @Environment(ProgramsViewModel.self) private var programsVM

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Category icon
            Circle()
                .fill(Color.categoryColor(for: program.category).gradient)
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: categoryIcon)
                        .font(.title3)
                        .foregroundStyle(.white)
                }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(program.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                // Location
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                    Text(program.locationText)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)

                // Description
                Text(program.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Tags
                HStack(spacing: 8) {
                    // Category tag
                    Text(program.category)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.categoryColor(for: program.category).opacity(0.15))
                        .foregroundStyle(Color.categoryColor(for: program.category))
                        .clipShape(Capsule())

                    // Distance if available
                    if let distance = program.distanceFromUser {
                        Text(LocationService.formatDistance(distance))
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.appInfo.opacity(0.15))
                            .foregroundStyle(Color.appInfo)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            // Favorite button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    programsVM.toggleFavorite(program.id)
                }
            } label: {
                Image(systemName: programsVM.isFavorite(program.id) ? "bookmark.fill" : "bookmark")
                    .font(.title3)
                    .foregroundStyle(programsVM.isFavorite(program.id) ? Color.appAccent : Color.secondary)
                    .symbolEffect(.bounce, value: programsVM.isFavorite(program.id))
            }
            .buttonStyle(.plain)
        }
        .padding()
        #if os(iOS)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        #else
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        #endif
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        #if os(visionOS)
        .hoverEffect(.highlight)
        #endif
    }

    private var categoryIcon: String {
        switch program.category.lowercased() {
        case "food", "food assistance": return "fork.knife"
        case "health", "healthcare": return "heart.fill"
        case "housing", "shelter": return "house.fill"
        case "transportation", "transit": return "bus.fill"
        case "education", "learning": return "graduationcap.fill"
        case "employment", "jobs": return "briefcase.fill"
        case "utilities", "utility programs": return "bolt.fill"
        case "legal", "legal aid": return "building.columns.fill"
        case "technology", "tech": return "wifi"
        case "recreation": return "figure.run"
        case "community", "community services": return "person.3.fill"
        case "finance", "financial assistance": return "dollarsign.circle.fill"
        case "childcare": return "figure.2.and.child.holdinghands"
        default: return "star.fill"
        }
    }
}

#Preview {
    VStack {
        ProgramCard(program: Program(
            id: "test",
            name: "CalFresh Food Assistance",
            category: "Food",
            description: "Monthly food benefits for low-income individuals and families.",
            groups: ["low-income", "families"],
            areas: ["Bay Area"],
            city: "San Francisco",
            website: "https://example.com",
            cost: "Free",
            phone: "(555) 123-4567",
            lastUpdated: "2024-01-15",
            latitude: 37.7749,
            longitude: -122.4194
        ))
    }
    .padding()
    .environment(ProgramsViewModel())
}
