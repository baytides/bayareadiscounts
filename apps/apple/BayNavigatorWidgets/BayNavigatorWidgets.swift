import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Entry

struct ProgramEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let stats: WidgetStats
    let recentPrograms: [WidgetProgram]
}

struct WidgetStats {
    let totalPrograms: Int
    let favoriteCount: Int
    let lastUpdated: Date

    static let placeholder = WidgetStats(
        totalPrograms: 1250,
        favoriteCount: 5,
        lastUpdated: Date()
    )
}

struct WidgetProgram: Identifiable {
    let id: String
    let name: String
    let category: String
    let categoryIcon: String

    static let placeholders: [WidgetProgram] = [
        WidgetProgram(id: "1", name: "CalFresh Food Benefits", category: "Food", categoryIcon: "fork.knife"),
        WidgetProgram(id: "2", name: "Medi-Cal Healthcare", category: "Health", categoryIcon: "heart.fill"),
        WidgetProgram(id: "3", name: "Housing Assistance", category: "Housing", categoryIcon: "house.fill")
    ]
}

// MARK: - Configuration Intent

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Bay Navigator Widget"
    static var description = IntentDescription("Quick access to Bay Area social services")

    @Parameter(title: "Show Favorites", default: true)
    var showFavorites: Bool

    @Parameter(title: "Category Filter")
    var categoryFilter: CategoryFilter?
}

enum CategoryFilter: String, AppEnum {
    case all = "All"
    case food = "Food"
    case housing = "Housing"
    case health = "Health"
    case employment = "Employment"
    case education = "Education"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static var caseDisplayRepresentations: [CategoryFilter: DisplayRepresentation] = [
        .all: "All Categories",
        .food: "Food Assistance",
        .housing: "Housing",
        .health: "Healthcare",
        .employment: "Employment",
        .education: "Education"
    ]
}

