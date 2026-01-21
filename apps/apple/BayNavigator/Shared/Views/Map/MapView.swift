import SwiftUI
import MapKit
import BayNavigatorCore

// MARK: - MapView

/// Interactive map view showing program locations with clustering, search, and list/map toggle.
/// Works on iOS 17+, macOS 14+, and visionOS 1+.
struct MapView: View {
    @Environment(ProgramsViewModel.self) private var programsVM
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State
    @State private var viewMode: ViewMode = .map
    @State private var searchText = ""
    @State private var selectedProgram: Program?
    @State private var showProgramDetail = false
    @State private var cameraPosition: MapCameraPosition = .region(Self.bayAreaRegion)
    @State private var selectedMapItem: ProgramMapItem?

    // Location service for user location
    @State private var locationService = LocationService()

    // MARK: - Constants
    private static let bayAreaCenter = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    private static let bayAreaRegion = MKCoordinateRegion(
        center: bayAreaCenter,
        span: MKCoordinateSpan(latitudeDelta: 0.8, longitudeDelta: 0.8)
    )

    // MARK: - Computed Properties

    private var programsWithLocation: [Program] {
        programsVM.filteredPrograms.filter { $0.hasCoordinates }
    }

    private var filteredMapPrograms: [Program] {
        if searchText.isEmpty {
            return programsWithLocation
        }
        let query = searchText.lowercased()
        return programsWithLocation.filter { program in
            program.name.lowercased().contains(query) ||
            program.description.lowercased().contains(query) ||
            program.category.lowercased().contains(query)
        }
    }

