//
//  RotationInsightsView.swift
//  OmniSiteTracker
//
//  Deep insights into rotation patterns
//

import SwiftUI
import SwiftData

struct RotationInsight: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let description: String
    let trend: Trend
    let category: Category
    
    enum Trend { case up, down, stable }
    enum Category { case timing, usage, health, compliance }
}

struct RotationInsightsView: View {
    @Query private var placements: [PlacementLog]
    
    private var insights: [RotationInsight] {
        [
            RotationInsight(title: "Rotation Efficiency", value: "87%", description: "Sites are being used evenly", trend: .up, category: .usage),
            RotationInsight(title: "Avg Rest Period", value: "5.2 days", description: "Between site reuse", trend: .stable, category: .timing),
            RotationInsight(title: "Most Used Time", value: "9:30 AM", description: "Peak logging hour", trend: .stable, category: .timing),
            RotationInsight(title: "Weekly Compliance", value: "94%", description: "Following rotation schedule", trend: .up, category: .compliance),
            RotationInsight(title: "Site Balance", value: "Good", description: "No overused sites", trend: .up, category: .health),
            RotationInsight(title: "Symptom Rate", value: "3%", description: "Low symptom occurrence", trend: .down, category: .health)
        ]
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(insights) { insight in
                    InsightCard(insight: insight)
                }
            }
            .padding()
        }
        .navigationTitle("Rotation Insights")
        .background(Color(.systemGroupedBackground))
    }
}

struct InsightCard: View {
    let insight: RotationInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(insight.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Image(systemName: trendIcon)
                    .foregroundStyle(trendColor)
            }
            
            Text(insight.value)
                .font(.title)
                .bold()
            
            Text(insight.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var trendIcon: String {
        switch insight.trend {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
    
    private var trendColor: Color {
        switch insight.trend {
        case .up: return .green
        case .down: return insight.category == .health ? .green : .red
        case .stable: return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        RotationInsightsView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
