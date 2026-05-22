//
//  QuickStatsWidgetView.swift
//  OmniSiteTracker
//
//  At-a-glance statistics widget
//

import SwiftUI
import SwiftData

struct QuickStatsWidgetView: View {
    @Query private var placements: [PlacementLog]
    
    private var todayCount: Int {
        placements.filter { Calendar.current.isDateInToday($0.placedAt) }.count
    }
    
    private var weekCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return placements.filter { $0.placedAt >= weekAgo }.count
    }
    
    private var lastSite: String? {
        placements.max(by: { $0.placedAt < $1.placedAt })?.site
    }
    
    private var daysSinceLastLog: Int {
        guard let last = placements.max(by: { $0.placedAt < $1.placedAt }) else { return 0 }
        return Calendar.current.dateComponents([.day], from: last.placedAt, to: Date()).day ?? 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                QuickStatCard(
                    title: "Today",
                    value: "\(todayCount)",
                    icon: "calendar",
                    color: .blue
                )
                
                QuickStatCard(
                    title: "This Week",
                    value: "\(weekCount)",
                    icon: "calendar.badge.clock",
                    color: .green
                )
            }
            
            HStack(spacing: 16) {
                QuickStatCard(
                    title: "Last Site",
                    value: lastSite ?? "None",
                    icon: "mappin",
                    color: .orange
                )
                
                QuickStatCard(
                    title: "Days Ago",
                    value: "\(daysSinceLastLog)",
                    icon: "clock",
                    color: .purple
                )
            }
            
            if daysSinceLastLog >= 3 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Time for a new placement!")
                        .font(.caption)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    QuickStatsWidgetView()
        .modelContainer(for: PlacementLog.self, inMemory: true)
}
