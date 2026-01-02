import SwiftUI
import RealityKit

struct ProgramDetailView: View {
    let program: Program
    @Environment(ProgramsViewModel.self) private var viewModel
    @Environment(\.openURL) private var openURL

    private var categoryColor: Color {
        Color.categoryColor(for: program.category)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Header with category color
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        // Category icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [categoryColor, categoryColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                                .shadow(color: categoryColor.opacity(0.3), radius: 8, y: 4)

                            Image(systemName: categoryIcon)
                                .font(.system(size: 28))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            // Category badge
                            Text(program.category.uppercased())
                                .font(.caption)
                                .fontWeight(.semibold)
                                .tracking(0.5)
                                .foregroundStyle(categoryColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(categoryColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))

                            Text(program.name)
                                .font(.system(size: 28, weight: .bold))

                            // Location
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                Text(program.locationText)
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Favorite button
                        Button {
                            viewModel.toggleFavorite(program.id)
                        } label: {
                            Image(systemName: viewModel.isFavorite(program.id) ? "bookmark.fill" : "bookmark")
                                .font(.title2)
                                .foregroundStyle(viewModel.isFavorite(program.id) ? Color.appDanger : .secondary)
                                .padding(12)
                                .background(.regularMaterial, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    // Description
                    Text(program.displayDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))

                Spacer().frame(height: 20)

                // What They Offer Section
                if !program.offerItems.isEmpty {
                    InfoCard(title: "What They Offer", icon: "gift.fill") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(program.offerItems, id: \.self) { item in
                                HStack(alignment: .top, spacing: 12) {
                                    Circle()
                                        .fill(Color.appPrimary)
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 6)

                                    Text(item)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                    }

                    Spacer().frame(height: 16)
                }

                // How to Get It Section
                if !program.howToSteps.isEmpty {
                    InfoCard(title: "How to Get It", icon: "checklist") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(program.howToSteps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.appPrimary)
                                        .frame(width: 24, height: 24)
                                        .background(Color.appPrimary.opacity(0.15), in: Circle())

                                    Text(step)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                    }

                    Spacer().frame(height: 16)
                }

                // Info Cards Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    // Groups Card (formerly Eligibility)
                    if !program.groups.isEmpty {
                        InfoCard(title: "Who It's For", icon: "person.2.fill") {
                            FlowLayout(spacing: 6) {
                                ForEach(program.groups, id: \.self) { item in
                                    Text(formatGroup(item))
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.appPrimary.opacity(0.1), in: Capsule())
                                        .foregroundStyle(Color.appPrimary)
                                }
                            }
                        }
                    }

