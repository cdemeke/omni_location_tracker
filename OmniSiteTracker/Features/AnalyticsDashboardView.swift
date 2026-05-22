//
//  AnalyticsDashboardView.swift
//  OmniSiteTracker
//
//  Comprehensive analytics dashboard for site usage
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let change: Double?
    let icon: String
}

struct DailyUsage: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

@MainActor
@Observable
final class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private(set) var metrics: [AnalyticMetric] = []
    private(set) var dailyUsage: [DailyUsage] = []
    private(set) var siteDistribution: [String: Int] = [:]
    
    func calculateMetrics(from placements: [PlacementLog]) {
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let sixtyDaysAgo = Calendar.current.date(byAdding: .day, value: -60, to: now)!
        
        let recent = placements.filter { $0.placedAt >= thirtyDaysAgo }
        let previous = placements.filter { $0.placedAt >= sixtyDaysAgo && $0.placedAt < thirtyDaysAgo }
        
        let totalRotations = recent.count
        let previousRotations = previous.count
        let rotationChange = previousRotations > 0 ? Double(totalRotations - previousRotations) / Double(previousRotations) * 100 : 0
        
        let uniqueSites = Set(recent.map { $0.site }).count
        
        var avgDuration = 0.0
        if recent.count > 1 {
            let sorted = recent.sorted { $0.placedAt < $1.placedAt }
            var totalHours = 0.0
            for i in 1..<sorted.count {
                totalHours += sorted[i].placedAt.timeIntervalSince(sorted[i-1].placedAt) / 3600
            }
            avgDuration = totalHours / Double(sorted.count - 1)
        }
        
        let streakDays = calculateStreak(placements)
        
        metrics = [
            AnalyticMetric(title: "Total Rotations", value: "\(totalRotations)", change: rotationChange, icon: "arrow.triangle.2.circlepath"),
            AnalyticMetric(title: "Sites Used", value: "\(uniqueSites)", change: nil, icon: "mappin.and.ellipse"),
            AnalyticMetric(title: "Avg Duration", value: String(format: "%.1f hrs", avgDuration), change: nil, icon: "clock"),
            AnalyticMetric(title: "Current Streak", value: "\(streakDays) days", change: nil, icon: "flame")
        ]
        
        // Calculate daily usage
        var usage: [Date: Int] = [:]
        for placement in recent {
            let day = Calendar.current.startOfDay(for: placement.placedAt)
            usage[day, default: 0] += 1
        }
        dailyUsage = usage.map { DailyUsage(date: $0.key, count: $0.value) }.sorted { $0.date < $1.date }
        
        // Calculate site distribution
        siteDistribution = [:]
        for placement in recent {
            siteDistribution[placement.site, default: 0] += 1
        }
    }
    
    private func calculateStreak(_ placements: [PlacementLog]) -> Int {
        guard !placements.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        let dates = Set(placements.map { calendar.startOfDay(for: $0.placedAt) })
        
        while dates.contains(currentDate) {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        return streak
    }
}

@available(iOS 16.0, *)
struct AnalyticsDashboardView: View {
    @Query private var placements: [PlacementLog]
    @State private var analytics = AnalyticsManager.shared
    @State private var selectedTimeRange = 30
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Time Range", selection: $selectedTimeRange) {
                    Text("7D").tag(7)
                    Text("30D").tag(30)
                    Text("90D").tag(90)
                    Text("All").tag(365)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(analytics.metrics) { metric in
                        MetricCard(metric: metric)
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text("Daily Activity")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Chart(analytics.dailyUsage) { usage in
                        BarMark(
                            x: .value("Date", usage.date, unit: .day),
                            y: .value("Count", usage.count)
                        )
                        .foregroundStyle(.blue.gradient)
                    }
                    .frame(height: 200)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                VStack(alignment: .leading) {
                    Text("Site Distribution")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(Array(analytics.siteDistribution.keys.sorted()), id: \.self) { site in
                        SiteDistributionRow(site: site, count: analytics.siteDistribution[site] ?? 0, total: placements.count)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Analytics")
        .onAppear {
            analytics.calculateMetrics(from: placements)
        }
        .onChange(of: selectedTimeRange) { _, _ in
            analytics.calculateMetrics(from: placements)
        }
    }
}

struct MetricCard: View {
    let metric: AnalyticMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: metric.icon)
                    .foregroundStyle(.blue)
                Spacer()
                if let change = metric.change {
                    HStack(spacing: 2) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text(String(format: "%.0f%%", abs(change)))
                    }
                    .font(.caption)
                    .foregroundStyle(change >= 0 ? .green : .red)
                }
            }
            
            Text(metric.value)
                .font(.title2.bold())
            
            Text(metric.title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SiteDistributionRow: View {
    let site: String
    let count: Int
    let total: Int
    
    var percentage: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(site)
                    .font(.subheadline)
                Spacer()
                Text("\(count)")
                    .font(.subheadline.bold())
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.gradient)
                        .frame(width: geo.size.width * percentage)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        NavigationStack {
            AnalyticsDashboardView()
        }
        .modelContainer(for: PlacementLog.self, inMemory: true)
    }
}
