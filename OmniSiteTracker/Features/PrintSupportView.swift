//
//  PrintSupportView.swift
//  OmniSiteTracker
//
//  Print reports and logs
//

import SwiftUI
import SwiftData

struct PrintSupportView: View {
    @Query private var placements: [PlacementLog]
    @State private var selectedFormat: PrintFormat = .summary
    @State private var dateRange: DateRangeOption = .month
    @State private var includeCharts = true
    @State private var includeNotes = true
    
    enum PrintFormat: String, CaseIterable {
        case summary = "Summary Report"
        case detailed = "Detailed Log"
        case calendar = "Calendar View"
    }
    
    enum DateRangeOption: String, CaseIterable {
        case week = "Last Week"
        case month = "Last Month"
        case quarter = "Last 3 Months"
        case year = "Last Year"
        case all = "All Time"
    }
    
    var body: some View {
        List {
            Section("Report Type") {
                Picker("Format", selection: $selectedFormat) {
                    ForEach(PrintFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section("Date Range") {
                Picker("Range", selection: $dateRange) {
                    ForEach(DateRangeOption.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
            }
            
            Section("Options") {
                Toggle("Include Charts", isOn: $includeCharts)
                Toggle("Include Notes", isOn: $includeNotes)
            }
            
            Section("Preview") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("OmniSite Tracker Report")
                        .font(.headline)
                    Text(selectedFormat.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(placements.count) entries")
                        .font(.caption)
                }
                .padding(.vertical, 8)
            }
            
            Section {
                Button {
                    printReport()
                } label: {
                    HStack {
                        Image(systemName: "printer")
                        Text("Print Report")
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Button {
                    // Share as PDF
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share as PDF")
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Print")
    }
    
    private func printReport() {
        // In production, generate printable content
    }
}

#Preview {
    NavigationStack {
        PrintSupportView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
