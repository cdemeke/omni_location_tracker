//
//  PatternsView.swift
//  OmniSiteTracker
//
//  Displays usage patterns with heatmap visualization and analytics.
//

import SwiftUI
import SwiftData

/// Patterns screen showing usage analytics and rotation heatmaps
struct PatternsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PlacementViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Content will be added in future stories
                    Text("Patterns view coming soon")
                        .font(.headline)
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity, maxHeight: 200)
                }
                .padding(20)
            }
            .background(WarmGradientBackground())
            .navigationTitle("Patterns")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.configure(with: modelContext)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PatternsView()
        .modelContainer(for: PlacementLog.self, inMemory: true)
}