                    // Service Areas Card
                    if !program.areas.isEmpty {
                        InfoCard(title: "Service Areas", icon: "map.fill") {
                            FlowLayout(spacing: 6) {
                                ForEach(program.areas, id: \.self) { area in
                                    Text(area)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.secondary.opacity(0.15), in: Capsule())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    // Cost Card
                    if let cost = program.cost, !cost.isEmpty {
                        InfoCard(title: "Cost", icon: "dollarsign.circle.fill") {
                            Text(cost)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Requirements Card (legacy)
                    if let requirements = program.requirements, !requirements.isEmpty {
                        InfoCard(title: "Requirements", icon: "checkmark.shield.fill") {
                            Text(requirements)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(4)
                        }
                    }
                }

                // How to Apply Section (legacy, full width)
                if let howToApply = program.howToApply, !howToApply.isEmpty {
                    Spacer().frame(height: 16)

                    InfoCard(title: "How to Apply", icon: "doc.text.fill") {
                        Text(howToApply)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                    }
                }

                Spacer().frame(height: 20)

                // Contact Section
                if program.phone != nil || program.email != nil || program.address != nil || (program.website != nil && !program.website!.isEmpty) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contact")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 4)

                        VStack(spacing: 8) {
                            if let phone = program.phone, !phone.isEmpty {
                                ContactButton(icon: "phone.fill", title: "Call", subtitle: phone) {
                                    let cleanPhone = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
                                    if let url = URL(string: "tel:\(cleanPhone)") {
                                        openURL(url)
                                    }
                                }
                            }

                            if let email = program.email, !email.isEmpty {
                                ContactButton(icon: "envelope.fill", title: "Email", subtitle: email) {
                                    if let url = URL(string: "mailto:\(email)") {
                                        openURL(url)
                                    }
                                }
                            }

                            if let address = program.address, !address.isEmpty {
                                ContactButton(icon: "location.fill", title: "Directions", subtitle: address) {
                                    let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                                    if let url = URL(string: "https://maps.apple.com/?q=\(encoded)") {
                                        openURL(url)
                                    }
                                }
                            }

                            if let website = program.website, !website.isEmpty {
                                ContactButton(icon: "globe", title: "Website", subtitle: website) {
                                    if let url = URL(string: website) {
                                        openURL(url)
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer().frame(height: 24)

                // Action Buttons
                HStack(spacing: 12) {
                    // Directions button (if address)
                    if let address = program.address, !address.isEmpty {
                        Button {
                            let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                            if let url = URL(string: "https://maps.apple.com/?q=\(encoded)") {
                                openURL(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                Text("Directions")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.bordered)
                    }

                    // Website button
                    if let website = program.website, !website.isEmpty {
                        Button {
                            if let url = URL(string: website) {
                                openURL(url)
                            }
                        } label: {
                            HStack {
                                Text("Visit Website")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.up.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.appPrimary)
                    }
                }

                Spacer().frame(height: 16)

                // Last Updated
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption2)
                    Text("Updated \(program.formattedLastUpdated)")
                        .font(.caption)
                }
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                ShareLink(item: shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
        .ornament(attachmentAnchor: .scene(.trailing)) {
            QuickActionsOrnament(
                program: program,
                isFavorite: viewModel.isFavorite(program.id),
                onFavoriteToggle: { viewModel.toggleFavorite(program.id) },
                onWebsite: {
                    if let website = program.website, let url = URL(string: website) {
                        openURL(url)
                    }
                },
                onCall: {
                    if let phone = program.phone {
                        let cleanPhone = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
                        if let url = URL(string: "tel:\(cleanPhone)") {
                            openURL(url)
                        }
                    }
                }
            )
        }
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

    private func formatGroup(_ group: String) -> String {
        let map: [String: String] = [
            "low-income": "Income-Eligible",
            "seniors": "Seniors",
            "youth": "Youth",
            "college-students": "Students",
            "veterans": "Veterans",
            "families": "Families",
            "disability": "Disability",
            "lgbtq": "LGBT+",
            "first-responders": "First Responders",
            "teachers": "Teachers",
            "unemployed": "Job Seekers",
            "immigrants": "Immigrants",
            "unhoused": "Unhoused",
            "pregnant": "Pregnant Women",
            "caregivers": "Caregivers",
            "foster-youth": "Foster Youth",
            "reentry": "Formerly Incarcerated",
            "nonprofits": "Nonprofits",
            "everyone": "Everyone"
        ]
        return map[group.lowercased()] ?? group
    }

    private var shareText: String {
        """
        \(program.name)

        \(program.displayDescription)

        Learn more: \(program.website ?? "")

        Shared from Bay Navigator
        """
    }
}

// Modern info card for detail sections
struct InfoCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(Color.appPrimary)
                    .font(.subheadline)

                Text(title.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .tracking(0.5)
                    .foregroundStyle(.secondary)
            }

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// Quick Actions Ornament for spatial UI
struct QuickActionsOrnament: View {
    let program: Program
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    let onWebsite: () -> Void
    let onCall: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Favorite button
            OrnamentButton(
                icon: isFavorite ? "bookmark.fill" : "bookmark",
                label: isFavorite ? "Saved" : "Save",
                color: isFavorite ? .red : .secondary,
                action: onFavoriteToggle
            )

            // Website button
            if program.website != nil && !program.website!.isEmpty {
                OrnamentButton(
                    icon: "globe",
                    label: "Website",
                    color: .blue,
                    action: onWebsite
                )
            }

            // Call button
            if program.phone != nil && !program.phone!.isEmpty {
                OrnamentButton(
                    icon: "phone.fill",
                    label: "Call",
                    color: .green,
                    action: onCall
                )
            }
        }
        .padding(12)
        .glassBackgroundEffect()
    }
}

struct OrnamentButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15), in: Circle())

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
    }
}

// Modern contact button
struct ContactButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.appPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.appPrimary.opacity(0.1), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
    }
}

#Preview(windowStyle: .automatic) {
    NavigationStack {
        ProgramDetailView(
            program: Program(
                id: "1",
                name: "CalFresh Food Benefits",
                category: "Food",
                description: "CalFresh helps low-income households buy nutritious food.",
                fullDescription: "CalFresh, known federally as SNAP, helps low-income households buy nutritious food. Benefits are provided on an EBT card that works like a debit card.",
                whatTheyOffer: "- Monthly food benefits on EBT card\n- Works at most grocery stores\n- Can buy fruits, vegetables, meat, dairy\n- Restaurant Meals Program for seniors",
                howToGetIt: "1. Check eligibility at GetCalFresh.org\n2. Gather income documents\n3. Submit application online\n4. Complete phone interview\n5. Receive EBT card in mail",
                groups: ["low-income", "seniors", "families"],
                areas: ["Alameda County", "Bay Area", "Statewide"],
                city: nil,
                website: "https://example.com",
                cost: "Free",
                phone: "1-800-555-1234",
                email: "help@example.com",
                address: "123 Main St, Oakland, CA 94612",
                requirements: "Must meet income requirements based on household size",
                howToApply: nil,
                lastUpdated: "2024-01-15"
            )
        )
    }
    .environment(ProgramsViewModel())
}
