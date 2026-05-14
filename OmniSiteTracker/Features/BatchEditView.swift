//
//  BatchEditView.swift
//  OmniSiteTracker
//
//  Edit multiple log entries at once
//

import SwiftUI
import SwiftData

struct BatchEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlacementLog.placedAt, order: .reverse) private var placements: [PlacementLog]
    
    @State private var selectedIds: Set<UUID> = []
    @State private var isSelecting = false
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        List {
            Section {
                if isSelecting {
                    HStack {
                        Button("Select All") {
                            selectedIds = Set(placements.map { $0.id })
                        }
                        
                        Spacer()
                        
                        Button("Clear") {
                            selectedIds.removeAll()
                        }
                    }
                }
            }
            
            Section("Entries (\(selectedIds.count) selected)") {
                ForEach(placements) { placement in
                    HStack {
                        if isSelecting {
                            Image(systemName: selectedIds.contains(placement.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedIds.contains(placement.id) ? .blue : .secondary)
                                .onTapGesture {
                                    if selectedIds.contains(placement.id) {
                                        selectedIds.remove(placement.id)
                                    } else {
                                        selectedIds.insert(placement.id)
                                    }
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(placement.site)
                                .font(.headline)
                            Text(placement.placedAt.formatted())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isSelecting {
                            if selectedIds.contains(placement.id) {
                                selectedIds.remove(placement.id)
                            } else {
                                selectedIds.insert(placement.id)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Batch Edit")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(isSelecting ? "Done" : "Select") {
                    isSelecting.toggle()
                    if !isSelecting {
                        selectedIds.removeAll()
                    }
                }
            }
            
            if isSelecting && !selectedIds.isEmpty {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Spacer()
                        
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            BatchEditOptionsView(selectedCount: selectedIds.count)
        }
        .alert("Delete \(selectedIds.count) entries?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteSelected()
            }
        }
    }
    
    private func deleteSelected() {
        for placement in placements where selectedIds.contains(placement.id) {
            modelContext.delete(placement)
        }
        selectedIds.removeAll()
        isSelecting = false
    }
}

struct BatchEditOptionsView: View {
    let selectedCount: Int
    @Environment(\.dismiss) private var dismiss
    
    @State private var newSite = ""
    @State private var addNotes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Editing \(selectedCount) entries")
                        .foregroundStyle(.secondary)
                }
                
                Section("Change Site") {
                    TextField("New site name", text: $newSite)
                }
                
                Section("Add Notes") {
                    TextField("Notes to append", text: $addNotes)
                }
            }
            .navigationTitle("Batch Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        // Apply changes
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        BatchEditView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
