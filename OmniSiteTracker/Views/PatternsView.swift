//
//  PatternsView.swift
//  OmniSiteTracker
//
//  Displays usage patterns with heatmap visualization and analytics.
//

import SwiftUI
import SwiftData
import UIKit

/// Patterns screen showing usage analytics and rotation heatmaps
struct PatternsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PlacementViewModel()

    // Date range state with defaults
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var endDate: Date = Date()

    // Export state
    @State private var showingExportSheet = false
    @State private var showingShareSheet = false
    @State private var exportedImage: UIImage?

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
                    exportAsImage()
                }
                Button("Export as PDF") {
                    // TODO: Implement in US-024
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Choose an export format for your pattern data.")
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = exportedImage {
                    ShareSheet(activityItems: [image])
                }
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

    // MARK: - Export Functions

    /// Exports the pattern data as an image using ImageRenderer
    @MainActor
    private func exportAsImage() {
        let exportView = ExportablePatternView(
            heatmapData: heatmapData,
            rotationScore: rotationScore,
            dateRange: formattedDateRange
        )

        let renderer = ImageRenderer(content: exportView)
        renderer.scale = UIScreen.main.scale

        if let uiImage = renderer.uiImage {
            exportedImage = uiImage
            showingShareSheet = true
        }
    }
}

// MARK: - Exportable Pattern View

/// A view designed for image export containing heatmap, zone stats, and compliance score
struct ExportablePatternView: View {
    let heatmapData: [HeatmapData]
    let rotationScore: RotationScore
    let dateRange: String

    private var timestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header with app name and date range
            VStack(spacing: 8) {
                Text("OmniSite Tracker")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)

                Text("Rotation Patterns Report")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)

                Text(dateRange)
                    .font(.caption)
                    .foregroundColor(.textMuted)
            }
            .padding(.top, 20)

            // Compliance Score
            ExportableScoreView(rotationScore: rotationScore)

            // Zone Statistics Summary
            ExportableZoneStatsView(heatmapData: heatmapData)

            // Footer with timestamp
            VStack(spacing: 4) {
                Text("Generated: \(timestamp)")
                    .font(.caption2)
                    .foregroundColor(.textMuted)

                Text("OmniSite Tracker")
                    .font(.caption2)
                    .foregroundColor(.textMuted)
            }
            .padding(.bottom, 20)
        }
        .padding(24)
        .frame(width: 400)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.96, blue: 0.92),
                    Color(red: 0.96, green: 0.94, blue: 0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Exportable Score View

/// Simplified compliance score display for export
private struct ExportableScoreView: View {
    let rotationScore: RotationScore

    var body: some View {
        VStack(spacing: 12) {
            Text("Rotation Score")
                .font(.headline)
                .foregroundColor(.textPrimary)

            ZStack {
                Circle()
                    .stroke(Color.appBackgroundSecondary, lineWidth: 8)

                Circle()
                    .trim(from: 0, to: CGFloat(rotationScore.score) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(rotationScore.score)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor)

                    Text("/ 100")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .frame(width: 100, height: 100)

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Distribution")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                    Text("\(rotationScore.distributionScore)/50")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                }

                VStack(spacing: 4) {
                    Text("Rest Compliance")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                    Text("\(rotationScore.restComplianceScore)/50")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                }
            }

            Text(rotationScore.explanation)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }

    private var scoreColor: Color {
        if rotationScore.score < 50 {
            return Color(red: 0.85, green: 0.35, blue: 0.35)
        } else if rotationScore.score <= 75 {
            return .appWarning
        } else {
            return .appSuccess
        }
    }
}

// MARK: - Exportable Zone Stats View

/// Simplified zone statistics display for export
private struct ExportableZoneStatsView: View {
    let heatmapData: [HeatmapData]

    private var sortedData: [HeatmapData] {
        heatmapData.sorted { $0.usageCount > $1.usageCount }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Zone Statistics")
                .font(.headline)
                .foregroundColor(.textPrimary)

            VStack(spacing: 8) {
                ForEach(sortedData) { data in
                    HStack(spacing: 12) {
                        Image(systemName: data.location.iconName)
                            .font(.system(size: 12))
                            .foregroundColor(intensityColor(for: data.intensity))
                            .frame(width: 20)

                        Text(data.location.shortName)
                            .font(.caption)
                            .foregroundColor(.textPrimary)
                            .frame(width: 80, alignment: .leading)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.appBackgroundSecondary)
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(intensityColor(for: data.intensity))
                                    .frame(width: geometry.size.width * CGFloat(data.intensity), height: 6)
                            }
                        }
                        .frame(height: 6)

                        Text("\(data.usageCount)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }

    private func intensityColor(for intensity: Double) -> Color {
        if intensity <= 0 {
            return Color.gray
        } else if intensity <= 0.5 {
            let t = intensity * 2
            return Color(
                red: 0.5 + (0.5 * t),
                green: 0.5 - (0.15 * t),
                blue: 0.5 - (0.5 * t)
            )
        } else {
            let t = (intensity - 0.5) * 2
            return Color(
                red: 1.0,
                green: 0.35 - (0.35 * t),
                blue: 0.0
            )
        }
    }
}

// MARK: - Share Sheet

/// UIViewControllerRepresentable wrapper for UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    PatternsView()
        .modelContainer(for: PlacementLog.self, inMemory: true)
}
