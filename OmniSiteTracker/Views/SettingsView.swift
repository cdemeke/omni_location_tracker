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

                    // Placeholder for future settings sections
                    Text("Settings options coming soon")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                }
                .padding(20)
            }
            .background(WarmGradientBackground())
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Settings")
            .onAppear {
                viewModel.configure(with: modelContext)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: PlacementLog.self, inMemory: true)
}
