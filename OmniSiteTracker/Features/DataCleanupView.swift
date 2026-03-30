//
//  DataCleanupView.swift
//  OmniSiteTracker
//
//  Tools for cleaning up old or invalid data
//

import SwiftUI
import SwiftData

struct DataCleanupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var placements: [PlacementLog]
    
    @State private var oldDataDays = 365
    @State private var showingDeleteConfirmation = false
    @State private var deletionType: DeletionType?
    @State private var isProcessing = false
    
    enum DeletionType {
        case old, duplicates, empty
    }
    
    private var oldPlacements: [PlacementLog] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -oldDataDays, to: Date())!
        return placements.filter { $0.placedAt < cutoff }
    }
    
    private var placementsWithoutNotes: [PlacementLog] {
        placements.filter { $0.notes?.isEmpty ?? true }
    }
    
    var body: some View {
        List {
            Section("Storage") {
                LabeledContent("Total Records", value: "\(placements.count)")
                LabeledContent("Estimated Size", value: "\(placements.count * 2) KB")
            }
            
            Section("Remove Old Data") {
                Stepper("Older than \(oldDataDays) days", value: $oldDataDays, in: 30...730, step: 30)
                
                Button {
                    deletionType = .old
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Text("Delete \(oldPlacements.count) old records")
                        Spacer()
                        Image(systemName: "trash")
                    }
                }
                .foregroundStyle(.red)
                .disabled(oldPlacements.isEmpty)
            }
            
            Section("Cleanup Options") {
                Button {
                    deletionType = .duplicates
                    showingDeleteConfirmation = true
                } label: {
                    Label("Find & Remove Duplicates", systemImage: "doc.on.doc")
                }
                
                Button {
                    deletionType = .empty
                    showingDeleteConfirmation = true
                } label: {
                    Label("Remove Empty Entries", systemImage: "xmark.circle")
                }
            }
            
            Section {
                Button("Compact Database", role: .none) {
                    // Trigger database compaction
                }
            }
        }
        .navigationTitle("Data Cleanup")
        .alert("Confirm Deletion", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                performDeletion()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .overlay {
            if isProcessing {
                ProgressView("Processing...")
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func performDeletion() {
        isProcessing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            switch deletionType {
            case .old:
                for placement in oldPlacements {
                    modelContext.delete(placement)
                }
            case .duplicates, .empty, .none:
                break
            }
            isProcessing = false
        }
    }
}

#Preview {
    NavigationStack {
        DataCleanupView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
