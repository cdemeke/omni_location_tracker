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

    // Export state
    @State private var showingExportSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Selected date range display
                    selectedRangeHeader

                    // Date range picker
                    DateRangePickerView(startDate: $startDate, endDate: $endDate)

                    if hasPlacementData {
                        // Rotation Score section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader("Rotation Score")
                            ComplianceScoreView(rotationScore: rotationScore)
                        }

                        // Usage Heatmap section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader("Usage Heatmap")
                            HeatmapBodyDiagramView(heatmapData: heatmapData)
                        }

                        // Zone Statistics section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader("Zone Statistics")
                            ZoneStatisticsListView(heatmapData: heatmapData)
                        }

                        // Usage Trend section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader("Usage Trend")
                            UsageTrendChartView(trendData: trendData)
                        }

                        // Location Breakdown section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader("Location Breakdown")
                            LocationBreakdownChartView(locationTrendData: locationTrendData)
                        }
                    } else {
                        // Empty state
                        emptyStateView
                    }
                }
                .padding(20)
            }
            .background(WarmGradientBackground())
            .navigationTitle("Patterns")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    shareButton
                }
            }
            .confirmationDialog("Export Patterns", isPresented: $showingExportSheet, titleVisibility: .visible) {
                Button("Export as Image") {
                    // TODO: Implement in US-023
                }
                Button("Export as PDF") {
                    // TODO: Implement in US-024
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Choose an export format for your pattern data.")
            }
            .onAppear {
                viewModel.configure(with: modelContext)
            }
        }
    }

    // MARK: - Computed Data

    /// Rotation score recalculates when date range changes
    private var rotationScore: RotationScore {
        viewModel.calculateRotationScore(from: startDate, to: endDate)
    }

    /// Heatmap data recalculates when date range changes
    private var heatmapData: [HeatmapData] {
        viewModel.generateHeatmapData(from: startDate, to: endDate)
    }

    /// Trend data recalculates when date range changes
    private var trendData: [TrendDataPoint] {
        viewModel.getPlacementTrend(from: startDate, to: endDate)
    }

    /// Location breakdown trend data recalculates when date range changes
    private var locationTrendData: [BodyLocation: [TrendDataPoint]] {
        // Auto-select grouping: day for ranges < 30 days, week for >= 30 days
        let daysDifference = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        let grouping: DateGrouping = daysDifference < 30 ? .day : .week
        return viewModel.getLocationTrend(from: startDate, to: endDate, groupBy: grouping)
    }

    /// Check if there is any placement data in the selected date range
    private var hasPlacementData: Bool {
        heatmapData.contains { $0.usageCount > 0 }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(.textMuted.opacity(0.5))

            Text("No Placement Data")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            Text("No placement data for this period. Log placements from the Home screen to see your rotation patterns and analytics.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Share Button

    private var shareButton: some View {
        Button {
            showingExportSheet = true
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.title3)
                .foregroundColor(.appAccent)
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
