import SwiftUI
import BayNavigatorCore

/// View for creating or editing a user profile
struct EditProfileView: View {
    let profile: UserProfile?
    let existingNames: [String]
    let onSave: (UserProfile) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Form state
    @State private var name: String = ""
    @State private var locationInput: String = ""
    @State private var city: String?
    @State private var zipCode: String?
    @State private var county: String?
    @State private var birthYear: Int?
    @State private var relationship: ProfileRelationship = .myself
    @State private var colorIndex: Int = 0
    @State private var qualifications: Set<String> = []

    // UI state
    @State private var locationSuggestions: [String] = []
    @State private var showDeleteConfirmation = false
    @State private var nameError: String?

    @FocusState private var focusedField: Field?

    enum Field {
        case name
        case location
    }

    private var isEditing: Bool {
        profile != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                // Name Section
                Section {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .name)
                        .onChange(of: name) { _, newValue in
                            validateName(newValue)
                        }

                    if let error = nameError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Name")
                } footer: {
                    Text("The name for this profile.")
                }

                // Location Section
                Section {
                    TextField("City or ZIP code", text: $locationInput)
                        .focused($focusedField, equals: .location)
                        #if os(iOS)
                        .keyboardType(.default)
                        .textInputAutocapitalization(.words)
                        #endif
                        .onChange(of: locationInput) { _, newValue in
                            handleLocationInput(newValue)
                        }

                    // Suggestions
                    if !locationSuggestions.isEmpty {
                        ForEach(locationSuggestions, id: \.self) { suggestion in
                            Button {
                                selectLocationSuggestion(suggestion)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(suggestion)
                                            .foregroundStyle(colorScheme == .dark ? .white : .primary)

                                        if let suggestedCounty = LocationLookup.lookupCounty(suggestion) {
                                            Text(suggestedCounty)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.up.left")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    // Location confirmation
                    if let county = county {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.appSuccess)

                            VStack(alignment: .leading, spacing: 2) {
                                if let city = city {
                                    Text("\(city), \(county)")
                                        .font(.subheadline)
                                } else {
                                    Text(county)
                                        .font(.subheadline)
                                }

                                if let zip = zipCode {
                                    Text("ZIP: \(zip)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .foregroundStyle(Color.appPrimary)
                    }

                    // Invalid ZIP warning
                    if locationInput.count == 5,
                       locationInput.allSatisfy({ $0.isNumber }),
                       county == nil {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)

                            Text("ZIP code not found in Bay Area. Try entering your city name.")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                } header: {
                    Text("Location")
                } footer: {
                    Text("Enter your city or ZIP code. We'll use this to show relevant programs for your area.")
                }

                // Relationship Section
                Section("Relationship") {
                    Picker("Relationship", selection: $relationship) {
                        ForEach(ProfileRelationship.allCases) { rel in
                            HStack {
                                Image(systemName: rel.systemImage)
                                Text(rel.displayName)
                            }
                            .tag(rel)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Birth Year Section
                Section {
                    Picker("Birth Year", selection: Binding(
                        get: { birthYear ?? Calendar.current.component(.year, from: Date()) - 30 },
                        set: { birthYear = $0 }
                    )) {
                        Text("Not set").tag(Optional<Int>.none)

                        ForEach((1920...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) { year in
                            Text(String(year)).tag(Optional(year))
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Birth Year")
                } footer: {
                    Text("Used to find age-specific programs like senior or youth services.")
                }

                // Profile Color Section
                Section("Profile Color") {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 44), spacing: 12)
                    ], spacing: 12) {
                        ForEach(Array(UserProfile.profileColors.enumerated()), id: \.offset) { index, color in
                            Button {
                                colorIndex = index
                                #if os(iOS)
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                                #endif
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 44, height: 44)

                                    if colorIndex == index {
                                        Image(systemName: "checkmark")
                                            .font(.headline.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .overlay(
                                    Circle()
                                        .stroke(colorIndex == index ? Color.white : Color.clear, lineWidth: 3)
                                )
                                .shadow(
                                    color: colorIndex == index ? color.opacity(0.5) : .clear,
                                    radius: 6,
                                    x: 0,
                                    y: 2
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Qualifications Section
                Section {
                    ForEach(ProfileQualification.allCases) { qual in
                        Button {
                            toggleQualification(qual)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: qual.systemImage)
                                    .font(.title3)
                                    .foregroundStyle(
                                        qualifications.contains(qual.rawValue)
                                            ? Color.appPrimary
                                            : .secondary
                                    )
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(qual.displayName)
                                        .foregroundStyle(colorScheme == .dark ? .white : .primary)

                                    if qual.isSensitive {
                                        HStack(spacing: 4) {
                                            Image(systemName: "lock.fill")
                                            Text("Protected")
                                        }
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                if qualifications.contains(qual.rawValue) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.appPrimary)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("About You")
                } footer: {
                    Text("Select all that apply. This helps us show relevant programs. Sensitive categories are stored securely on your device.")
                }

                // Delete Section (for existing profiles)
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete Profile", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Profile" : "New Profile")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog(
                "Delete Profile",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    // Deletion is handled by parent view
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this profile? This cannot be undone.")
            }
            .onAppear {
                loadExistingProfile()
            }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(hasChanges)
    }

    // MARK: - Computed Properties

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && nameError == nil
    }

    private var hasChanges: Bool {
        guard let profile = profile else {
            return !name.isEmpty || !locationInput.isEmpty || !qualifications.isEmpty
        }

        return name != profile.name ||
            city != profile.city ||
            zipCode != profile.zipCode ||
            county != profile.county ||
            birthYear != profile.birthYear ||
            relationship != profile.relationship ||
            colorIndex != profile.colorIndex ||
            Set(profile.qualifications) != qualifications
    }

    // MARK: - Actions

    private func loadExistingProfile() {
        guard let profile = profile else { return }

        name = profile.name
        city = profile.city
        zipCode = profile.zipCode
        county = profile.county
        birthYear = profile.birthYear
        relationship = profile.relationship
        colorIndex = profile.colorIndex
        qualifications = Set(profile.qualifications)

        // Set location input
        if let zip = profile.zipCode {
            locationInput = zip
        } else if let city = profile.city {
            locationInput = city
        }
    }

    private func validateName(_ newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces).lowercased()

        if trimmed.isEmpty {
            nameError = nil
            return
        }

        // Check for duplicate names (excluding current profile if editing)
        let namesToCheck = isEditing
            ? existingNames.filter { $0 != profile?.name.lowercased() }
            : existingNames

        if namesToCheck.contains(trimmed) {
            nameError = "A profile with this name already exists"
        } else {
            nameError = nil
        }
    }

    private func handleLocationInput(_ input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespaces)

        // Check if it's a complete ZIP code
        if trimmed.count == 5 && trimmed.allSatisfy({ $0.isNumber }) {
            if let foundCity = LocationLookup.zipToCity[trimmed],
               let foundCounty = LocationLookup.lookupCounty(trimmed) {
                zipCode = trimmed
                city = foundCity
                county = foundCounty
                locationSuggestions = []
            } else {
                // Invalid ZIP for Bay Area
                zipCode = nil
                city = nil
                county = nil
                locationSuggestions = []
            }
        } else if trimmed.count >= 2 && !trimmed.allSatisfy({ $0.isNumber }) {
            // City name search
            let suggestions = LocationLookup.getSuggestions(for: trimmed, limit: 5)
            locationSuggestions = suggestions

            // Clear previous location if typing new
            if suggestions.isEmpty {
                // Check exact match
                if LocationLookup.isCityName(trimmed) {
                    selectLocationSuggestion(trimmed)
                } else {
                    zipCode = nil
                    city = nil
                    county = nil
                }
            }
        } else {
            locationSuggestions = []
            if trimmed.isEmpty || (trimmed.allSatisfy({ $0.isNumber }) && trimmed.count < 5) {
                zipCode = nil
                city = nil
                county = nil
            }
        }
    }

    private func selectLocationSuggestion(_ suggestion: String) {
        locationInput = suggestion
        city = suggestion.capitalized
        county = LocationLookup.lookupCounty(suggestion)
        zipCode = nil
        locationSuggestions = []
        focusedField = nil
    }

    private func toggleQualification(_ qual: ProfileQualification) {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        #endif

        if qualifications.contains(qual.rawValue) {
            qualifications.remove(qual.rawValue)
        } else {
            qualifications.insert(qual.rawValue)
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        let savedProfile = UserProfile(
            id: profile?.id ?? UUID().uuidString,
            name: trimmedName,
            city: city,
            zipCode: zipCode,
            county: county,
            birthYear: birthYear,
            relationship: relationship,
            colorIndex: colorIndex,
            qualifications: Array(qualifications),
            createdAt: profile?.createdAt ?? Date(),
            updatedAt: Date()
        )

        onSave(savedProfile)
        dismiss()
    }
}

#Preview("New Profile") {
    EditProfileView(
        profile: nil,
        existingNames: [],
        onSave: { _ in }
    )
}

#Preview("Edit Profile") {
    EditProfileView(
        profile: UserProfile(
            name: "John",
            city: "San Francisco",
            county: "San Francisco",
            birthYear: 1985,
            relationship: .myself,
            colorIndex: 0,
            qualifications: ["veteran", "student"]
        ),
        existingNames: ["john"],
        onSave: { _ in }
    )
}
