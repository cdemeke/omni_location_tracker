//
//  ExportHistoryView.swift
//  OmniSiteTracker
//
//  Track previous data exports
//

import SwiftUI

struct ExportRecord: Identifiable {
    let id = UUID()
    let date: Date
    let format: String
    let recordCount: Int
    let fileSize: String
    let destination: String
}

@MainActor
@Observable
final class ExportHistoryManager {
    var exports: [ExportRecord] = [
        ExportRecord(date: Date().addingTimeInterval(-86400), format: "CSV", recordCount: 156, fileSize: "24 KB", destination: "Files"),
        ExportRecord(date: Date().addingTimeInterval(-604800), format: "PDF", recordCount: 89, fileSize: "1.2 MB", destination: "Email"),
        ExportRecord(date: Date().addingTimeInterval(-1209600), format: "JSON", recordCount: 234, fileSize: "45 KB", destination: "iCloud")
    ]
    
    func deleteExport(_ export: ExportRecord) {
        exports.removeAll { $0.id == export.id }
    }
    
    func clearHistory() {
        exports.removeAll()
    }
}

struct ExportHistoryView: View {
    @State private var manager = ExportHistoryManager()
    
    var body: some View {
        List {
            if manager.exports.isEmpty {
                Section {
                    Text("No export history")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ForEach(manager.exports) { export in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(export.format)
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text(export.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack {
                                Label("\(export.recordCount) records", systemImage: "doc")
                                Spacer()
                                Label(export.fileSize, systemImage: "arrow.down.circle")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            
                            Label("Exported to \(export.destination)", systemImage: "folder")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            manager.deleteExport(manager.exports[index])
                        }
                    }
                }
                
                Section {
                    Button("Clear History", role: .destructive) {
                        manager.clearHistory()
                    }
                }
            }
        }
        .navigationTitle("Export History")
    }
}

#Preview {
    NavigationStack {
        ExportHistoryView()
    }
}
