//
//  ExportFormatsView.swift
//  OmniSiteTracker
//
//  Export data in multiple formats
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum ExportFormat: String, CaseIterable, Identifiable {
    case csv = "CSV"
    case json = "JSON"
    case pdf = "PDF"
    case excel = "Excel"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .csv: return "tablecells"
        case .json: return "curlybraces"
        case .pdf: return "doc.richtext"
        case .excel: return "chart.bar.doc.horizontal"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        case .pdf: return "pdf"
        case .excel: return "xlsx"
        }
    }
}

struct ExportFormatsView: View {
    @Query private var placements: [PlacementLog]
    @State private var selectedFormat: ExportFormat = .csv
    @State private var includePhotos = false
    @State private var dateRange: ClosedRange<Date> = Date().addingTimeInterval(-30*24*60*60)...Date()
    @State private var isExporting = false
    @State private var exportURL: URL?
    
    var body: some View {
        List {
            Section("Format") {
                ForEach(ExportFormat.allCases) { format in
                    Button {
                        selectedFormat = format
                    } label: {
                        HStack {
                            Image(systemName: format.icon)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text(format.rawValue)
                                    .foregroundStyle(.primary)
                                Text(".\(format.fileExtension) file")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedFormat == format {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            
            Section("Options") {
                Toggle("Include Photos", isOn: $includePhotos)
                    .disabled(selectedFormat == .csv || selectedFormat == .json)
            }
            
            Section("Preview") {
                Text("\(placements.count) entries to export")
                Text("Format: \(selectedFormat.rawValue)")
            }
            
            Section {
                Button {
                    exportData()
                } label: {
                    if isExporting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Export as \(selectedFormat.rawValue)")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isExporting || placements.isEmpty)
            }
        }
        .navigationTitle("Export Data")
    }
    
    private func exportData() {
        isExporting = true
        
        Task {
            try? await Task.sleep(for: .seconds(1))
            
            // Generate export file based on format
            let content: String
            switch selectedFormat {
            case .csv:
                content = generateCSV()
            case .json:
                content = generateJSON()
            default:
                content = ""
            }
            
            // In a real app, save to file and present share sheet
            isExporting = false
        }
    }
    
    private func generateCSV() -> String {
        var csv = "Date,Site,Notes
"
        for placement in placements {
            csv += "\(placement.placedAt),\(placement.site),\(placement.notes ?? "")
"
        }
        return csv
    }
    
    private func generateJSON() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = placements.map { ["date": $0.placedAt.ISO8601Format(), "site": $0.site] }
        if let jsonData = try? JSONEncoder().encode(data) {
            return String(data: jsonData, encoding: .utf8) ?? "[]"
        }
        return "[]"
    }
}

#Preview {
    NavigationStack {
        ExportFormatsView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
