//
//  PatternsView.swift
//  OmniSiteTracker
//
//  Displays usage patterns with heatmap visualization and analytics.
//

import SwiftUI
import SwiftData
import UIKit

// MARK: - Local Components (workaround for scope issues)

private struct PatternsHelpButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 18))
                .foregroundColor(.textMuted)
        }
        .buttonStyle(.plain)
    }
}

private struct PatternsHelpTooltip: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(message)
                .font(.subheadline)
                .foregroundColor(.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onDismiss) {
                Text("Got it")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appAccent)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .frame(maxWidth: 280)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 4)
        )
        .transition(.opacity)
    }
}

private struct PatternsAboutModal: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

            Text("OmniSite")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text("This app was developed by a father caring for his child with Type 1 Diabetes.\n\nIt's intended to help ensure you're rotating pump placement locations and minimizing the chance of scar tissue developing.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                Text("Made with love.")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)

                Text("Love you, Theo.")
                    .font(.headline)
                    .foregroundColor(.appAccent)
            }
            .padding(.top, 8)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appAccent)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 24)
        .background(Color.appBackground)
    }
}

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
    @State private var exportedPDFURL: URL?
    @State private var showingPDFShareSheet = false

    // Help tooltip state
    @State private var showingScoreHelp = false
    @State private var showingHeatmapHelp = false
    @State private var showingAboutModal = false
    @State private var scrollOffset: CGFloat = 0
    @AppStorage("hasSeenPatternsHelp") private var hasSeenHelp = false

    private var showNavBarLogo: Bool {
        scrollOffset < 100
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Custom large title with icon
                    HStack(spacing: 12) {
                        Button {
                            showingAboutModal = true
                        } label: {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        Text("Patterns")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onChange(of: geo.frame(in: .global).minY) { _, newValue in
                                    scrollOffset = newValue
                                }
                                .onAppear {
                                    scrollOffset = geo.frame(in: .global).minY
                                }
                        }
                    )

                    // Selected date range display
                    selectedRangeHeader

                    // Date range picker
                    DateRangePickerView(startDate: $startDate, endDate: $endDate)

                    if hasPlacementData {
                        // Rotation Score section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .top) {
                                SectionHeader("Rotation Score")
                                Spacer()
                                PatternsHelpButton {
                                    withAnimation {
                                        showingScoreHelp = true
                                    }
                                }
                            }
                            ComplianceScoreView(rotationScore: rotationScore)
                        }

                        // Usage Heatmap section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .top) {
                                SectionHeader("Usage Heatmap")
                                Spacer()
                                PatternsHelpButton {
                                    withAnimation {
                                        showingHeatmapHelp = true
                                    }
                                }
                            }
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if showNavBarLogo {
                        Button {
                            showingAboutModal = true
                        } label: {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        }
                        .transition(.opacity)
                    }
                }
                ToolbarItem(placement: .principal) {
                    if showNavBarLogo {
                        Text("Patterns")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                            .transition(.opacity)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    shareButton
                }
            }
            .confirmationDialog("Export Patterns", isPresented: $showingExportSheet, titleVisibility: .visible) {
                Button("Export as Image") {
                    exportAsImage()
                }
                Button("Export as PDF") {
                    exportAsPDF()
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
            .sheet(isPresented: $showingPDFShareSheet) {
                if let pdfURL = exportedPDFURL {
                    ShareSheet(activityItems: [pdfURL])
                }
            }
            .sheet(isPresented: $showingAboutModal) {
                PatternsAboutModal()
                    .presentationDetents([.medium])
            }
            .onAppear {
                viewModel.configure(with: modelContext)
                // Auto-show score tooltip on first visit after delay
                if !hasSeenHelp {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            showingScoreHelp = true
                        }
                    }
                }
            }
            .overlay {
                if showingScoreHelp {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showingScoreHelp = false
                            }
                            if !hasSeenHelp {
                                hasSeenHelp = true
                            }
                        }
                    PatternsHelpTooltip(
                        message: "Your rotation score (0-100) based on distribution balance and rest compliance."
                    ) {
                        withAnimation {
                            showingScoreHelp = false
                        }
                        if !hasSeenHelp {
                            hasSeenHelp = true
                        }
                    }
                }
            }
            .overlay {
                if showingHeatmapHelp {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showingHeatmapHelp = false
                            }
                        }
                    PatternsHelpTooltip(
                        message: "Warmer colors = more frequently used. Aim for even distribution across all sites."
                    ) {
                        withAnimation {
                            showingHeatmapHelp = false
                        }
                    }
                }
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

            Text("At least 5 placements are needed to generate pattern insights.")
                .font(.caption)
                .foregroundColor(.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.top, 8)
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

    /// Exports the pattern data as a PDF using UIGraphicsPDFRenderer
    @MainActor
    private func exportAsPDF() {
        let pdfGenerator = PatternsPDFGenerator(
            heatmapData: heatmapData,
            rotationScore: rotationScore,
            trendData: trendData,
            dateRange: formattedDateRange
        )

        if let pdfURL = pdfGenerator.generatePDF() {
            exportedPDFURL = pdfURL
            showingPDFShareSheet = true
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

// MARK: - PDF Generator

/// Generates a PDF document containing pattern data statistics
class PatternsPDFGenerator {
    private let heatmapData: [HeatmapData]
    private let rotationScore: RotationScore
    private let trendData: [TrendDataPoint]
    private let dateRange: String

    // PDF page dimensions (US Letter)
    private let pageWidth: CGFloat = 612
    private let pageHeight: CGFloat = 792
    private let margin: CGFloat = 50

    init(heatmapData: [HeatmapData], rotationScore: RotationScore, trendData: [TrendDataPoint], dateRange: String) {
        self.heatmapData = heatmapData
        self.rotationScore = rotationScore
        self.trendData = trendData
        self.dateRange = dateRange
    }

    func generatePDF() -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "OmniSite Tracker",
            kCGPDFContextAuthor: "OmniSite Tracker App",
            kCGPDFContextTitle: "Rotation Patterns Report"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()
            drawContent(in: context.cgContext)
        }

        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("OmniSite_Patterns_Report.pdf")

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }

    private func drawContent(in context: CGContext) {
        var yPosition: CGFloat = margin

        // Title
        yPosition = drawTitle(at: yPosition)

        // Date range
        yPosition = drawDateRange(at: yPosition)

        // Generation timestamp
        yPosition = drawTimestamp(at: yPosition)

        yPosition += 20

        // Compliance Score Section
        yPosition = drawComplianceScore(at: yPosition)

        yPosition += 20

        // Heatmap Summary Section
        yPosition = drawHeatmapSummary(at: yPosition)

        yPosition += 20

        // Zone Statistics Table
        yPosition = drawZoneStatisticsTable(at: yPosition)

        yPosition += 20

        // Trend Summary
        yPosition = drawTrendSummary(at: yPosition)

        // Footer
        drawFooter()
    }

    private func drawTitle(at yPosition: CGFloat) -> CGFloat {
        let title = "OmniSite Tracker"
        let subtitle = "Rotation Patterns Report"

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.darkGray
        ]

        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.gray
        ]

        let titleSize = title.size(withAttributes: titleAttributes)
        let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)

        let titleX = (pageWidth - titleSize.width) / 2
        title.draw(at: CGPoint(x: titleX, y: yPosition), withAttributes: titleAttributes)

        let subtitleX = (pageWidth - subtitleSize.width) / 2
        subtitle.draw(at: CGPoint(x: subtitleX, y: yPosition + titleSize.height + 4), withAttributes: subtitleAttributes)

        return yPosition + titleSize.height + subtitleSize.height + 16
    }

    private func drawDateRange(at yPosition: CGFloat) -> CGFloat {
        let text = "Report Period: \(dateRange)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]

        let textSize = text.size(withAttributes: attributes)
        let textX = (pageWidth - textSize.width) / 2
        text.draw(at: CGPoint(x: textX, y: yPosition), withAttributes: attributes)

        return yPosition + textSize.height + 8
    }

    private func drawTimestamp(at yPosition: CGFloat) -> CGFloat {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let timestamp = "Generated: \(formatter.string(from: Date()))"

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]

        let textSize = timestamp.size(withAttributes: attributes)
        let textX = (pageWidth - textSize.width) / 2
        timestamp.draw(at: CGPoint(x: textX, y: yPosition), withAttributes: attributes)

        return yPosition + textSize.height + 8
    }

    private func drawComplianceScore(at yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition

        // Section header
        currentY = drawSectionHeader("Compliance Score", at: currentY)

        let contentX = margin + 20

        // Overall score
        let scoreText = "Overall Score: \(rotationScore.score)/100"
        let scoreAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: scoreColor
        ]
        scoreText.draw(at: CGPoint(x: contentX, y: currentY), withAttributes: scoreAttributes)
        currentY += 28

        // Sub-scores
        let subScoreAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]

        let distributionText = "Distribution Score: \(rotationScore.distributionScore)/50"
        distributionText.draw(at: CGPoint(x: contentX, y: currentY), withAttributes: subScoreAttributes)
        currentY += 18

        let restText = "Rest Compliance Score: \(rotationScore.restComplianceScore)/50"
        restText.draw(at: CGPoint(x: contentX, y: currentY), withAttributes: subScoreAttributes)
        currentY += 22

        // Explanation
        let explanationAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.italicSystemFont(ofSize: 11),
            .foregroundColor: UIColor.gray
        ]

        let explanationRect = CGRect(x: contentX, y: currentY, width: pageWidth - margin * 2 - 20, height: 60)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping

        var explanationAttrs = explanationAttributes
        explanationAttrs[.paragraphStyle] = paragraphStyle

        let explanationNS = rotationScore.explanation as NSString
        explanationNS.draw(in: explanationRect, withAttributes: explanationAttrs)

        return currentY + 50
    }

    private var scoreColor: UIColor {
        if rotationScore.score < 50 {
            return UIColor(red: 0.85, green: 0.35, blue: 0.35, alpha: 1.0)
        } else if rotationScore.score <= 75 {
            return UIColor(red: 0.95, green: 0.65, blue: 0.25, alpha: 1.0)
        } else {
            return UIColor(red: 0.35, green: 0.75, blue: 0.45, alpha: 1.0)
        }
    }

    private func drawHeatmapSummary(at yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition

        // Section header
        currentY = drawSectionHeader("Heatmap Summary", at: currentY)

        let contentX = margin + 20
        let sortedData = heatmapData.sorted { $0.usageCount > $1.usageCount }

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.darkGray
        ]

        // Total placements
        let totalPlacements = sortedData.reduce(0) { $0 + $1.usageCount }
        let totalText = "Total Placements: \(totalPlacements)"
        totalText.draw(at: CGPoint(x: contentX, y: currentY), withAttributes: textAttributes)
        currentY += 18

        // Most used location
        if let mostUsed = sortedData.first, mostUsed.usageCount > 0 {
            let mostUsedText = "Most Used: \(mostUsed.location.shortName) (\(mostUsed.usageCount) placements, \(String(format: "%.1f", mostUsed.percentageOfTotal))%)"
            mostUsedText.draw(at: CGPoint(x: contentX, y: currentY), withAttributes: textAttributes)
            currentY += 18
        }

        // Least used location (with usage > 0)
        if let leastUsed = sortedData.filter({ $0.usageCount > 0 }).last {
            let leastUsedText = "Least Used: \(leastUsed.location.shortName) (\(leastUsed.usageCount) placements, \(String(format: "%.1f", leastUsed.percentageOfTotal))%)"
            leastUsedText.draw(at: CGPoint(x: contentX, y: currentY), withAttributes: textAttributes)
            currentY += 18
        }

        // Unused locations
        let unusedLocations = sortedData.filter { $0.usageCount == 0 }
        if !unusedLocations.isEmpty {
            let unusedNames = unusedLocations.map { $0.location.shortName }.joined(separator: ", ")
            let unusedText = "Unused Locations: \(unusedNames)"
            unusedText.draw(at: CGPoint(x: contentX, y: currentY), withAttributes: textAttributes)
            currentY += 18
        }

        return currentY + 8
    }

    private func drawZoneStatisticsTable(at yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition

        // Section header
        currentY = drawSectionHeader("Zone Statistics", at: currentY)

        let sortedData = heatmapData.sorted { $0.usageCount > $1.usageCount }

        // Table headers
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray
        ]

        let col1X = margin + 20
        let col2X = margin + 150
        let col3X = margin + 220
        let col4X = margin + 300
        let col5X = margin + 380

        "Zone".draw(at: CGPoint(x: col1X, y: currentY), withAttributes: headerAttributes)
        "Count".draw(at: CGPoint(x: col2X, y: currentY), withAttributes: headerAttributes)
        "Percentage".draw(at: CGPoint(x: col3X, y: currentY), withAttributes: headerAttributes)
        "Intensity".draw(at: CGPoint(x: col4X, y: currentY), withAttributes: headerAttributes)
        "Last Used".draw(at: CGPoint(x: col5X, y: currentY), withAttributes: headerAttributes)
        currentY += 16

        // Draw header line
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(UIColor.lightGray.cgColor)
        context?.setLineWidth(0.5)
        context?.move(to: CGPoint(x: margin + 10, y: currentY))
        context?.addLine(to: CGPoint(x: pageWidth - margin - 10, y: currentY))
        context?.strokePath()
        currentY += 6

        // Table rows
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none

        for data in sortedData {
            let zoneName = data.location.shortName
            let count = "\(data.usageCount)"
            let percentage = String(format: "%.1f%%", data.percentageOfTotal)
            let intensity = String(format: "%.2f", data.intensity)
            let lastUsed = data.lastUsed != nil ? dateFormatter.string(from: data.lastUsed!) : "Never"

            zoneName.draw(at: CGPoint(x: col1X, y: currentY), withAttributes: rowAttributes)
            count.draw(at: CGPoint(x: col2X, y: currentY), withAttributes: rowAttributes)
            percentage.draw(at: CGPoint(x: col3X, y: currentY), withAttributes: rowAttributes)
            intensity.draw(at: CGPoint(x: col4X, y: currentY), withAttributes: rowAttributes)
            lastUsed.draw(at: CGPoint(x: col5X, y: currentY), withAttributes: rowAttributes)
            currentY += 16
        }

        return currentY + 8
    }

    private func drawTrendSummary(at yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition

        // Section header
        currentY = drawSectionHeader("Trend Summary", at: currentY)

        let contentX = margin + 20
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.darkGray
        ]

        let totalInRange = trendData.reduce(0) { $0 + $1.count }
        let totalText = "Total Placements in Period: \(totalInRange)"
        totalText.draw(at: CGPoint(x: contentX, y: currentY), withAttributes: textAttributes)
        currentY += 18

        let nonZeroPeriods = trendData.filter { $0.count > 0 }
        if !nonZeroPeriods.isEmpty {
            let avgPerPeriod = Double(totalInRange) / Double(nonZeroPeriods.count)
            let avgText = "Average per Active Period: \(String(format: "%.1f", avgPerPeriod))"
            avgText.draw(at: CGPoint(x: contentX, y: currentY), withAttributes: textAttributes)
            currentY += 18
        }

        if let maxPeriod = trendData.max(by: { $0.count < $1.count }), maxPeriod.count > 0 {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            let peakText = "Peak: \(maxPeriod.count) placements on \(dateFormatter.string(from: maxPeriod.date))"
            peakText.draw(at: CGPoint(x: contentX, y: currentY), withAttributes: textAttributes)
            currentY += 18
        }

        return currentY + 8
    }

    private func drawSectionHeader(_ title: String, at yPosition: CGFloat) -> CGFloat {
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor(red: 0.4, green: 0.3, blue: 0.25, alpha: 1.0)
        ]

        title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttributes)

        // Draw underline
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(UIColor(red: 0.85, green: 0.8, blue: 0.75, alpha: 1.0).cgColor)
        context?.setLineWidth(1.0)
        context?.move(to: CGPoint(x: margin, y: yPosition + 20))
        context?.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition + 20))
        context?.strokePath()

        return yPosition + 28
    }

    private func drawFooter() {
        let footerY = pageHeight - margin + 10

        let footerText = "Generated by OmniSite Tracker"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.lightGray
        ]

        let textSize = footerText.size(withAttributes: footerAttributes)
        let textX = (pageWidth - textSize.width) / 2
        footerText.draw(at: CGPoint(x: textX, y: footerY), withAttributes: footerAttributes)
    }
}

// MARK: - Preview

#Preview {
    PatternsView()
        .modelContainer(for: PlacementLog.self, inMemory: true)
}