    private var mapItems: [ProgramMapItem] {
        filteredMapPrograms.map { ProgramMapItem(program: $0) }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                switch viewMode {
                case .map:
                    mapContent
                case .list:
                    listContent
                }
            }
            .navigationTitle("Map")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search on map...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    viewModeToggle
                }
                ToolbarItem(placement: .topBarTrailing) {
                    locationButton
                }
            }
            #elseif os(macOS)
            .searchable(text: $searchText, placement: .toolbar, prompt: "Search on map...")
            .toolbar {
                ToolbarItem {
                    viewModeToggle
                }
                ToolbarItem {
                    locationButton
                }
            }
            #elseif os(visionOS)
            .searchable(text: $searchText, prompt: "Search on map...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    viewModeToggle
                }
                ToolbarItem(placement: .topBarTrailing) {
                    locationButton
                }
            }
            #endif
            .sheet(item: $selectedProgram) { program in
                ProgramDetailView(program: program)
                    .environment(programsVM)
            }
        }
    }

    // MARK: - Map Content

    @ViewBuilder
    private var mapContent: some View {
        ZStack(alignment: .bottom) {
            mapView

            // Program count badge
            programCountBadge
                .padding(.bottom, 16)
                .padding(.leading, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var mapView: some View {
        Map(position: $cameraPosition, selection: $selectedMapItem) {
            // User location annotation
            #if !os(visionOS)
            UserAnnotation()
            #endif

            // Program annotations with clustering
            ForEach(mapItems) { item in
                Annotation(
                    item.program.name,
                    coordinate: item.coordinate,
                    anchor: .bottom
                ) {
                    ProgramAnnotationView(
                        program: item.program,
                        isSelected: selectedMapItem?.id == item.id
                    )
                }
                .tag(item)
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(mapStyle)
        .mapControls {
            #if os(iOS)
            MapCompass()
            MapScaleView()
            #elseif os(macOS)
            MapCompass()
            MapZoomStepper()
            MapScaleView()
            #elseif os(visionOS)
            MapCompass()
            #endif
        }
        #if os(visionOS)
        .mapCameraKeyframeAnimator(trigger: selectedMapItem) { camera in
            if let item = selectedMapItem {
                KeyframeTrack(\.centerCoordinate) {
                    LinearKeyframe(item.coordinate, duration: 0.5)
                }
            }
        }
        #endif
        .onChange(of: selectedMapItem) { _, newValue in
            if let item = newValue {
                selectedProgram = item.program
            }
        }
    }

    private var mapStyle: MapStyle {
        #if os(visionOS)
        return .standard(elevation: .realistic)
        #else
        return colorScheme == .dark ? .standard(elevation: .realistic, pointsOfInterest: .excludingAll) : .standard(pointsOfInterest: .excludingAll)
        #endif
    }

    // MARK: - List Content

    private var listContent: some View {
        Group {
            if filteredMapPrograms.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredMapPrograms) { program in
                            Button {
                                selectedProgram = program
                            } label: {
                                ProgramMapCard(program: program)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Subviews

    private var viewModeToggle: some View {
        Picker("View Mode", selection: $viewMode) {
            ForEach(ViewMode.allCases) { mode in
                Label(mode.label, systemImage: mode.icon)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .fixedSize()
    }

    private var locationButton: some View {
        Button {
            requestUserLocation()
        } label: {
            Image(systemName: locationService.hasLocation ? "location.fill" : "location")
                .foregroundStyle(Color.appPrimary)
        }
        .disabled(locationService.isLoading)
    }

    private var programCountBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "mappin.circle.fill")
                .foregroundStyle(Color.appPrimary)
            Text("\(filteredMapPrograms.count) programs")
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        #if os(iOS)
        .background(.regularMaterial, in: Capsule())
        #elseif os(macOS)
        .background(Color(.windowBackgroundColor), in: Capsule())
        #elseif os(visionOS)
        .background(.regularMaterial, in: Capsule())
        #endif
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Programs Found")
                .font(.headline)

            Text("Try adjusting your search or filters to see programs on the map.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if !searchText.isEmpty {
                Button("Clear Search") {
                    searchText = ""
                }
                .buttonStyle(.bordered)
                .tint(.appPrimary)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func requestUserLocation() {
        if !locationService.hasPermission {
            locationService.requestPermission()
        }

        locationService.getCurrentLocation()

        // Animate to user location when available
        if let location = locationService.currentLocation {
            withAnimation(.easeInOut(duration: 0.5)) {
                cameraPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                ))
            }
        }
    }
}

// MARK: - View Mode

extension MapView {
    enum ViewMode: String, CaseIterable, Identifiable {
        case map
        case list

        var id: String { rawValue }

        var label: String {
            switch self {
            case .map: return "Map"
            case .list: return "List"
            }
        }

        var icon: String {
            switch self {
            case .map: return "map"
            case .list: return "list.bullet"
            }
        }
    }
}

// MARK: - Program Map Item

/// Wrapper for Program to conform to MapKit requirements
struct ProgramMapItem: Identifiable, Hashable {
    let program: Program

    var id: String { program.id }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: program.latitude ?? 0,
            longitude: program.longitude ?? 0
        )
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ProgramMapItem, rhs: ProgramMapItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Program Annotation View

/// Custom annotation marker for programs with category-colored styling
struct ProgramAnnotationView: View {
    let program: Program
    var isSelected: Bool = false

    private var categoryColor: Color {
        Color.categoryColor(for: program.category)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Marker bubble
            ZStack {
                // Shadow layer
                Circle()
                    .fill(categoryColor.opacity(0.3))
                    .frame(width: isSelected ? 48 : 36, height: isSelected ? 48 : 36)
                    .blur(radius: 4)

                // Main marker
                Circle()
                    .fill(categoryColor.gradient)
                    .frame(width: isSelected ? 44 : 32, height: isSelected ? 44 : 32)
                    .overlay {
                        Image(systemName: categoryIcon)
                            .font(isSelected ? .body : .caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(.white, lineWidth: isSelected ? 3 : 2)
                    }
            }

            // Pointer triangle
            Triangle()
                .fill(categoryColor)
                .frame(width: 12, height: 8)
                .offset(y: -1)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Program Map Card

/// Compact card view for program list in map view
struct ProgramMapCard: View {
    let program: Program
    @Environment(ProgramsViewModel.self) private var programsVM

    private var categoryColor: Color {
        Color.categoryColor(for: program.category)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Circle()
                .fill(categoryColor.gradient)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: categoryIcon)
                        .font(.body)
                        .foregroundStyle(.white)
                }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(program.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Category tag
                    Text(program.category)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(categoryColor.opacity(0.15))
                        .foregroundStyle(categoryColor)
                        .clipShape(Capsule())

                    // Location
                    if let address = program.address {
                        Text(address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text(program.locationText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                // Distance if available
                if let distance = program.distanceFromUser {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(LocationService.formatDistance(distance))
                            .font(.caption)
                    }
                    .foregroundStyle(Color.appInfo)
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
                    .foregroundStyle(programsVM.isFavorite(program.id) ? Color.appAccent : Color.secondary)
                    .symbolEffect(.bounce, value: programsVM.isFavorite(program.id))
            }
            .buttonStyle(.plain)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        #if os(iOS)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        #elseif os(macOS)
        .background(Color(.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16))
        #elseif os(visionOS)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .hoverEffect(.highlight)
        #endif
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
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

// MARK: - Preview

#Preview {
    MapView()
        .environment(ProgramsViewModel())
}
