//
//  SettingsView.swift
//  OmniSiteTracker
//
//  Settings screen for customizing app preferences.
//

import SwiftUI
import SwiftData

/// Settings screen for customizing app preferences
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()
    @State private var restDays: Int = 3
    @State private var disabledSites: Set<BodyLocation> = []
    @State private var showDisableAllAlert: Bool = false
    @State private var customSites: [CustomSite] = []
    @State private var showDeleteConfirmation: Bool = false
    @State private var siteToDelete: CustomSite?
    @State private var showAddCustomSiteSheet: Bool = false
    @State private var newSiteName: String = ""
    @State private var newSiteIcon: String = "star.fill"
    @State private var showDuplicateNameError: Bool = false
    @State private var showDisabledSitesInHistory: Bool = true

    /// Curated list of SF Symbols for custom site icons
    private let availableIcons = [
        "star.fill", "circle.fill", "square.fill", "triangle.fill", "heart.fill",
        "bolt.fill", "leaf.fill", "drop.fill", "flame.fill", "moon.fill",
        "sun.max.fill", "cross.fill", "pills.fill", "bandage.fill", "syringe.fill"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Custom large title with icon
                    HStack(spacing: 12) {
                        Image(systemName: "gearshape.fill")
                            .font(.title)
                            .foregroundColor(.appAccent)
                        Text("Settings")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // MARK: - Rotation Settings Section
                    rotationSettingsSection

                    // MARK: - Body Sites Section
                    bodySitesSection

                    // MARK: - Custom Sites Section
                    customSitesSection

                    // MARK: - Data Display Section
                    dataDisplaySection
                }
                .padding(20)
            }
            .background(WarmGradientBackground())
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Settings")
            .onAppear {
                viewModel.configure(with: modelContext)
                restDays = viewModel.getRestDuration()
                disabledSites = Set(viewModel.getDisabledDefaultSites())
                customSites = viewModel.getCustomSites()
                showDisabledSitesInHistory = viewModel.getShowDisabledSitesInHistory()
            }
            .alert("Cannot Disable All Sites", isPresented: $showDisableAllAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("At least one body site must remain enabled.")
            }
            .alert("Delete Custom Site", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    siteToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let site = siteToDelete {
                        viewModel.deleteCustomSite(id: site.id)
                        customSites = viewModel.getCustomSites()
                        siteToDelete = nil
                    }
                }
            } message: {
                if let site = siteToDelete {
                    Text("Are you sure you want to delete \"\(site.name)\"?")
                } else {
                    Text("Are you sure you want to delete this site?")
                }
            }
            .sheet(isPresented: $showAddCustomSiteSheet) {
                addCustomSiteSheet
            }
        }
    }

    // MARK: - Add Custom Site Sheet

    private var addCustomSiteSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Site name text field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Site Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)

                    TextField("Enter site name", text: $newSiteName)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: newSiteName) { _, _ in
                            // Clear error when user types
                            showDuplicateNameError = false
                        }

                    if showDuplicateNameError {
                        Text("A site with this name already exists")
                            .font(.caption)
                            .foregroundColor(.appWarning)
                    }
                }

                // Icon picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose Icon")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                        ForEach(availableIcons, id: \.self) { iconName in
                            iconButton(for: iconName)
                        }
                    }
                }

                Spacer()
            }
            .padding(20)
            .background(WarmGradientBackground())
            .navigationTitle("Add Custom Site")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        resetSheetState()
                        showAddCustomSiteSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addCustomSite()
                    }
                    .disabled(newSiteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func iconButton(for iconName: String) -> some View {
        let isSelected = newSiteIcon == iconName

        return Button(action: {
            newSiteIcon = iconName
        }) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(isSelected ? .white : .appAccent)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.appAccent : Color.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.appAccent : Color.textSecondary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func addCustomSite() {
        let trimmedName = newSiteName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if name already exists
        let existingNames = customSites.map { $0.name.lowercased() }
        if existingNames.contains(trimmedName.lowercased()) {
            showDuplicateNameError = true
            return
        }

        // Add the custom site
        viewModel.addCustomSite(name: trimmedName, iconName: newSiteIcon)
        customSites = viewModel.getCustomSites()

        // Reset and dismiss
        resetSheetState()
        showAddCustomSiteSheet = false
    }

    private func resetSheetState() {
        newSiteName = ""
        newSiteIcon = "star.fill"
        showDuplicateNameError = false
    }

    // MARK: - Rotation Settings Section

    private var rotationSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader("Rotation Settings")

            VStack(spacing: 12) {
                HStack {
                    Text("Minimum Rest Days")
                        .font(.body)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Text("\(restDays)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.appAccent)
                        .frame(minWidth: 40)

                    Stepper("", value: $restDays, in: 1...30)
                        .labelsHidden()
                        .onChange(of: restDays) { _, newValue in
                            viewModel.updateRestDuration(days: newValue)
                        }
                }

                Text("Days before a site can be used again")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .neumorphicCard()
        }
    }

    // MARK: - Body Sites Section

    private var bodySitesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader("Body Sites")

            VStack(spacing: 0) {
                ForEach(BodyLocation.allCases) { location in
                    bodySiteRow(for: location)

                    if location != BodyLocation.allCases.last {
                        Divider()
                            .background(Color.textSecondary.opacity(0.3))
                    }
                }
            }
            .padding(16)
            .neumorphicCard()
        }
    }

    private func bodySiteRow(for location: BodyLocation) -> some View {
        let isEnabled = !disabledSites.contains(location)

        return Toggle(isOn: Binding(
            get: { isEnabled },
            set: { newValue in
                toggleSite(location: location, enable: newValue)
            }
        )) {
            HStack(spacing: 12) {
                Image(systemName: location.iconName)
                    .font(.body)
                    .foregroundColor(isEnabled ? .appAccent : .textSecondary)
                    .frame(width: 24)

                Text(location.displayName)
                    .font(.body)
                    .foregroundColor(isEnabled ? .textPrimary : .textSecondary)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: .appAccent))
        .padding(.vertical, 8)
    }

    private func toggleSite(location: BodyLocation, enable: Bool) {
        let enabledCount = BodyLocation.allCases.count - disabledSites.count

        // If trying to disable and only one site is enabled, show alert
        if !enable && enabledCount <= 1 {
            showDisableAllAlert = true
            return
        }

        // Update local state
        if enable {
            disabledSites.remove(location)
        } else {
            disabledSites.insert(location)
        }

        // Persist change via ViewModel
        viewModel.toggleDefaultSite(location: location)
    }

    // MARK: - Custom Sites Section

    private var customSitesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader("Custom Sites")

            VStack(spacing: 0) {
                if customSites.isEmpty {
                    // Empty state
                    Text("No custom sites yet")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else {
                    // List of custom sites
                    ForEach(customSites, id: \.id) { site in
                        customSiteRow(for: site)

                        if site.id != customSites.last?.id {
                            Divider()
                                .background(Color.textSecondary.opacity(0.3))
                        }
                    }
                }

                // Add Custom Site button
                if !customSites.isEmpty {
                    Divider()
                        .background(Color.textSecondary.opacity(0.3))
                }

                Button(action: {
                    showAddCustomSiteSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.body)
                        Text("Add Custom Site")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.appAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
            .padding(16)
            .neumorphicCard()
        }
    }

    private func customSiteRow(for site: CustomSite) -> some View {
        HStack(spacing: 12) {
            // Site icon
            Image(systemName: site.iconName)
                .font(.body)
                .foregroundColor(site.isEnabled ? .appAccent : .textSecondary)
                .frame(width: 24)

            // Site name
            Text(site.name)
                .font(.body)
                .foregroundColor(site.isEnabled ? .textPrimary : .textSecondary)

            Spacer()

            // Toggle
            Toggle("", isOn: Binding(
                get: { site.isEnabled },
                set: { _ in
                    viewModel.toggleCustomSite(id: site.id)
                    customSites = viewModel.getCustomSites()
                }
            ))
            .toggleStyle(SwitchToggleStyle(tint: .appAccent))
            .labelsHidden()

            // Delete button
            Button(action: {
                siteToDelete = site
                showDeleteConfirmation = true
            }) {
                Image(systemName: "trash")
                    .font(.body)
                    .foregroundColor(.appWarning)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
    }

    // MARK: - Data Display Section

    private var dataDisplaySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader("Data Display")

            VStack(spacing: 12) {
                Toggle(isOn: $showDisabledSitesInHistory) {
                    Text("Show Disabled Sites in History")
                        .font(.body)
                        .foregroundColor(.textPrimary)
                }
                .toggleStyle(SwitchToggleStyle(tint: .appAccent))
                .onChange(of: showDisabledSitesInHistory) { _, newValue in
                    viewModel.updateShowDisabledSitesInHistory(show: newValue)
                }

                Text("When off, disabled sites are hidden from History and Patterns")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .neumorphicCard()
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: PlacementLog.self, inMemory: true)
}
