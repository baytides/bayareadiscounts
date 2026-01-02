import SwiftUI
import RealityKit

struct ProgramCardView: View {
    let program: Program
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavoriteToggle: () -> Void

    @State private var isHovered = false

    private var categoryColor: Color {
        Color.categoryColor(for: program.category)
    }

    private var categoryIcon: String {
        switch program.category.lowercased() {
        case "food", "food assistance":
            return "fork.knife"
        case "health", "healthcare", "medical":
            return "heart.text.square.fill"
        case "recreation", "activities", "entertainment":
            return "ticket.fill"
        case "community", "community services", "social services":
            return "person.3.fill"
        case "education", "learning", "training":
            return "graduationcap.fill"
        case "finance", "financial", "financial assistance":
            return "dollarsign.circle.fill"
        case "transportation", "transit":
            return "car.fill"
        case "technology", "tech", "internet":
            return "laptopcomputer"
        case "legal", "legal aid":
            return "scale.3d"
        case "housing", "shelter":
            return "house.fill"
        case "employment", "jobs", "career":
            return "briefcase.fill"
        case "pet resources", "pets":
            return "pawprint.fill"
        case "utilities", "energy":
            return "bolt.fill"
        case "childcare", "childcare assistance":
            return "figure.and.child.holdinghands"
        case "clothing", "clothing assistance":
            return "tshirt.fill"
        case "library resources", "library":
            return "books.vertical.fill"
        default:
            return "info.circle.fill"
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon, title, and favorite button
                HStack(alignment: .top, spacing: 12) {
                    // Category icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(categoryColor.opacity(0.12))
                            .frame(width: 40, height: 40)

                        Image(systemName: categoryIcon)
                            .font(.system(size: 18))
                            .foregroundStyle(categoryColor)
                    }

                    // Title and location
                    VStack(alignment: .leading, spacing: 4) {
                        Text(program.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Location
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                            Text(program.locationText)
                                .font(.caption)
                        }
                        .foregroundStyle(.tertiary)
                    }

                    // Favorite button
                    Button {
                        onFavoriteToggle()
                    } label: {
                        Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(isFavorite ? Color.appDanger : .secondary)
                            .font(.title3)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isFavorite ? Color.appDanger.opacity(0.1) : Color.secondary.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }

                // Description
                Text(program.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                // Tags and groups row
                HStack(spacing: 8) {
                    // Category tag with color
                    TagView(text: program.category, color: categoryColor)

                    // First area tag
                    if let firstArea = program.areas.first {
                        TagView(text: firstArea, style: .secondary)
                    }

                    Spacer()

                    // Groups badges (emoji icons)
                    ForEach(program.groups.prefix(3), id: \.self) { group in
                        GroupBadge(group: group)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
            }
            .hoverEffect(.highlight)
            .hoverEffect { effect, isActive, _ in
                effect.scaleEffect(isActive ? 1.02 : 1.0)
            }
            .shadow(color: .black.opacity(0.1), radius: isHovered ? 20 : 10, y: isHovered ? 10 : 5)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
        }
        .buttonStyle(.plain)
    }
}

struct TagView: View {
    let text: String
    var style: TagStyle = .primary
    var color: Color? = nil

    enum TagStyle {
        case primary
        case secondary
    }

    var body: some View {
        let tagColor = color ?? (style == .primary ? Color.appPrimary : Color.secondary)

        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(tagColor.opacity(style == .primary ? 0.12 : 0.08))
            }
            .foregroundStyle(style == .primary ? tagColor : .secondary)
    }
}

struct GroupBadge: View {
    let group: String

    private var emoji: String {
        switch group.lowercased() {
        case "low-income": return "💵"
        case "seniors": return "👴"
        case "youth": return "🧒"
        case "college-students": return "🎓"
        case "veterans": return "🎖️"
        case "families": return "👨‍👩‍👧"
        case "disability": return "♿"
        case "lgbtq": return "🌈"
        case "first-responders": return "🚒"
        case "teachers": return "👩‍🏫"
        case "unemployed": return "💼"
        case "immigrants": return "🌍"
        case "unhoused": return "🏠"
        case "pregnant": return "🤰"
        case "caregivers": return "🤲"
        case "foster-youth": return "🏡"
        case "reentry": return "🔓"
        case "nonprofits": return "🏢"
        case "everyone": return "👥"
        default: return "👤"
        }
    }

    var body: some View {
        Text(emoji)
            .font(.system(size: 14))
            .frame(width: 28, height: 28)
            .background(Color.secondary.opacity(0.08), in: Circle())
    }
}

#Preview(windowStyle: .automatic) {
    VStack {
        ProgramCardView(
            program: Program(
                id: "1",
                name: "CalFresh Food Benefits",
                category: "Food",
                description: "CalFresh, known federally as SNAP, helps low-income households buy nutritious food. Benefits are provided on an EBT card that works like a debit card.",
                fullDescription: nil,
                whatTheyOffer: nil,
                howToGetIt: nil,
                groups: ["low-income", "seniors"],
                areas: ["Alameda County", "Bay Area"],
                city: nil,
                website: "https://example.com",
                cost: "Free",
                phone: "1-800-555-1234",
                email: "help@example.com",
                address: nil,
                requirements: "Must meet income requirements",
                howToApply: "Apply online or in person",
                lastUpdated: "2024-01-15"
            ),
            isFavorite: false,
            onTap: {},
            onFavoriteToggle: {}
        )

        ProgramCardView(
            program: Program(
                id: "2",
                name: "Medi-Cal Health Coverage",
                category: "Healthcare",
                description: "Free or low-cost health coverage for eligible California residents.",
                fullDescription: nil,
                whatTheyOffer: nil,
                howToGetIt: nil,
                groups: ["low-income", "families"],
                areas: ["Statewide"],
                city: nil,
                website: "https://example.com",
                cost: nil,
                phone: nil,
                email: nil,
                address: nil,
                requirements: nil,
                howToApply: nil,
                lastUpdated: "2024-02-20"
            ),
            isFavorite: true,
            onTap: {},
            onFavoriteToggle: {}
        )
    }
    .padding()
    .frame(width: 400)
}
