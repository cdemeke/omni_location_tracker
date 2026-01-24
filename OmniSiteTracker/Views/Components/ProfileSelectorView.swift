//
//  ProfileSelectorView.swift
//  OmniSiteTracker
//
//  UI components for multi-profile support.
//  Allows users to switch between and manage multiple profiles.
//

import SwiftUI
import SwiftData

/// Compact profile selector shown in the app header
struct ProfileSelectorButton: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingProfileSheet = false
    @State private var activeProfile: UserProfile?

    var body: some View {
        Button {
            showingProfileSheet = true
        } label: {
            HStack(spacing: 8) {
                // Profile avatar
                Circle()
                    .fill(activeProfile?.color ?? .appAccent)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: activeProfile?.avatarName ?? "person.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }

                // Profile name
                VStack(alignment: .leading, spacing: 1) {
                    Text(activeProfile?.name ?? "Profile")
                        .font(.subheadline.bold())
                        .foregroundColor(.textPrimary)

                    Text("Tap to switch")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.cardBackground)
            .clipShape(Capsule())
        }
        .sheet(isPresented: $showingProfileSheet) {
            ProfileListSheet(activeProfile: $activeProfile)
        }
        .onAppear {
            loadActiveProfile()
        }
    }

    private func loadActiveProfile() {
        activeProfile = UserProfile.getActive(context: modelContext)
    }
}

/// Full profile list sheet for switching and managing profiles
struct ProfileListSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var activeProfile: UserProfile?

    @State private var profiles: [UserProfile] = []
    @State private var showingAddProfile = false
    @State private var showingEditProfile = false
    @State private var profileToEdit: UserProfile?
    @State private var showingDeleteConfirmation = false
    @State private var profileToDelete: UserProfile?

    var body: some View {
        NavigationStack {
            List {
                // Active profile section
                Section("Current Profile") {
                    if let active = activeProfile {
                        ProfileRow(profile: active, isActive: true)
                    }
                }

                // Other profiles
                if profiles.filter({ $0.id != activeProfile?.id }).count > 0 {
                    Section("Other Profiles") {
                        ForEach(profiles.filter { $0.id != activeProfile?.id }) { profile in
                            ProfileRow(profile: profile, isActive: false)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    switchToProfile(profile)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        profileToDelete = profile
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        profileToEdit = profile
                                        showingEditProfile = true
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                }

                // Add profile button
                Section {
                    Button {
                        showingAddProfile = true
                    } label: {
                        Label("Add Profile", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddProfile) {
                ProfileEditorSheet(mode: .add, onSave: { _ in
                    loadProfiles()
                })
            }
            .sheet(isPresented: $showingEditProfile) {
                if let profile = profileToEdit {
                    ProfileEditorSheet(mode: .edit(profile), onSave: { _ in
                        loadProfiles()
                    })
                }
            }
            .alert("Delete Profile", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    profileToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let profile = profileToDelete {
                        deleteProfile(profile)
                    }
                }
            } message: {
                if let profile = profileToDelete {
                    Text("Are you sure you want to delete \"\(profile.name)\"? This will not delete their placement history.")
                }
            }
            .onAppear {
                loadProfiles()
            }
        }
    }

    private func loadProfiles() {
        profiles = UserProfile.getAll(context: modelContext)
        activeProfile = profiles.first { $0.isActive } ?? profiles.first
    }

    private func switchToProfile(_ profile: UserProfile) {
        profile.setAsActive(context: modelContext)
        activeProfile = profile
        dismiss()
    }

    private func deleteProfile(_ profile: UserProfile) {
        modelContext.delete(profile)
        try? modelContext.save()
        profileToDelete = nil
        loadProfiles()
    }
}

/// Row displaying a single profile
struct ProfileRow: View {
    let profile: UserProfile
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(profile.color)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: profile.avatarName)
                        .font(.title3)
                        .foregroundStyle(.white)
                }

            // Name and info
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Text("\(profile.minimumRestDays) day rest period")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.appSuccess)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Sheet for adding or editing a profile
struct ProfileEditorSheet: View {
    enum Mode {
        case add
        case edit(UserProfile)
    }

    let mode: Mode
    let onSave: (UserProfile) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedColor: String = UserProfile.availableColors[0].hex
    @State private var selectedAvatar: String = UserProfile.availableAvatars[0]
    @State private var minimumRestDays: Int = 18

    var body: some View {
        NavigationStack {
            Form {
                // Name
                Section("Name") {
                    TextField("Profile Name", text: $name)
                }

                // Color
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(UserProfile.availableColors, id: \.hex) { color in
                            Circle()
                                .fill(Color(hex: color.hex) ?? .gray)
                                .frame(width: 44, height: 44)
                                .overlay {
                                    if selectedColor == color.hex {
                                        Image(systemName: "checkmark")
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = color.hex
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Avatar
                Section("Avatar") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(UserProfile.availableAvatars, id: \.self) { avatar in
                            Circle()
                                .fill(Color(hex: selectedColor) ?? .gray)
                                .frame(width: 44, height: 44)
                                .overlay {
                                    Image(systemName: avatar)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }
                                .overlay {
                                    if selectedAvatar == avatar {
                                        Circle()
                                            .stroke(Color.primary, lineWidth: 3)
                                    }
                                }
                                .onTapGesture {
                                    selectedAvatar = avatar
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Rest days
                Section("Settings") {
                    Stepper("Minimum Rest Days: \(minimumRestDays)", value: $minimumRestDays, in: 1...30)
                }
            }
            .navigationTitle(isEditing ? "Edit Profile" : "Add Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if case .edit(let profile) = mode {
                    name = profile.name
                    selectedColor = profile.colorHex
                    selectedAvatar = profile.avatarName
                    minimumRestDays = profile.minimumRestDays
                }
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func saveProfile() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        switch mode {
        case .add:
            let newProfile = UserProfile(
                name: trimmedName,
                colorHex: selectedColor,
                avatarName: selectedAvatar,
                minimumRestDays: minimumRestDays
            )
            modelContext.insert(newProfile)
            try? modelContext.save()
            onSave(newProfile)

        case .edit(let profile):
            profile.name = trimmedName
            profile.colorHex = selectedColor
            profile.avatarName = selectedAvatar
            profile.minimumRestDays = minimumRestDays
            try? modelContext.save()
            onSave(profile)
        }

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    ProfileSelectorButton()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
