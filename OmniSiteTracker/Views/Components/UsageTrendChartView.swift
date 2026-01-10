//
//  UsageTrendChartView.swift
//  OmniSiteTracker
//
//  Displays a bar chart showing placement frequency over time.
//  Uses Swift Charts framework with the app's earthy color palette.
//

import SwiftUI
import Charts

struct UsageTrendChartView: View {
    let trendData: [TrendDataPoint]

    var body: some View {
        VStack(spacing: 12) {
            if trendData.isEmpty || trendData.allSatisfy({ $0.count == 0 }) {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 32))
                        .foregroundColor(.textMuted)

                    Text("No placement data")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                // Bar chart
                Chart(trendData) { dataPoint in
                    BarMark(
                        x: .value("Date", dataPoint.date, unit: .day),
                        y: .value("Placements", dataPoint.count)
                    )
                    .foregroundStyle(barGradient)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartYScale(domain: 0...(maxCount + 1))
                .frame(height: 200)
            }
        }
        .padding(16)
        .neumorphicCard()
    }

    // MARK: - Computed Properties

    /// Maximum count in the data for chart scaling
    private var maxCount: Int {
        trendData.map { $0.count }.max() ?? 1
    }

    /// Gradient using app's earthy color palette
    private var barGradient: LinearGradient {
        LinearGradient(
            colors: [Color.appAccent, Color.appSecondary],
            startPoint: .bottom,
            endPoint: .top
        )
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let today = Date()

    let sampleData: [TrendDataPoint] = (0..<14).map { dayOffset in
        let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
        let count = Int.random(in: 0...5)
        return TrendDataPoint(date: date, count: count)
    }.reversed()

    return ScrollView {
        VStack(spacing: 24) {
            SectionHeader("Usage Trend")
            UsageTrendChartView(trendData: sampleData)
        }
        .padding()
    }
    .background(WarmGradientBackground())
}
