//
//  LocationBreakdownChartView.swift
//  OmniSiteTracker
//
//  Displays a stacked bar chart showing usage breakdown by location over time.
//  Uses Swift Charts framework with distinct colors for each body location.
//

import SwiftUI
import Charts

struct LocationBreakdownChartView: View {
    let locationTrendData: [BodyLocation: [TrendDataPoint]]

    var body: some View {
        VStack(spacing: 16) {
            if hasData {
                // Stacked bar chart
                Chart {
                    ForEach(BodyLocation.allCases, id: \.self) { location in
                        if let dataPoints = locationTrendData[location] {
                            ForEach(dataPoints) { dataPoint in
                                BarMark(
                                    x: .value("Date", dataPoint.date, unit: .day),
                                    y: .value("Placements", dataPoint.count)
                                )
                                .foregroundStyle(by: .value("Location", location.shortName))
                            }
                        }
                    }
                }
                .chartForegroundStyleScale(locationColorMapping)
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
                .chartLegend(position: .bottom, alignment: .center, spacing: 12)
                .frame(height: 250)

            } else {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 32))
                        .foregroundColor(.textMuted)

                    Text("No location data")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .frame(height: 250)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .neumorphicCard()
    }

    // MARK: - Computed Properties

    /// Check if there's any data to display
    private var hasData: Bool {
        for (_, dataPoints) in locationTrendData {
            if dataPoints.contains(where: { $0.count > 0 }) {
                return true
            }
        }
        return false
    }

    /// Color mapping for each body location using the app's earthy color palette
    private var locationColorMapping: KeyValuePairs<String, Color> {
        [
            BodyLocation.leftArm.shortName: Color.appAccent,
            BodyLocation.rightArm.shortName: Color.appSecondary,
            BodyLocation.abdomenLeft.shortName: Color.appSuccess,
            BodyLocation.abdomenRight.shortName: Color.appInfo,
            BodyLocation.lowerAbdomen.shortName: Color.appWarning,
            BodyLocation.leftThigh.shortName: Color.appHighlight,
            BodyLocation.rightThigh.shortName: Color(red: 0.65, green: 0.55, blue: 0.75),
            BodyLocation.leftLowerBack.shortName: Color(red: 0.55, green: 0.65, blue: 0.60),
            BodyLocation.rightLowerBack.shortName: Color(red: 0.60, green: 0.55, blue: 0.65)
        ]
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            SectionHeader("Location Breakdown")
            LocationBreakdownChartView(locationTrendData: Dictionary(uniqueKeysWithValues: BodyLocation.allCases.map { location in
                (location, (0..<14).reversed().map { dayOffset in
                    TrendDataPoint(
                        date: Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date(),
                        count: Int.random(in: 0...2),
                        location: location
                    )
                })
            }))
        }
        .padding()
    }
    .background(WarmGradientBackground())
}
