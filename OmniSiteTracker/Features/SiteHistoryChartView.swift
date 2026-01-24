//
//  SiteHistoryChartView.swift
//  OmniSiteTracker
//
//  Visual charts for site usage history
//

import SwiftUI
import SwiftData
import Charts

struct SiteUsagePoint: Identifiable {
    let id = UUID()
    let date: Date
    let site: String
    let count: Int
}

@available(iOS 16.0, *)
struct SiteHistoryChartView: View {
    @Query private var placements: [PlacementLog]
    @State private var selectedTimeRange = 30
    @State private var chartType = 0
    
    private var usageData: [SiteUsagePoint] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedTimeRange, to: Date())!
        let filtered = placements.filter { $0.placedAt >= cutoff }
        
        var data: [SiteUsagePoint] = []
        let sites = Set(filtered.map { $0.site })
        
        for site in sites {
            let count = filtered.filter { $0.site == site }.count
            data.append(SiteUsagePoint(date: Date(), site: site, count: count))
        }
        
        return data.sorted { $0.count > $1.count }
    }
    
    var body: some View {
        List {
            Section {
                Picker("Time Range", selection: $selectedTimeRange) {
                    Text("7 Days").tag(7)
                    Text("30 Days").tag(30)
                    Text("90 Days").tag(90)
                }
                .pickerStyle(.segmented)
            }
            
            Section {
                Picker("Chart Type", selection: $chartType) {
                    Text("Bar").tag(0)
                    Text("Pie").tag(1)
                }
                .pickerStyle(.segmented)
            }
            
            Section("Usage") {
                if chartType == 0 {
                    Chart(usageData) { point in
                        BarMark(
                            x: .value("Site", point.site),
                            y: .value("Count", point.count)
                        )
                        .foregroundStyle(by: .value("Site", point.site))
                    }
                    .frame(height: 250)
                    .chartLegend(.hidden)
                } else {
                    Chart(usageData) { point in
                        SectorMark(
                            angle: .value("Count", point.count),
                            innerRadius: .ratio(0.5),
                            angularInset: 1
                        )
                        .foregroundStyle(by: .value("Site", point.site))
                    }
                    .frame(height: 250)
                }
            }
            
            Section("Details") {
                ForEach(usageData) { point in
                    HStack {
                        Text(point.site)
                        Spacer()
                        Text("\(point.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Usage Charts")
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        NavigationStack {
            SiteHistoryChartView()
        }
        .modelContainer(for: PlacementLog.self, inMemory: true)
    }
}
