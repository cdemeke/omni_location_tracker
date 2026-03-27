//
//  AccessibleChartView.swift
//  OmniSiteTracker
//
//  Provides accessible alternatives to visual charts.
//  Offers text-based data summaries for VoiceOver users.
//

import SwiftUI

/// Accessible text-based alternative to visual charts
struct AccessibleChartView: View {
    let title: String
    let data: [AccessibleDataPoint]
    let summary: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expandedItem: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text(title)
                .font(.headline)
                .foregroundColor(.textPrimary)
                .accessibilityAddTraits(.isHeader)

            // Summary for quick overview
            Text(summary)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .accessibilityLabel("Summary: \(summary)")

            // Data list
            VStack(spacing: 8) {
                ForEach(data) { item in
                    AccessibleDataRow(
                        item: item,
                        isExpanded: expandedItem == item.id,
                        onToggle: {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                                expandedItem = expandedItem == item.id ? nil : item.id
                            }
                        }
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title) chart with \(data.count) data points")
    }
}

/// A single data point for accessible chart
struct AccessibleDataPoint: Identifiable {
    let id: String
    let label: String
    let value: Double
    let formattedValue: String
    let percentage: Double?
    let details: String?
    let trend: Trend?

    enum Trend: String {
        case up = "increasing"
        case down = "decreasing"
        case stable = "stable"

        var iconName: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .stable: return "minus"
            }
        }

        var accessibilityDescription: String {
            rawValue
        }
    }

    init(
        id: String? = nil,
        label: String,
        value: Double,
        formattedValue: String? = nil,
        percentage: Double? = nil,
        details: String? = nil,
        trend: Trend? = nil
    ) {
        self.id = id ?? UUID().uuidString
        self.label = label
        self.value = value
        self.formattedValue = formattedValue ?? String(format: "%.1f", value)
        self.percentage = percentage
        self.details = details
        self.trend = trend
    }
}

/// Row displaying a single data point with accessibility
struct AccessibleDataRow: View {
    let item: AccessibleDataPoint
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 8) {
                // Main row
                HStack {
                    // Label
                    Text(item.label)
                        .font(.body)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    // Value
                    Text(item.formattedValue)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)

                    // Percentage if available
                    if let percentage = item.percentage {
                        Text("(\(Int(percentage))%)")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    // Trend indicator
                    if let trend = item.trend {
                        Image(systemName: trend.iconName)
                            .font(.caption)
                            .foregroundColor(trendColor(for: trend))
                    }

                    // Expand/collapse indicator
                    if item.details != nil {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                // Visual bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                            .cornerRadius(4)

                        Rectangle()
                            .fill(Color.appAccent)
                            .frame(width: geometry.size.width * min(item.value / 100, 1), height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
                .accessibilityHidden(true)

                // Details when expanded
                if isExpanded, let details = item.details {
                    Text(details)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .padding(.top, 4)
                }
            }
            .padding(12)
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(item.details != nil ? "Double tap to expand for more details" : "")
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        var label = "\(item.label): \(item.formattedValue)"

        if let percentage = item.percentage {
            label += ", \(Int(percentage)) percent"
        }

        if let trend = item.trend {
            label += ", trend \(trend.accessibilityDescription)"
        }

        if isExpanded, let details = item.details {
            label += ". \(details)"
        }

        return label
    }

    private func trendColor(for trend: AccessibleDataPoint.Trend) -> Color {
        switch trend {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        }
    }
}

// MARK: - Accessible Summary Card

/// A summary card with accessible content
struct AccessibleSummaryCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String?
    let accessibilityHint: String?

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.appAccent)
                .accessibilityHidden(true)

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.textMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)" + (subtitle != nil ? ". \(subtitle!)" : ""))
        .accessibilityHint(accessibilityHint ?? "")
    }
}

// MARK: - Accessible Site Grid

/// Accessible grid showing all site statuses
struct AccessibleSiteGridView: View {
    let statuses: [AccessibleSiteStatus]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Site Status")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            // Summary
            let readyCount = statuses.filter { $0.statusText == "Ready" || $0.statusText == "Available" }.count
            Text("\(readyCount) of \(statuses.count) sites are ready to use")
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            // List of sites
            ForEach(statuses, id: \.siteName) { status in
                HStack {
                    // Status indicator
                    Circle()
                        .fill(statusColor(for: status))
                        .frame(width: 12, height: 12)
                        .accessibilityHidden(true)

                    // Site name
                    Text(status.siteName)
                        .font(.body)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    // Status text
                    Text(status.statusText)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(for: status).opacity(0.2))
                        .cornerRadius(8)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(status.description)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    private func statusColor(for status: AccessibleSiteStatus) -> Color {
        switch status.statusText {
        case "Ready", "Available":
            return .green
        case "Resting":
            return .orange
        default:
            return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        AccessibleChartView(
            title: "Site Usage",
            data: [
                AccessibleDataPoint(label: "Abdomen Right", value: 25, percentage: 25, trend: .up),
                AccessibleDataPoint(label: "Left Thigh", value: 20, percentage: 20, trend: .stable),
                AccessibleDataPoint(label: "Abdomen Left", value: 15, percentage: 15, trend: .down)
            ],
            summary: "3 sites used in the last 30 days"
        )

        AccessibleSummaryCard(
            icon: "flame.fill",
            title: "Current Streak",
            value: "7",
            subtitle: "days",
            accessibilityHint: nil
        )
    }
    .padding()
    .background(Color.appBackground)
}
