//
//  InsightsDashboardView.swift
//  OmniSiteTracker
//
//  AI-generated insights and recommendations
//

import SwiftUI
import SwiftData

struct Insight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: InsightType
    let actionLabel: String?
    
    enum InsightType {
        case positive, warning, info, action
        
        var icon: String {
            switch self {
            case .positive: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            case .action: return "arrow.right.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .warning: return .orange
            case .info: return .blue
            case .action: return .purple
            }
        }
    }
}

struct InsightsDashboardView: View {
    @Query private var placements: [PlacementLog]
    
    private var insights: [Insight] {
        [
            Insight(
                title: "Great rotation balance",
                description: "You have used all sites evenly this month",
                type: .positive,
                actionLabel: nil
            ),
            Insight(
                title: "Left arm needs rest",
                description: "Consider avoiding for 3 more days",
                type: .warning,
                actionLabel: "View alternatives"
            ),
            Insight(
                title: "Streak milestone approaching",
                description: "2 more days to reach 30-day streak",
                type: .info,
                actionLabel: nil
            ),
            Insight(
                title: "Time for next rotation",
                description: "Based on your schedule",
                type: .action,
                actionLabel: "Log now"
            )
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
        .navigationTitle("Insights")
        .background(Color(.systemGroupedBackground))
    }
}

struct InsightCard: View {
    let insight: Insight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: insight.type.icon)
                    .foregroundStyle(insight.type.color)
                    .font(.title2)
                
                Text(insight.title)
                    .font(.headline)
            }
            
            Text(insight.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let actionLabel = insight.actionLabel {
                Button(actionLabel) {}
                    .font(.subheadline)
                    .foregroundStyle(insight.type.color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        InsightsDashboardView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
