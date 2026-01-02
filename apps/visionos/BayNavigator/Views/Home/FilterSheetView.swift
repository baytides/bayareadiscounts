import SwiftUI

struct FilterSheetView: View {
    @Environment(ProgramsViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Categories section
                    FilterSection(
                        title: "Categories",
                        icon: "square.grid.2x2",
                        selectedCount: viewModel.filterState.categories.count
                    ) {
                        FlowLayout(spacing: 8) {
                            ForEach(viewModel.categories) { category in
                                FilterChipView(
                                    title: category.name,
                                    count: viewModel.getCategoryCount(category.id),
                                    isSelected: viewModel.filterState.categories.contains(category.id)
                                ) {
                                    viewModel.toggleCategory(category.id)
                                }
                            }
                        }
                    }

                    // Groups section (formerly Eligibility)
                    FilterSection(
                        title: "Show programs for...",
                        icon: "person.2",
                        selectedCount: viewModel.filterState.groups.count
                    ) {
                        FlowLayout(spacing: 8) {
                            ForEach(viewModel.groups) { group in
                                FilterChipView(
                                    title: group.name,
                                    count: viewModel.getGroupCount(group.id),
                                    isSelected: viewModel.filterState.groups.contains(group.id)
                                ) {
                                    viewModel.toggleGroup(group.id)
                                }
                            }
                        }
                    }

                    // Service Areas section
                    FilterSection(
                        title: "Service Areas",
                        icon: "location",
                        selectedCount: viewModel.filterState.selectedAreaDisplayCount
                    ) {
                        FlowLayout(spacing: 8) {
                            // County areas
                            ForEach(viewModel.countyAreas) { area in
                                FilterChipView(
                                    title: area.name,
                                    count: viewModel.getAreaCount(area.id),
                                    isSelected: viewModel.filterState.areas.contains(area.id)
                                ) {
                                    viewModel.toggleArea(area.id)
                                }
                            }

                            // "Other" option (Bay Area, Statewide, Nationwide)
                            FilterChipView(
                                title: "Other",
                                count: viewModel.getOtherAreasCount(),
                                isSelected: viewModel.filterState.hasOtherAreasSelected
                            ) {
                                viewModel.toggleOtherAreas()
                            }
                        }
                    }

                    // Results count
                    HStack {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(Color.appPrimary)

                        Text("\(viewModel.filteredPrograms.count) programs match")
                            .fontWeight(.medium)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if viewModel.filterState.hasFilters {
                        Button("Clear All") {
                            viewModel.clearFilters()
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
}

struct FilterSection<Content: View>: View {
    let title: String
    let icon: String
    let selectedCount: Int
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Color.appPrimary)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                if selectedCount > 0 {
                    Text("\(selectedCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.appPrimary, in: Capsule())
                }
            }

            content()
        }
    }
}

struct FilterChipView: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)

                Text("(\(count))")
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(isSelected ? Color.appPrimary : Color.clear)
                    .background {
                        if !isSelected {
                            Capsule()
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        }
                    }
            }
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// Flow layout for wrapping chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))

            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalWidth = max(totalWidth, currentX - spacing)
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}

#Preview(windowStyle: .automatic) {
    FilterSheetView()
        .environment(ProgramsViewModel())
}
