//
//  SiteHeatmapView.swift
//  OmniSiteTracker
//
//  Visual heatmap of site usage
//

import SwiftUI
import SwiftData

struct SiteHeatmapView: View {
    @Query private var placements: [PlacementLog]
    
    private var siteUsage: [String: Int] {
        var usage: [String: Int] = [:]
        for placement in placements {
            usage[placement.site, default: 0] += 1
        }
        return usage
    }
    
    private var maxUsage: Int {
        siteUsage.values.max() ?? 1
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Legend
                HStack {
                    Text("Less")
                        .font(.caption)
                    
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(Double(i + 1) / 5.0))
                            .frame(width: 20, height: 20)
                    }
                    
                    Text("More")
                        .font(.caption)
                }
                .padding()
                
                // Heatmap grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(Array(siteUsage.keys.sorted()), id: \.self) { site in
                        HeatmapCell(
                            site: site,
                            count: siteUsage[site] ?? 0,
                            maxCount: maxUsage
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Site Heatmap")
    }
}

struct HeatmapCell: View {
    let site: String
    let count: Int
    let maxCount: Int
    
    private var intensity: Double {
        guard maxCount > 0 else { return 0.1 }
        return Double(count) / Double(maxCount)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1 + intensity * 0.9))
                .frame(height: 80)
                .overlay {
                    Text("\(count)")
                        .font(.title)
                        .bold()
                        .foregroundStyle(intensity > 0.5 ? .white : .primary)
                }
            
            Text(site)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    NavigationStack {
        SiteHeatmapView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
