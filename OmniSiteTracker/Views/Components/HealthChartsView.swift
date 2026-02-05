//
//  HealthChartsView.swift
//  OmniSiteTracker
//
//  Interactive health charts showing glucose trends
//  correlated with pump site changes.
//

import SwiftUI
import Charts
import HealthKit

// MARK: - Health Charts View

@available(iOS 16.0, *)
struct HealthChartsView: View {
    @State private var selectedTimeRange: TimeRange = .week
    @State private var glucoseData: [GlucoseReading] = []
    @State private var placementMarkers: [PlacementMarker] = []
    @State private var isLoading = true
    @State private var selectedReading: GlucoseReading?

    enum TimeRange: String, CaseIterable {
        case day = "24h"
        case week = "7 Days"
        case month = "30 Days"

        var hours: Int {
            switch self {
            case .day: return 24
            case .week: return 168
            case .month: return 720
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time range picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedTimeRange) { _, _ in
                    loadData()
                }

                // Main glucose chart
                if isLoading {
                    ProgressView("Loading health data...")
                        .frame(height: 300)
                } else if glucoseData.isEmpty {
                    EmptyHealthDataView()
                } else {
                    GlucoseChartCard(
                        data: glucoseData,
                        placements: placementMarkers,
                        selectedReading: $selectedReading
                    )

                    // Statistics cards
                    StatisticsSection(data: glucoseData)

                    // Site correlation chart
                    SiteCorrelationChart(
                        glucoseData: glucoseData,
                        placements: placementMarkers
                    )
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Health Charts")
        .onAppear {
            loadData()
        }
    }

    private func loadData() {
        isLoading = true

        // Generate sample data for demonstration
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -selectedTimeRange.hours, to: now) ?? now

        // Generate glucose readings
        var readings: [GlucoseReading] = []
        var currentDate = startDate

        while currentDate <= now {
            let baseValue = 120.0
            let variation = Double.random(in: -40...60)
            let hourOfDay = Calendar.current.component(.hour, from: currentDate)
            let mealEffect = (hourOfDay == 8 || hourOfDay == 13 || hourOfDay == 19) ? Double.random(in: 20...50) : 0

            readings.append(GlucoseReading(
                date: currentDate,
                value: baseValue + variation + mealEffect
            ))

            currentDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? now
        }

        glucoseData = readings

        // Generate placement markers
        var markers: [PlacementMarker] = []
        var markerDate = startDate

        while markerDate <= now {
            markers.append(PlacementMarker(
                date: markerDate,
                siteName: ["Abdomen Left", "Abdomen Right", "Left Thigh", "Right Thigh"].randomElement() ?? "Abdomen Left"
            ))
            markerDate = Calendar.current.date(byAdding: .day, value: 3, to: markerDate) ?? now
        }

        placementMarkers = markers
        isLoading = false
    }
}

// MARK: - Glucose Chart Card

@available(iOS 16.0, *)
struct GlucoseChartCard: View {
    let data: [GlucoseReading]
    let placements: [PlacementMarker]
    @Binding var selectedReading: GlucoseReading?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Blood Glucose")
                    .font(.headline)

                Spacer()

                if let selected = selectedReading {
                    VStack(alignment: .trailing) {
                        Text("\(Int(selected.value)) mg/dL")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(selected.date, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Chart {
                // Glucose line
                ForEach(data) { reading in
                    LineMark(
                        x: .value("Time", reading.date),
                        y: .value("Glucose", reading.value)
                    )
                    .foregroundStyle(glucoseColor(for: reading.value).gradient)
                    .interpolationMethod(.catmullRom)
                }

                // Target range
                RectangleMark(
                    xStart: .value("Start", data.first?.date ?? .now),
                    xEnd: .value("End", data.last?.date ?? .now),
                    yStart: .value("Low", 70),
                    yEnd: .value("High", 180)
                )
                .foregroundStyle(.green.opacity(0.1))

                // Placement markers
                ForEach(placements) { marker in
                    RuleMark(x: .value("Placement", marker.date))
                        .foregroundStyle(.purple.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .annotation(position: .top) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.purple)
                                .font(.caption)
                        }
                }
            }
            .frame(height: 250)
            .chartYScale(domain: 40...300)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [70, 120, 180, 250]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if let date: Date = proxy.value(atX: value.location.x) {
                                        selectedReading = data.min(by: {
                                            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                        })
                                    }
                                }
                                .onEnded { _ in
                                    selectedReading = nil
                                }
                        )
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func glucoseColor(for value: Double) -> Color {
        if value < 70 { return .red }
        if value > 180 { return .orange }
        return .green
    }
}

// MARK: - Statistics Section

struct StatisticsSection: View {
    let data: [GlucoseReading]

    private var average: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.value).reduce(0, +) / Double(data.count)
    }

    private var timeInRange: Double {
        guard !data.isEmpty else { return 0 }
        let inRange = data.filter { $0.value >= 70 && $0.value <= 180 }.count
        return Double(inRange) / Double(data.count) * 100
    }

    private var standardDeviation: Double {
        guard data.count > 1 else { return 0 }
        let mean = average
        let variance = data.map { pow($0.value - mean, 2) }.reduce(0, +) / Double(data.count - 1)
        return sqrt(variance)
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatBox(title: "Average", value: "\(Int(average))", unit: "mg/dL", color: .blue)
            StatBox(title: "Time in Range", value: "\(Int(timeInRange))%", unit: "", color: .green)
            StatBox(title: "Variability", value: String(format: "%.1f", standardDeviation), unit: "SD", color: .orange)
        }
        .padding(.horizontal)
    }
}

// MARK: - Site Correlation Chart

@available(iOS 16.0, *)
struct SiteCorrelationChart: View {
    let glucoseData: [GlucoseReading]
    let placements: [PlacementMarker]

    private var siteAverages: [(site: String, average: Double)] {
        var siteReadings: [String: [Double]] = [:]

        for (index, placement) in placements.enumerated() {
            let endDate = index < placements.count - 1 ? placements[index + 1].date : Date()

            let readings = glucoseData.filter {
                $0.date >= placement.date && $0.date < endDate
            }.map(\.value)

            if !readings.isEmpty {
                let existing = siteReadings[placement.siteName] ?? []
                siteReadings[placement.siteName] = existing + readings
            }
        }

        return siteReadings.map { site, readings in
            (site, readings.reduce(0, +) / Double(readings.count))
        }.sorted { $0.average < $1.average }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Average Glucose by Site")
                .font(.headline)

            if siteAverages.isEmpty {
                Text("Not enough data")
                    .foregroundColor(.secondary)
            } else {
                Chart(siteAverages, id: \.site) { item in
                    BarMark(
                        x: .value("Average", item.average),
                        y: .value("Site", item.site)
                    )
                    .foregroundStyle(item.average <= 140 ? Color.green.gradient : Color.orange.gradient)
                    .annotation(position: .trailing) {
                        Text("\(Int(item.average))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: CGFloat(siteAverages.count * 50 + 20))
                .chartXAxis(.hidden)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views

struct StatBox: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(8)
    }
}

struct EmptyHealthDataView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Health Data")
                .font(.headline)

            Text("Enable HealthKit integration in Settings to see glucose charts.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

// MARK: - Data Models

struct GlucoseReading: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct PlacementMarker: Identifiable {
    let id = UUID()
    let date: Date
    let siteName: String
}

// MARK: - Color Extension

extension Color {
    static let cardBackground = Color(uiColor: .secondarySystemBackground)
}

// MARK: - Preview

@available(iOS 16.0, *)
#Preview {
    NavigationStack {
        HealthChartsView()
    }
}
