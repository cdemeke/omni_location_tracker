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
                }
                .padding(20)
            }
            .background(WarmGradientBackground())
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Settings")
            .onAppear {
                viewModel.configure(with: modelContext)
                restDays = viewModel.getRestDuration()
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
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: PlacementLog.self, inMemory: true)
}
