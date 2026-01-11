//
//  ZoneStatisticsListView.swift
//  OmniSiteTracker
//
//  Displays a ranked list of all body zones by usage count.
//  Shows each zone's icon, name, usage count, and a proportional usage bar.
//

import SwiftUI

struct ZoneStatisticsListView: View {
    let heatmapData: [HeatmapData]

    /// Sorted heatmap data by usage count (highest first)
    private var sortedData: [HeatmapData] {
        heatmapData.sorted { $0.usageCount > $1.usageCount }
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(sortedData) { data in
                ZoneStatisticsRow(data: data)
            }
        }
        .padding(16)
        .neumorphicCard()
    }
}

// MARK: - Zone Statistics Row

private struct ZoneStatisticsRow: View {
    let data: HeatmapData

    var body: some View {
        HStack(spacing: 12) {
            // Location icon with intensity-based color
            Image(systemName: data.location.iconName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(intensityColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(intensityColor.opacity(0.15))
                )

            // Zone name and usage count
            VStack(alignment: .leading, spacing: 4) {
                Text(data.location.shortName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)

                Text("\(data.usageCount) placements")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .frame(width: 100, alignment: .leading)

            Spacer()

            // Horizontal usage bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.appBackgroundSecondary)
                        .frame(height: 8)

                    // Filled portion based on intensity
                    RoundedRectangle(cornerRadius: 4)
                        .fill(intensityColor)
                        .frame(width: geometry.size.width * CGFloat(data.intensity), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(intensityColor.opacity(0.05))
        )
    }

    /// Calculates color based on intensity (0-1)
    /// Gray (0) -> Orange (0.5) -> Red (1.0)
    private var intensityColor: Color {
        if data.intensity <= 0 {
            return Color.gray
        } else if data.intensity <= 0.5 {
            // Gray to Orange transition (0 to 0.5)
            let t = data.intensity * 2 // Normalize to 0-1 range
            return Color(
                red: 0.5 + (0.5 * t),      // 0.5 -> 1.0
                green: 0.5 - (0.15 * t),   // 0.5 -> 0.35
                blue: 0.5 - (0.5 * t)      // 0.5 -> 0.0
            )
        } else {
            // Orange to Red transition (0.5 to 1.0)
            let t = (data.intensity - 0.5) * 2 // Normalize to 0-1 range
            return Color(
                red: 1.0,                  // Stay at 1.0
                green: 0.35 - (0.35 * t),  // 0.35 -> 0.0
                blue: 0.0                  // Stay at 0.0
            )
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        ZoneStatisticsListView(heatmapData: [
            HeatmapData(location: .abdomenLeft, usageCount: 10, intensity: 1.0, lastUsed: Date(), percentageOfTotal: 25),
            HeatmapData(location: .abdomenRight, usageCount: 8, intensity: 0.8, lastUsed: Date(), percentageOfTotal: 20),
            HeatmapData(location: .leftArm, usageCount: 6, intensity: 0.6, lastUsed: Date(), percentageOfTotal: 15),
            HeatmapData(location: .leftThigh, usageCount: 5, intensity: 0.5, lastUsed: Date(), percentageOfTotal: 12.5),
            HeatmapData(location: .rightArm, usageCount: 4, intensity: 0.4, lastUsed: Date(), percentageOfTotal: 10),
            HeatmapData(location: .rightThigh, usageCount: 3, intensity: 0.3, lastUsed: Date(), percentageOfTotal: 7.5),
            HeatmapData(location: .leftLowerBack, usageCount: 2, intensity: 0.2, lastUsed: Date(), percentageOfTotal: 2.5),
            HeatmapData(location: .rightLowerBack, usageCount: 2, intensity: 0.2, lastUsed: Date(), percentageOfTotal: 2.5),
            HeatmapData(location: .lowerAbdomen, usageCount: 2, intensity: 0.2, lastUsed: Date(), percentageOfTotal: 5),
        ])
        .padding()
    }
    .background(WarmGradientBackground())
}
