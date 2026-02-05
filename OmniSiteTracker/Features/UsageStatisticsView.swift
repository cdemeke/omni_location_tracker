//
//  UsageStatisticsView.swift
//  OmniSiteTracker
//
//  Detailed app usage statistics
//

import SwiftUI
import SwiftData

struct UsageStatisticsView: View {
    @Query private var placements: [PlacementLog]
    
    private var totalPlacements: Int { placements.count }
    private var uniqueSites: Int { Set(placements.map { $0.site }).count }
    private var firstLog: Date? { placements.min(by: { $0.placedAt < $1.placedAt })?.placedAt }
    private var lastLog: Date? { placements.max(by: { $0.placedAt < $1.placedAt })?.placedAt }
    
    private var daysTracking: Int {
        guard let first = firstLog else { return 0 }
        return Calendar.current.dateComponents([.day], from: first, to: Date()).day ?? 0
    }
    
    private var logsPerWeek: Double {
        guard daysTracking > 0 else { return 0 }
        return Double(totalPlacements) / (Double(daysTracking) / 7.0)
    }
    
    var body: some View {
        List {
            Section("Overview") {
                StatRow(label: "Total Placements", value: "\(totalPlacements)")
                StatRow(label: "Unique Sites Used", value: "\(uniqueSites)")
                StatRow(label: "Days Tracking", value: "\(daysTracking)")
                StatRow(label: "Avg per Week", value: String(format: "%.1f", logsPerWeek))
            }
            
            Section("Timeline") {
                if let first = firstLog {
                    StatRow(label: "First Log", value: first.formatted(date: .abbreviated, time: .omitted))
                }
                if let last = lastLog {
                    StatRow(label: "Last Log", value: last.formatted(date: .abbreviated, time: .omitted))
                }
            }
            
            Section("By Site") {
                ForEach(siteStats, id: \.0) { stat in
                    HStack {
                        Text(stat.0)
                        Spacer()
                        Text("\(stat.1)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Statistics")
    }
    
    private var siteStats: [(String, Int)] {
        var counts: [String: Int] = [:]
        for placement in placements {
            counts[placement.site, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        UsageStatisticsView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
