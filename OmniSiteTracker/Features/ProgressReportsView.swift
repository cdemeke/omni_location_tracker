//
//  ProgressReportsView.swift
//  OmniSiteTracker
//
//  Generate and view progress reports
//

import SwiftUI
import SwiftData

struct ProgressReport: Identifiable {
    let id = UUID()
    let period: String
    let startDate: Date
    let endDate: Date
    let totalPlacements: Int
    let sitesUsed: Int
    let avgInterval: Double
    let symptoms: Int
    let complianceRate: Double
}

@MainActor
@Observable
final class ProgressReportManager {
    var reports: [ProgressReport] = []
    var isGenerating = false
    
    func generate(from placements: [PlacementLog], period: ReportPeriod) async {
        isGenerating = true
        try? await Task.sleep(for: .seconds(1))
        
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        let periodName: String
        
        switch period {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
            periodName = "Weekly"
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)!
            periodName = "Monthly"
        case .quarter:
            startDate = calendar.date(byAdding: .month, value: -3, to: now)!
            periodName = "Quarterly"
        }
        
        let filteredPlacements = placements.filter { $0.placedAt >= startDate }
        
        let report = ProgressReport(
            period: periodName,
            startDate: startDate,
            endDate: now,
            totalPlacements: filteredPlacements.count,
            sitesUsed: Set(filteredPlacements.map { $0.site }).count,
            avgInterval: 2.5,
            symptoms: 2,
            complianceRate: 0.92
        )
        
        reports.insert(report, at: 0)
        isGenerating = false
    }
    
    enum ReportPeriod: String, CaseIterable {
        case week = "Weekly"
        case month = "Monthly"
        case quarter = "Quarterly"
    }
}

struct ProgressReportsView: View {
    @Query private var placements: [PlacementLog]
    @State private var manager = ProgressReportManager()
    @State private var selectedPeriod: ProgressReportManager.ReportPeriod = .month
    
    var body: some View {
        List {
            Section {
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(ProgressReportManager.ReportPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                
                Button {
                    Task {
                        await manager.generate(from: placements, period: selectedPeriod)
                    }
                } label: {
                    HStack {
                        if manager.isGenerating {
                            ProgressView()
                        }
                        Text("Generate Report")
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(manager.isGenerating)
            }
            
            Section("Reports") {
                ForEach(manager.reports) { report in
                    NavigationLink {
                        ReportDetailView(report: report)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(report.period) Report")
                                .font(.headline)
                            Text("\(report.startDate.formatted(date: .abbreviated, time: .omitted)) - \(report.endDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Progress Reports")
    }
}

struct ReportDetailView: View {
    let report: ProgressReport
    
    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("Period", value: report.period)
                LabeledContent("Total Placements", value: "\(report.totalPlacements)")
                LabeledContent("Sites Used", value: "\(report.sitesUsed)")
            }
            
            Section("Metrics") {
                LabeledContent("Avg Interval", value: String(format: "%.1f days", report.avgInterval))
                LabeledContent("Symptoms Logged", value: "\(report.symptoms)")
                LabeledContent("Compliance Rate", value: String(format: "%.0f%%", report.complianceRate * 100))
            }
            
            Section {
                Button("Export PDF") {}
                Button("Share Report") {}
            }
        }
        .navigationTitle("Report Details")
    }
}

#Preview {
    NavigationStack {
        ProgressReportsView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
