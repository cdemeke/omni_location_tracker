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
            }
            .alert("Cannot Disable All Sites", isPresented: $showDisableAllAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("At least one body site must remain enabled.")
            }
        }
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
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: PlacementLog.self, inMemory: true)
}
