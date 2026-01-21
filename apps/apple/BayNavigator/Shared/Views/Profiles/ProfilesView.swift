import SwiftUI
import BayNavigatorCore

/// View for managing user profiles
/// Each household member can have their own profile with personalized saved programs
struct ProfilesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var profiles: [UserProfile] = []
    @State private var activeProfileId: String?
    @State private var savedCounts: [String: Int] = [:]
    @State private var isLoading = true
    @State private var showEditSheet = false
    @State private var editingProfile: UserProfile?
    @State private var profileToDelete: UserProfile?
    @State private var showDeleteConfirmation = false

    private let profileService = ProfileService.shared

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading profiles...")
                } else if profiles.isEmpty {
                    emptyStateView
                } else {
                    profilesListView
                }
            }
            .navigationTitle("Profiles")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if profiles.count < UserProfile.maxProfiles {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            editingProfile = nil
                            showEditSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditProfileView(
                    profile: editingProfile,
                    existingNames: profiles.map { $0.name.lowercased() },
                    onSave: { profile in
                        Task {
                            await saveProfile(profile)
                        }
                    }
                )
            }
            .confirmationDialog(
                "Delete Profile",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                if let profile = profileToDelete {
                    Button("Delete \"\(profile.name)\"", role: .destructive) {
                        Task {
                            await deleteProfile(profile)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    profileToDelete = nil
                }
            } message: {
                if let profile = profileToDelete {
                    let count = savedCounts[profile.id] ?? 0
                    Text("This will delete the profile and \(count) saved program\(count == 1 ? "" : "s").")
                }
            }
        }
        .task {
            await loadProfiles()
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.appPrimary)
            }

            VStack(spacing: 8) {
                Text("No Profiles Yet")
                    .font(.title2.bold())

                Text("Create profiles for yourself and family members to save programs separately.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                editingProfile = nil
                showEditSheet = true
            } label: {
                Label("Create First Profile", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appPrimary)
        }
        .padding()
    }

    private var profilesListView: some View {
        List {
            // Info section
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color.appPrimary)

                    Text("Create profiles for family members. Each profile can save up to \(UserProfile.maxSavedPerProfile) programs.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            // Profiles section
            Section("Profiles (\(profiles.count)/\(UserProfile.maxProfiles))") {
                ForEach(profiles) { profile in
                    ProfileCardView(
                        profile: profile,
                        isActive: profile.id == activeProfileId,
                        savedCount: savedCounts[profile.id] ?? 0,
                        onTap: {
                            Task {
                                await setActiveProfile(profile.id)
                            }
                        },
                        onEdit: {
                            editingProfile = profile
                            showEditSheet = true
                        },
                        onDelete: {
                            profileToDelete = profile
                            showDeleteConfirmation = true
                        }
                    )
                }
            }

            // Add profile button
            if profiles.count < UserProfile.maxProfiles {
                Section {
                    Button {
                        editingProfile = nil
                        showEditSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.appPrimary)
                            Text("Add Profile")
                            Spacer()
                            Text("\(profiles.count)/\(UserProfile.maxProfiles)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func loadProfiles() async {
        let loadedProfiles = await profileService.getProfiles()
        let activeId = await profileService.getActiveProfileId()

        // Load saved counts for each profile
        var counts: [String: Int] = [:]
        for profile in loadedProfiles {
            let count = await profileService.getSavedProgramCount(for: profile.id)
            counts[profile.id] = count
        }

        await MainActor.run {
            profiles = loadedProfiles
            activeProfileId = activeId
            savedCounts = counts
            isLoading = false
        }
    }

    private func setActiveProfile(_ id: String) async {
        await profileService.setActiveProfileId(id)
        await MainActor.run {
            activeProfileId = id
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            #endif
        }
    }

    private func saveProfile(_ profile: UserProfile) async {
        if editingProfile == nil {
            // Create new profile
            _ = await profileService.createProfile(
                name: profile.name,
                city: profile.city,
                zipCode: profile.zipCode,
                county: profile.county,
                birthYear: profile.birthYear,
                relationship: profile.relationship,
                colorIndex: profile.colorIndex,
                qualifications: profile.qualifications
            )
        } else {
            // Update existing
            await profileService.updateProfile(profile)
        }

        await loadProfiles()
    }

    private func deleteProfile(_ profile: UserProfile) async {
        await profileService.deleteProfile(profile.id)
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
        await loadProfiles()
    }
}

// MARK: - Profile Card View

struct ProfileCardView: View {
    let profile: UserProfile
    let isActive: Bool
    let savedCount: Int
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(profile.color)
                        .frame(width: 48, height: 48)

                    Text(profile.initial)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(profile.name)
                            .font(.headline)
                            .foregroundStyle(colorScheme == .dark ? .white : .primary)

                        if isActive {
                            Text("Active")
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.appPrimary)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: profile.relationship.systemImage)
                            .font(.caption)

                        Text(profile.relationship.displayName)
                            .font(.subheadline)

                        Text("  ")

                        Image(systemName: "bookmark.fill")
                            .font(.caption)

                        Text("\(savedCount) saved")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Menu
                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            isActive
                ? Color.appPrimary.opacity(0.1)
                : Color.clear
        )
    }
}

#Preview {
    ProfilesView()
}
