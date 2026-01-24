//
//  SiteHistoryDetailView.swift
//  OmniSiteTracker
//
//  Detailed history for individual sites
//

import SwiftUI
import SwiftData

struct SiteHistoryDetailView: View {
    let siteName: String
    @Query private var allPlacements: [PlacementLog]
    
    private var sitePlacements: [PlacementLog] {
        allPlacements.filter { $0.site == siteName }.sorted { $0.placedAt > $1.placedAt }
    }
    
    private var totalUses: Int { sitePlacements.count }
    
    private var averageInterval: Double {
        guard sitePlacements.count > 1 else { return 0 }
        var intervals: [Double] = []
        for i in 0..<sitePlacements.count - 1 {
            let interval = sitePlacements[i].placedAt.timeIntervalSince(sitePlacements[i + 1].placedAt)
            intervals.append(interval / 86400)
        }
        return intervals.reduce(0, +) / Double(intervals.count)
    }
    
    private var lastUsed: Date? {
        sitePlacements.first?.placedAt
    }
    
    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("Total Uses", value: "\(totalUses)")
                LabeledContent("Avg Interval", value: String(format: "%.1f days", averageInterval))
                if let last = lastUsed {
                    LabeledContent("Last Used", value: last.formatted(date: .abbreviated, time: .shortened))
                }
            }
            
            Section("Usage by Month") {
                ForEach(usageByMonth, id: \.0) { month, count in
                    HStack {
                        Text(month)
                        Spacer()
                        Text("\(count)")
                            .foregroundStyle(.secondary)
                        ProgressView(value: Double(count), total: Double(maxMonthlyUsage))
                            .frame(width: 60)
                    }
                }
            }
            
            Section("History") {
                ForEach(sitePlacements.prefix(20)) { placement in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(placement.placedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.headline)
                        
                        if let notes = placement.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(siteName)
    }
    
    private var usageByMonth: [(String, Int)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        
        var counts: [String: Int] = [:]
        for placement in sitePlacements {
            let key = formatter.string(from: placement.placedAt)
            counts[key, default: 0] += 1
        }
        
        return counts.sorted { $0.key > $1.key }.prefix(6).map { ($0.key, $0.value) }
    }
    
    private var maxMonthlyUsage: Int {
        usageByMonth.map { $0.1 }.max() ?? 1
    }
}

#Preview {
    NavigationStack {
        SiteHistoryDetailView(siteName: "Left Arm")
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
