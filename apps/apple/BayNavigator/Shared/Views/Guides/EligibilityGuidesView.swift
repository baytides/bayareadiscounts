import SwiftUI

// MARK: - Models

/// Eligibility guide category
enum EligibilityGuideCategory: String, CaseIterable, Identifiable {
    case food = "Food Assistance"
    case healthcare = "Healthcare"
    case housing = "Housing Help"
    case utilities = "Utility Assistance"
    case cash = "Cash Benefits"
    case disability = "Disability Services"
    case seniors = "Senior Programs"
    case students = "Student Aid"
    case veterans = "Military & Veterans"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .healthcare: return "heart.fill"
        case .housing: return "house.fill"
        case .utilities: return "bolt.fill"
        case .cash: return "dollarsign.circle"
        case .disability: return "figure.roll"
        case .seniors: return "person.crop.circle"
        case .students: return "graduationcap.fill"
        case .veterans: return "shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .food: return .green
        case .healthcare: return .red
        case .housing: return .blue
        case .utilities: return .yellow
        case .cash: return .green
        case .disability: return .purple
        case .seniors: return .orange
        case .students: return .blue
        case .veterans: return Color(red: 0.0, green: 0.13, blue: 0.4) // Navy
        }
    }

    var guideId: String {
        switch self {
        case .food: return "food-assistance"
        case .healthcare: return "healthcare"
        case .housing: return "housing-assistance"
        case .utilities: return "utility-programs"
        case .cash: return "cash-assistance"
        case .disability: return "disability"
        case .seniors: return "seniors"
        case .students: return "students"
        case .veterans: return "military-veterans"
        }
    }
}

/// Eligibility guide with metadata
struct EligibilityGuide: Identifiable, Hashable {
    let id: String
    let category: EligibilityGuideCategory
    let description: String

    var title: String { category.rawValue }
    var icon: String { category.icon }
    var color: Color { category.color }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: EligibilityGuide, rhs: EligibilityGuide) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Guides Data

extension EligibilityGuide {
    static let allGuides: [EligibilityGuide] = [
        EligibilityGuide(
            id: "food",
            category: .food,
            description: "CalFresh (SNAP), WIC, food banks, and meal programs"
        ),
        EligibilityGuide(
            id: "healthcare",
            category: .healthcare,
            description: "Medi-Cal, Medicare, Covered California, and free clinics"
        ),
        EligibilityGuide(
            id: "housing",
            category: .housing,
            description: "Section 8, rental assistance, and homeless services"
        ),
        EligibilityGuide(
            id: "utilities",
            category: .utilities,
            description: "CARE, LIHEAP, Lifeline phone, and internet discounts"
        ),
        EligibilityGuide(
            id: "cash",
            category: .cash,
            description: "CalWORKs, SSI/SSDI, and General Assistance"
        ),
        EligibilityGuide(
            id: "disability",
            category: .disability,
            description: "SSI, SSDI, IHSS, and disability-specific services"
        ),
        EligibilityGuide(
            id: "seniors",
            category: .seniors,
            description: "Programs for adults 60 and older"
        ),
        EligibilityGuide(
            id: "students",
            category: .students,
            description: "Financial aid, student discounts, and educational support"
        ),
        EligibilityGuide(
            id: "veterans",
            category: .veterans,
            description: "VA benefits, veteran services, and military family support"
        ),
    ]
}

// MARK: - View Layout Mode

enum GuideLayoutMode: String, CaseIterable {
    case grid = "Grid"
    case list = "List"

    var icon: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        }
    }
}

// MARK: - Eligibility Guides View

struct EligibilityGuidesView: View {
    @State private var searchText = ""
    @State private var layoutMode: GuideLayoutMode = .grid
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var filteredGuides: [EligibilityGuide] {
        guard !searchText.isEmpty else {
            return EligibilityGuide.allGuides
        }

        let query = searchText.lowercased()
        return EligibilityGuide.allGuides.filter {
            $0.title.lowercased().contains(query) ||
            $0.description.lowercased().contains(query)
        }
    }

    /// Determine number of columns based on horizontal size class
    private var gridColumns: [GridItem] {
        #if os(iOS)
        if horizontalSizeClass == .regular {
            // iPad: 3 columns
            return Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
        } else {
            // iPhone: 2 columns
            return Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
        }
        #elseif os(macOS) || os(visionOS)
        // macOS/visionOS: 3+ columns based on window size
        return Array(repeating: GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16), count: 3)
        #else
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
        #endif
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Info banner
                infoBanner
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Results count and layout toggle
                resultsHeader
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                // Guides content
                if filteredGuides.isEmpty {
                    emptyState
                } else {
                    guidesContent
                }
            }
            .navigationTitle("Eligibility Guides")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .searchable(text: $searchText, prompt: "Search guides...")
            .navigationDestination(for: EligibilityGuide.self) { guide in
                GuideViewerView(
                    title: guide.title,
                    guideId: guide.category.guideId,
                    accentColor: guide.color
                )
            }
        }
    }

    // MARK: - Info Banner

    private var infoBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color.appInfo)
                .font(.title3)

            Text("These guides explain eligibility requirements, how to apply, and what documents you need.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        #if os(iOS)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        #else
        .background(Color.appInfo.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        #endif
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appInfo.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Results Header

    private var resultsHeader: some View {
        HStack {
            Text("\(filteredGuides.count) guides")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            // Layout toggle
            Picker("Layout", selection: $layoutMode) {
                ForEach(GuideLayoutMode.allCases, id: \.self) { mode in
                    Image(systemName: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 100)
        }
    }

    // MARK: - Guides Content

    @ViewBuilder
    private var guidesContent: some View {
        ScrollView {
            Group {
                switch layoutMode {
                case .grid:
                    gridView
                case .list:
                    listView
                }
            }
            .padding()
        }
    }

    // MARK: - Grid View

    private var gridView: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(filteredGuides) { guide in
                NavigationLink(value: guide) {
                    GuideGridCard(guide: guide)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - List View

    private var listView: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredGuides) { guide in
                NavigationLink(value: guide) {
                    GuideListCard(guide: guide)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No guides found")
                .font(.title2.bold())

            Text("Try a different search term")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

// MARK: - Guide Grid Card

private struct GuideGridCard: View {
    let guide: EligibilityGuide
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(guide.color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: guide.icon)
                    .font(.title2)
                    .foregroundStyle(guide.color)
            }

            // Title
            Text(guide.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Description
            Text(guide.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            // Chevron indicator
            HStack {
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 160)
        #if os(iOS)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        #else
        .background(
            colorScheme == .dark ? Color.darkCard : Color.lightCard,
            in: RoundedRectangle(cornerRadius: 16)
        )
        #endif
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(guide.color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Guide List Card

private struct GuideListCard: View {
    let guide: EligibilityGuide
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(guide.color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: guide.icon)
                    .font(.title2)
                    .foregroundStyle(guide.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(guide.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(guide.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        #if os(iOS)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        #else
        .background(
            colorScheme == .dark ? Color.darkCard : Color.lightCard,
            in: RoundedRectangle(cornerRadius: 12)
        )
        #endif
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview("Eligibility Guides") {
    EligibilityGuidesView()
}
