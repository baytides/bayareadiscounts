import SwiftUI

struct MessageContentView: View {
    let isExpanded: Bool
    let onSendProgram: (SharedProgram) -> Void
    let onRequestExpand: () -> Void

    @StateObject private var dataManager = SharedDataManager()
    @State private var searchText = ""

    var body: some View {
        if isExpanded {
            expandedView
        } else {
            compactView
        }
    }

    // MARK: - Compact View (shown in iMessage app drawer)

    private var compactView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundStyle(.teal)
                Text("Bay Navigator")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)

            if dataManager.savedPrograms.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bookmark")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No saved programs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Save programs in the app to share them here")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(dataManager.savedPrograms.prefix(5)) { program in
                            CompactProgramCard(program: program) {
                                onSendProgram(program)
                            }
                        }

                        // Show "See All" button if there are more than 5 saved programs
                        if dataManager.savedPrograms.count > 5 {
                            Button {
                                onRequestExpand()
                            } label: {
                                VStack {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.title2)
                                    Text("See All")
                                        .font(.caption)
                                }
                                .foregroundStyle(.teal)
                                .frame(width: 80, height: 100)
                                .background(Color.teal.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            dataManager.loadSavedPrograms()
        }
    }

    // MARK: - Expanded View (full screen in iMessage)

    private var expandedView: some View {
        NavigationView {
            VStack(spacing: 0) {
                if dataManager.savedPrograms.isEmpty {
                    emptyStateView
                } else {
                    // Search bar (only show if there are programs)
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search saved programs...", text: $searchText)
                            .textFieldStyle(.plain)
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding()

                    if filteredPrograms.isEmpty {
                        noSearchResultsView
                    } else {
                        programsList
                    }
                }
            }
            .navigationTitle("Share a Program")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            dataManager.loadSavedPrograms()
        }
    }

    private var filteredPrograms: [SharedProgram] {
        if searchText.isEmpty {
            return dataManager.savedPrograms
        }
        return dataManager.savedPrograms.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Saved Programs")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Save programs in the Bay Navigator app to share them with friends and family.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noSearchResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Results")
                .font(.title3)
                .fontWeight(.semibold)

            Text("No saved programs match \"\(searchText)\"")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Clear Search") {
                searchText = ""
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var programsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredPrograms) { program in
                    ExpandedProgramCard(program: program) {
                        onSendProgram(program)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Compact Program Card

struct CompactProgramCard: View {
    let program: SharedProgram
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Text(categoryEmoji)
                        .font(.system(size: 16))
                }

                Text(program.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)

                Text(program.category)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 100, height: 100)
            .padding(8)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var categoryColor: Color {
        switch program.category.lowercased() {
        case "food", "food assistance": return .orange
        case "health", "healthcare": return .red
        case "recreation", "activities": return .purple
        case "community", "community services": return .green
        case "education": return .blue
        case "transportation": return .cyan
        default: return .teal
        }
    }

    private var categoryEmoji: String {
        switch program.category.lowercased() {
        case "food", "food assistance": return "🍽️"
        case "health", "healthcare": return "❤️"
        case "recreation", "activities": return "🎫"
        case "community", "community services": return "👥"
        case "education": return "🎓"
        case "transportation": return "🚗"
        case "housing": return "🏠"
        case "financial assistance": return "💰"
        default: return "✨"
        }
    }
}

// MARK: - Expanded Program Card

struct ExpandedProgramCard: View {
    let program: SharedProgram
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                Text(categoryEmoji)
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(program.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(program.category)
                    .font(.caption)
                    .foregroundStyle(categoryColor)
                    .fontWeight(.medium)

                Text(program.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.teal)
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }

    private var categoryColor: Color {
        switch program.category.lowercased() {
        case "food", "food assistance": return .orange
        case "health", "healthcare": return .red
        case "recreation", "activities": return .purple
        case "community", "community services": return .green
        case "education": return .blue
        case "transportation": return .cyan
        default: return .teal
        }
    }

    private var categoryEmoji: String {
        switch program.category.lowercased() {
        case "food", "food assistance": return "🍽️"
        case "health", "healthcare": return "❤️"
        case "recreation", "activities": return "🎫"
        case "community", "community services": return "👥"
        case "education": return "🎓"
        case "transportation": return "🚗"
        case "housing": return "🏠"
        case "financial assistance": return "💰"
        default: return "✨"
        }
    }
}

#Preview {
    MessageContentView(
        isExpanded: true,
        onSendProgram: { _ in },
        onRequestExpand: { }
    )
}
