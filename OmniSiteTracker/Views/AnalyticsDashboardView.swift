//
//  AnalyticsDashboardView.swift
//  OmniSiteTracker
//
//  Comprehensive analytics view with usage statistics,
//  trends over time, and personalized insights.
//

import SwiftUI
import SwiftData
import Charts

/// Main analytics dashboard view
struct AnalyticsDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlacementLog.placedAt, order: .reverse) private var allPlacements: [PlacementLog]

    @State private var selectedTimeRange: TimeRange = .last30Days
    @State private var selectedMetric: AnalyticsMetric = .siteUsage

    enum TimeRange: String, CaseIterable {
        case last7Days = "7 Days"
        case last30Days = "30 Days"
        case last90Days = "90 Days"
        case allTime = "All Time"

        var days: Int? {
            switch self {
            case .last7Days: return 7
            case .last30Days: return 30
            case .last90Days: return 90
            case .allTime: return nil
            }
        }
    }

    enum AnalyticsMetric: String, CaseIterable {
        case siteUsage = "Site Usage"
        case timeline = "Timeline"
        case patterns = "Patterns"
        case insights = "Insights"
    }

    private var filteredPlacements: [PlacementLog] {
        guard let days = selectedTimeRange.days else { return allPlacements }
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        return allPlacements.filter { $0.placedAt >= startDate }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Picker
                    timeRangePicker

                    // Quick Stats
                    quickStatsSection

                    // Metric Picker
                    metricPicker

                    // Selected Metric View
                    selectedMetricView
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Analytics")
        }
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button(action: { selectedTimeRange = range }) {
                        Text(range.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedTimeRange == range
                                    ? Color.appAccent
                                    : Color.cardBackground
                            )
                            .foregroundColor(
                                selectedTimeRange == range
                                    ? .white
                                    : .textPrimary
                            )
                            .cornerRadius(20)
                    }
                }
            }
        }
    }

    // MARK: - Quick Stats

    private var quickStatsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Total Placements",
                value: "\(filteredPlacements.count)",
                icon: "list.bullet.clipboard",
                color: .blue
            )

            StatCard(
                title: "Unique Sites",
                value: "\(uniqueSitesCount)",
                icon: "mappin.and.ellipse",
                color: .green
            )

            StatCard(
                title: "Avg Days Between",
                value: String(format: "%.1f", averageDaysBetween),
                icon: "calendar",
                color: .orange
            )

            StatCard(
                title: "Most Used Site",
                value: mostUsedSite ?? "N/A",
                icon: "star.fill",
                color: .yellow
            )
        }
    }

    // MARK: - Metric Picker

    private var metricPicker: some View {
        Picker("Metric", selection: $selectedMetric) {
            ForEach(AnalyticsMetric.allCases, id: \.self) { metric in
                Text(metric.rawValue).tag(metric)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Selected Metric View

    @ViewBuilder
    private var selectedMetricView: some View {
        switch selectedMetric {
        case .siteUsage:
            SiteUsageChart(placements: filteredPlacements)
        case .timeline:
            TimelineChart(placements: filteredPlacements)
        case .patterns:
            PatternsView(placements: filteredPlacements)
        case .insights:
            InsightsView(placements: filteredPlacements)
        }
    }

    // MARK: - Computed Properties

    private var uniqueSitesCount: Int {
        Set(filteredPlacements.compactMap { $0.locationRawValue ?? $0.customSiteName }).count
    }

    private var averageDaysBetween: Double {
        guard filteredPlacements.count > 1 else { return 0 }

        let sortedPlacements = filteredPlacements.sorted { $0.placedAt < $1.placedAt }
        var totalDays = 0

        for i in 1..<sortedPlacements.count {
            let days = Calendar.current.dateComponents(
                [.day],
                from: sortedPlacements[i-1].placedAt,
                to: sortedPlacements[i].placedAt
            ).day ?? 0
            totalDays += days
        }

        return Double(totalDays) / Double(filteredPlacements.count - 1)
    }

    private var mostUsedSite: String? {
        let siteCounts = Dictionary(grouping: filteredPlacements) {
            $0.locationRawValue ?? $0.customSiteName ?? "Unknown"
        }.mapValues { $0.count }

        return siteCounts.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Site Usage Chart

struct SiteUsageChart: View {
    let placements: [PlacementLog]

    private var siteData: [(site: String, count: Int)] {
        let grouped = Dictionary(grouping: placements) {
            $0.locationRawValue ?? $0.customSiteName ?? "Unknown"
        }

        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Site Distribution")
                .font(.headline)
                .foregroundColor(.textPrimary)

            if #available(iOS 16.0, *) {
                Chart(siteData, id: \.site) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Site", item.site)
                    )
                    .foregroundStyle(Color.appAccent.gradient)
                    .annotation(position: .trailing) {
                        Text("\(item.count)")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
                .frame(height: CGFloat(siteData.count * 40 + 40))
                .chartXAxis(.hidden)
            } else {
                // Fallback for older iOS
                ForEach(siteData, id: \.site) { item in
                    HStack {
                        Text(item.site)
                            .font(.body)
                        Spacer()
                        Text("\(item.count)")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Timeline Chart

struct TimelineChart: View {
    let placements: [PlacementLog]

    private var dailyData: [(date: Date, count: Int)] {
        let grouped = Dictionary(grouping: placements) { placement in
            Calendar.current.startOfDay(for: placement.placedAt)
        }

        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Placements Over Time")
                .font(.headline)
                .foregroundColor(.textPrimary)

            if #available(iOS 16.0, *), !dailyData.isEmpty {
                Chart(dailyData, id: \.date) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(Color.appAccent)

                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(Color.appAccent)
                }
                .frame(height: 200)
            } else {
                Text("No data to display")
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Patterns View

struct PatternsView: View {
    let placements: [PlacementLog]

    private var weekdayData: [(day: String, count: Int)] {
        let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        let grouped = Dictionary(grouping: placements) { placement in
            Calendar.current.component(.weekday, from: placement.placedAt) - 1
        }

        return weekdays.enumerated().map { index, day in
            (day, grouped[index]?.count ?? 0)
        }
    }

    private var hourlyData: [(hour: Int, count: Int)] {
        let grouped = Dictionary(grouping: placements) { placement in
            Calendar.current.component(.hour, from: placement.placedAt)
        }

        return (0..<24).map { hour in
            (hour, grouped[hour]?.count ?? 0)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Weekday Pattern
            VStack(alignment: .leading, spacing: 12) {
                Text("Day of Week Pattern")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                HStack(spacing: 4) {
                    ForEach(weekdayData, id: \.day) { item in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(barColor(for: item.count))
                                .frame(height: CGFloat(item.count * 10 + 10))

                            Text(item.day)
                                .font(.caption2)
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 80)
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)

            // Time of Day Pattern
            VStack(alignment: .leading, spacing: 12) {
                Text("Time of Day Pattern")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                HStack(spacing: 1) {
                    ForEach(hourlyData, id: \.hour) { item in
                        Rectangle()
                            .fill(heatmapColor(for: item.count))
                            .frame(height: 30)
                    }
                }
                .cornerRadius(4)

                HStack {
                    Text("12 AM")
                        .font(.caption2)
                    Spacer()
                    Text("12 PM")
                        .font(.caption2)
                    Spacer()
                    Text("11 PM")
                        .font(.caption2)
                }
                .foregroundColor(.textSecondary)
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
    }

    private func barColor(for count: Int) -> Color {
        if count == 0 { return Color.gray.opacity(0.2) }
        let maxCount = weekdayData.map(\.count).max() ?? 1
        let intensity = Double(count) / Double(maxCount)
        return Color.appAccent.opacity(0.3 + intensity * 0.7)
    }

    private func heatmapColor(for count: Int) -> Color {
        if count == 0 { return Color.gray.opacity(0.1) }
        let maxCount = hourlyData.map(\.count).max() ?? 1
        let intensity = Double(count) / Double(maxCount)
        return Color.appAccent.opacity(0.2 + intensity * 0.8)
    }
}

// MARK: - Insights View

struct InsightsView: View {
    let placements: [PlacementLog]

    private var insights: [Insight] {
        var result: [Insight] = []

        // Calculate various insights
        let siteCounts = Dictionary(grouping: placements) {
            $0.locationRawValue ?? $0.customSiteName ?? "Unknown"
        }.mapValues { $0.count }

        // Most used site
        if let mostUsed = siteCounts.max(by: { $0.value < $1.value }) {
            let percentage = Double(mostUsed.value) / Double(placements.count) * 100
            result.append(Insight(
                icon: "star.fill",
                title: "Most Used Site",
                description: "\(mostUsed.key) accounts for \(Int(percentage))% of your placements.",
                color: .yellow
            ))
        }

        // Least used sites
        if let leastUsed = siteCounts.min(by: { $0.value < $1.value }), leastUsed.value < 3 {
            result.append(Insight(
                icon: "exclamationmark.triangle",
                title: "Underutilized Site",
                description: "\(leastUsed.key) has only been used \(leastUsed.value) times. Consider rotating more.",
                color: .orange
            ))
        }

        // Streak insight
        let sortedPlacements = placements.sorted { $0.placedAt > $1.placedAt }
        var currentStreak = 0
        var lastDate: Date?

        for placement in sortedPlacements {
            let placementDay = Calendar.current.startOfDay(for: placement.placedAt)
            if let last = lastDate {
                let diff = Calendar.current.dateComponents([.day], from: placementDay, to: last).day ?? 0
                if diff <= 3 {
                    currentStreak += 1
                    lastDate = placementDay
                } else {
                    break
                }
            } else {
                currentStreak = 1
                lastDate = placementDay
            }
        }

        if currentStreak >= 3 {
            result.append(Insight(
                icon: "flame.fill",
                title: "Great Consistency!",
                description: "You've logged \(currentStreak) placements recently. Keep it up!",
                color: .red
            ))
        }

        // Rotation insight
        let uniqueSites = Set(siteCounts.keys).count
        if uniqueSites >= 6 {
            result.append(Insight(
                icon: "checkmark.circle.fill",
                title: "Excellent Rotation",
                description: "You're using \(uniqueSites) different sites. Great job rotating!",
                color: .green
            ))
        }

        return result
    }

    var body: some View {
        VStack(spacing: 12) {
            if insights.isEmpty {
                Text("Log more placements to see insights")
                    .foregroundColor(.textSecondary)
                    .padding()
            } else {
                ForEach(insights) { insight in
                    HStack(spacing: 12) {
                        Image(systemName: insight.icon)
                            .font(.title2)
                            .foregroundColor(insight.color)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(insight.title)
                                .font(.headline)
                                .foregroundColor(.textPrimary)

                            Text(insight.description)
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Insight Model

struct Insight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Preview

#Preview {
    AnalyticsDashboardView()
}
