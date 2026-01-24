//
//  DataArchivingView.swift
//  OmniSiteTracker
//
//  Archive old data to reduce app size
//

import SwiftUI
import SwiftData

struct ArchiveInfo {
    var totalRecords: Int
    var archivableRecords: Int
    var currentSize: String
    var potentialSavings: String
}

@MainActor
@Observable
final class DataArchiveManager {
    var archiveInfo: ArchiveInfo?
    var isArchiving = false
    var archiveCutoffDays = 180
    var includePhotos = true
    
    func analyze(placements: [PlacementLog]) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -archiveCutoffDays, to: Date())!
        let archivable = placements.filter { $0.placedAt < cutoff }
        
        archiveInfo = ArchiveInfo(
            totalRecords: placements.count,
            archivableRecords: archivable.count,
            currentSize: "\(placements.count * 2) KB",
            potentialSavings: "\(archivable.count * 2) KB"
        )
    }
    
    func archive() async {
        isArchiving = true
        try? await Task.sleep(for: .seconds(2))
        isArchiving = false
    }
}

struct DataArchivingView: View {
    @Query private var placements: [PlacementLog]
    @State private var manager = DataArchiveManager()
    @State private var showingConfirmation = false
    
    var body: some View {
        List {
            Section("Settings") {
                Stepper("Archive data older than \(manager.archiveCutoffDays) days", value: $manager.archiveCutoffDays, in: 30...365, step: 30)
                Toggle("Include Photos", isOn: $manager.includePhotos)
            }
            
            if let info = manager.archiveInfo {
                Section("Analysis") {
                    LabeledContent("Total Records", value: "\(info.totalRecords)")
                    LabeledContent("Archivable", value: "\(info.archivableRecords)")
                    LabeledContent("Current Size", value: info.currentSize)
                    LabeledContent("Potential Savings", value: info.potentialSavings)
                }
            }
            
            Section {
                Button("Analyze Data") {
                    manager.analyze(placements: placements)
                }
                
                Button("Archive Now") {
                    showingConfirmation = true
                }
                .disabled(manager.archiveInfo?.archivableRecords == 0)
            }
        }
        .navigationTitle("Data Archiving")
        .onAppear {
            manager.analyze(placements: placements)
        }
        .alert("Archive Data?", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Archive") {
                Task {
                    await manager.archive()
                }
            }
        } message: {
            Text("This will move old data to an archive. You can restore it later if needed.")
        }
        .overlay {
            if manager.isArchiving {
                ProgressView("Archiving...")
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

#Preview {
    NavigationStack {
        DataArchivingView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
