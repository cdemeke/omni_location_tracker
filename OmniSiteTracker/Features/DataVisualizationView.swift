//
//  DataVisualizationView.swift
//  OmniSiteTracker
//
//  Advanced charts and visualizations
//

import SwiftUI
import Charts

struct SiteUsageData: Identifiable {
    let id = UUID()
    let site: String
    let count: Int
    let month: String
}

struct HealingTimeData: Identifiable {
    let id = UUID()
    let site: String
    let days: Double
}

@available(iOS 16.0, *)
struct DataVisualizationView: View {
    @State private var selectedChart = 0
    
    private let siteUsage: [SiteUsageData] = [
        SiteUsageData(site: "Left Arm", count: 12, month: "Jan"),
        SiteUsageData(site: "Right Arm", count: 8, month: "Jan"),
        SiteUsageData(site: "Left Thigh", count: 10, month: "Jan"),
        SiteUsageData(site: "Right Thigh", count: 11, month: "Jan"),
        SiteUsageData(site: "Abdomen", count: 9, month: "Jan")
    ]
    
    private let healingTimes: [HealingTimeData] = [
        HealingTimeData(site: "Left Arm", days: 5.2),
        HealingTimeData(site: "Right Arm", days: 4.8),
        HealingTimeData(site: "Left Thigh", days: 6.1),
        HealingTimeData(site: "Right Thigh", days: 5.5),
        HealingTimeData(site: "Abdomen", days: 4.2)
    ]
    
    var body: some View {
        List {
            Section {
                Picker("Chart Type", selection: $selectedChart) {
                    Text("Usage").tag(0)
                    Text("Healing").tag(1)
                }
                .pickerStyle(.segmented)
            }
            
            Section {
                if selectedChart == 0 {
                    Chart(siteUsage) { data in
                        BarMark(
                            x: .value("Site", data.site),
                            y: .value("Count", data.count)
                        )
                        .foregroundStyle(by: .value("Site", data.site))
                    }
                    .frame(height: 250)
                    .chartLegend(.hidden)
                } else {
                    Chart(healingTimes) { data in
                        BarMark(
                            x: .value("Days", data.days),
                            y: .value("Site", data.site)
                        )
                        .foregroundStyle(.orange.gradient)
                    }
                    .frame(height: 250)
                }
            }
            
            Section("Insights") {
                if selectedChart == 0 {
                    Label("Left Arm is your most used site", systemImage: "star.fill")
                    Label("Right Arm could use more rotation", systemImage: "arrow.triangle.2.circlepath")
                } else {
                    Label("Abdomen heals fastest on average", systemImage: "bandage.fill")
                    Label("Left Thigh may need longer rest periods", systemImage: "clock.fill")
                }
            }
        }
        .navigationTitle("Visualizations")
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        NavigationStack {
            DataVisualizationView()
        }
    }
}
