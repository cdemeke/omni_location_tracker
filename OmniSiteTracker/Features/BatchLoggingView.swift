//
//  BatchLoggingView.swift
//  OmniSiteTracker
//
//  Log multiple entries at once for catch-up
//

import SwiftUI
import SwiftData

struct BatchEntry: Identifiable {
    let id = UUID()
    var date: Date
    var site: String
    var notes: String
}

struct BatchLoggingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var entries: [BatchEntry] = []
    @State private var showingAddEntry = false
    
    private let sites = ["Left Arm", "Right Arm", "Left Thigh", "Right Thigh", "Abdomen Left", "Abdomen Right"]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach($entries) { $entry in
                        VStack(alignment: .leading, spacing: 8) {
                            DatePicker("Date", selection: $entry.date, displayedComponents: [.date, .hourAndMinute])
                            
                            Picker("Site", selection: $entry.site) {
                                ForEach(sites, id: \.self) { site in
                                    Text(site).tag(site)
                                }
                            }
                            
                            TextField("Notes (optional)", text: $entry.notes)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        entries.remove(atOffsets: indexSet)
                    }
                    
                    Button {
                        entries.append(BatchEntry(date: Date(), site: sites[0], notes: ""))
                    } label: {
                        Label("Add Entry", systemImage: "plus")
                    }
                }
                
                if !entries.isEmpty {
                    Section {
                        Button("Save All (\(entries.count) entries)") {
                            saveAll()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Batch Logging")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func saveAll() {
        for entry in entries {
            let log = PlacementLog(
                site: entry.site,
                placedAt: entry.date,
                notes: entry.notes
            )
            modelContext.insert(log)
        }
        dismiss()
    }
}

#Preview {
    BatchLoggingView()
        .modelContainer(for: PlacementLog.self, inMemory: true)
}
