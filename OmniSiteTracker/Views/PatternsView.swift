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

    // Date range state with defaults
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var endDate: Date = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Selected date range display
                    selectedRangeHeader

                    // Date range picker
                    DateRangePickerView(startDate: $startDate, endDate: $endDate)

                    // Additional content will be added in future stories
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

    // MARK: - Selected Range Header

    private var selectedRangeHeader: some View {
        VStack(spacing: 4) {
            Text("Selected Period")
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            Text(formattedDateRange)
                .font(.headline)
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }

    private var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

// MARK: - Preview

#Preview {
    PatternsView()
        .modelContainer(for: PlacementLog.self, inMemory: true)
}