// MARK: - Timeline Provider

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ProgramEntry {
        ProgramEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            stats: .placeholder,
            recentPrograms: WidgetProgram.placeholders
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> ProgramEntry {
        await fetchEntry(for: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<ProgramEntry> {
        let entry = await fetchEntry(for: configuration)

        // Refresh every 6 hours
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchEntry(for configuration: ConfigurationAppIntent) async -> ProgramEntry {
        // Load data from shared App Group container
        let stats = loadStats()
        let programs = loadRecentPrograms(filter: configuration.categoryFilter, showFavorites: configuration.showFavorites)

        return ProgramEntry(
            date: Date(),
            configuration: configuration,
            stats: stats,
            recentPrograms: programs
        )
    }

    private func loadStats() -> WidgetStats {
        let defaults = UserDefaults(suiteName: "group.org.baytides.navigator")
        return WidgetStats(
            totalPrograms: defaults?.integer(forKey: "totalPrograms") ?? 0,
            favoriteCount: defaults?.integer(forKey: "favoriteCount") ?? 0,
            lastUpdated: defaults?.object(forKey: "lastUpdated") as? Date ?? Date()
        )
    }

    private func loadRecentPrograms(filter: CategoryFilter?, showFavorites: Bool) -> [WidgetProgram] {
        let defaults = UserDefaults(suiteName: "group.org.baytides.navigator")

        guard let data = defaults?.data(forKey: showFavorites ? "favoritePrograms" : "recentPrograms"),
              let programs = try? JSONDecoder().decode([WidgetProgramData].self, from: data) else {
            return WidgetProgram.placeholders
        }

        var filtered = programs.map { data in
            WidgetProgram(
                id: data.id,
                name: data.name,
                category: data.category,
                categoryIcon: categoryIcon(for: data.category)
            )
        }

        if let filter = filter, filter != .all {
            filtered = filtered.filter { $0.category.lowercased() == filter.rawValue.lowercased() }
        }

        return Array(filtered.prefix(5))
    }

    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "food": return "fork.knife"
        case "housing": return "house.fill"
        case "health": return "heart.fill"
        case "employment": return "briefcase.fill"
        case "education": return "book.fill"
        case "legal": return "scale.3d"
        default: return "folder.fill"
        }
    }
}

struct WidgetProgramData: Codable {
    let id: String
    let name: String
    let category: String
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: ProgramEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                Spacer()
                Text("\(entry.stats.totalPrograms)")
                    .font(.title.bold())
                    .foregroundStyle(.primary)
            }

            Text("Programs")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
                Text("\(entry.stats.favoriteCount) saved")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: ProgramEntry

    var body: some View {
        HStack(spacing: 16) {
            // Stats section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)
                    Text("Bay Navigator")
                        .font(.headline)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Label("\(entry.stats.totalPrograms) programs", systemImage: "list.bullet")
                        .font(.caption)
                    Label("\(entry.stats.favoriteCount) favorites", systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.pink)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Recent programs
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.configuration.showFavorites ? "Favorites" : "Recent")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                ForEach(entry.recentPrograms.prefix(3)) { program in
                    Link(destination: URL(string: "baynavigator://program/\(program.id)")!) {
                        HStack(spacing: 6) {
                            Image(systemName: program.categoryIcon)
                                .font(.caption)
                                .foregroundStyle(.tint)
                                .frame(width: 16)
                            Text(program.name)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let entry: ProgramEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.title)
                    .foregroundStyle(.tint)

                VStack(alignment: .leading) {
                    Text("Bay Navigator")
                        .font(.headline)
                    Text("\(entry.stats.totalPrograms) programs available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Link(destination: URL(string: "baynavigator://search")!) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)
                }
            }

            Divider()

            // Quick categories
            HStack(spacing: 12) {
                QuickCategoryButton(icon: "fork.knife", label: "Food", category: "food")
                QuickCategoryButton(icon: "house.fill", label: "Housing", category: "housing")
                QuickCategoryButton(icon: "heart.fill", label: "Health", category: "health")
                QuickCategoryButton(icon: "briefcase.fill", label: "Jobs", category: "employment")
            }

            Divider()

            // Programs list
            Text(entry.configuration.showFavorites ? "Your Favorites" : "Recent Programs")
                .font(.subheadline.bold())

            ForEach(entry.recentPrograms.prefix(5)) { program in
                Link(destination: URL(string: "baynavigator://program/\(program.id)")!) {
                    HStack {
                        Image(systemName: program.categoryIcon)
                            .foregroundStyle(.tint)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(program.name)
                                .font(.subheadline)
                                .lineLimit(1)
                            Text(program.category)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct QuickCategoryButton: View {
    let icon: String
    let label: String
    let category: String

    var body: some View {
        Link(destination: URL(string: "baynavigator://category/\(category)")!) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.fill.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Lock Screen Widget Views

struct LockScreenCircularView: View {
    let entry: ProgramEntry

    var body: some View {
        Gauge(value: Double(entry.stats.favoriteCount), in: 0...20) {
            Image(systemName: "building.2.fill")
        } currentValueLabel: {
            Text("\(entry.stats.favoriteCount)")
                .font(.system(.body, design: .rounded).bold())
        }
        .gaugeStyle(.accessoryCircular)
    }
}

struct LockScreenRectangularView: View {
    let entry: ProgramEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Bay Navigator")
                    .font(.headline)
                    .widgetAccentable()
                Text("\(entry.stats.totalPrograms) programs")
                    .font(.caption)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
                Text("\(entry.stats.favoriteCount)")
                    .font(.title3.bold())
            }
        }
    }
}

struct LockScreenInlineView: View {
    let entry: ProgramEntry

    var body: some View {
        Label("\(entry.stats.favoriteCount) favorites • \(entry.stats.totalPrograms) programs", systemImage: "building.2.fill")
    }
}

// MARK: - Main Widget

struct BayNavigatorWidget: Widget {
    let kind: String = "BayNavigatorWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            BayNavigatorWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Bay Navigator")
        .description("Quick access to Bay Area social services and your saved programs.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct BayNavigatorWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .accessoryCircular:
            LockScreenCircularView(entry: entry)
        case .accessoryRectangular:
            LockScreenRectangularView(entry: entry)
        case .accessoryInline:
            LockScreenInlineView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Favorites Widget

struct FavoritesEntry: TimelineEntry {
    let date: Date
    let favorites: [WidgetProgram]
}

struct FavoritesProvider: TimelineProvider {
    func placeholder(in context: Context) -> FavoritesEntry {
        FavoritesEntry(date: Date(), favorites: WidgetProgram.placeholders)
    }

    func getSnapshot(in context: Context, completion: @escaping (FavoritesEntry) -> Void) {
        let entry = FavoritesEntry(date: Date(), favorites: loadFavorites())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FavoritesEntry>) -> Void) {
        let entry = FavoritesEntry(date: Date(), favorites: loadFavorites())
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadFavorites() -> [WidgetProgram] {
        let defaults = UserDefaults(suiteName: "group.org.baytides.navigator")

        guard let data = defaults?.data(forKey: "favoritePrograms"),
              let programs = try? JSONDecoder().decode([WidgetProgramData].self, from: data) else {
            return WidgetProgram.placeholders
        }

        return programs.prefix(5).map { data in
            WidgetProgram(
                id: data.id,
                name: data.name,
                category: data.category,
                categoryIcon: categoryIcon(for: data.category)
            )
        }
    }

    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "food": return "fork.knife"
        case "housing": return "house.fill"
        case "health": return "heart.fill"
        case "employment": return "briefcase.fill"
        case "education": return "book.fill"
        default: return "folder.fill"
        }
    }
}

struct FavoritesWidgetView: View {
    let entry: FavoritesEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
                Text("Favorites")
                    .font(.headline)
            }

            if entry.favorites.isEmpty {
                Spacer()
                Text("No favorites yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(entry.favorites.prefix(family == .systemMedium ? 3 : 5)) { program in
                    Link(destination: URL(string: "baynavigator://program/\(program.id)")!) {
                        HStack(spacing: 8) {
                            Image(systemName: program.categoryIcon)
                                .foregroundStyle(.tint)
                                .frame(width: 20)
                            Text(program.name)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct FavoritesWidget: Widget {
    let kind: String = "FavoritesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FavoritesProvider()) { entry in
            FavoritesWidgetView(entry: entry)
        }
        .configurationDisplayName("Saved Programs")
        .description("Quick access to your favorite programs.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle

@main
struct BayNavigatorWidgetBundle: WidgetBundle {
    var body: some Widget {
        BayNavigatorWidget()
        FavoritesWidget()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    BayNavigatorWidget()
} timeline: {
    ProgramEntry(date: .now, configuration: ConfigurationAppIntent(), stats: .placeholder, recentPrograms: WidgetProgram.placeholders)
}

#Preview("Medium", as: .systemMedium) {
    BayNavigatorWidget()
} timeline: {
    ProgramEntry(date: .now, configuration: ConfigurationAppIntent(), stats: .placeholder, recentPrograms: WidgetProgram.placeholders)
}

#Preview("Large", as: .systemLarge) {
    BayNavigatorWidget()
} timeline: {
    ProgramEntry(date: .now, configuration: ConfigurationAppIntent(), stats: .placeholder, recentPrograms: WidgetProgram.placeholders)
}

#Preview("Lock Screen Circular", as: .accessoryCircular) {
    BayNavigatorWidget()
} timeline: {
    ProgramEntry(date: .now, configuration: ConfigurationAppIntent(), stats: .placeholder, recentPrograms: WidgetProgram.placeholders)
}

#Preview("Lock Screen Rectangular", as: .accessoryRectangular) {
    BayNavigatorWidget()
} timeline: {
    ProgramEntry(date: .now, configuration: ConfigurationAppIntent(), stats: .placeholder, recentPrograms: WidgetProgram.placeholders)
}
