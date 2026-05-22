//
//  SiteNotesView.swift
//  OmniSiteTracker
//
//  Persistent notes for each site
//

import SwiftUI
import SwiftData

@Model
final class SiteNote {
    var id: UUID
    var siteName: String
    var content: String
    var updatedAt: Date
    var isPinned: Bool
    
    init(siteName: String, content: String) {
        self.id = UUID()
        self.siteName = siteName
        self.content = content
        self.updatedAt = Date()
        self.isPinned = false
    }
}

struct SiteNotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SiteNote.updatedAt, order: .reverse) private var notes: [SiteNote]
    @State private var showingAddNote = false
    
    private let sites = ["Left Arm", "Right Arm", "Left Thigh", "Right Thigh", "Abdomen Left", "Abdomen Right"]
    
    private func notesFor(_ site: String) -> [SiteNote] {
        notes.filter { $0.siteName == site }
    }
    
    var body: some View {
        List {
            ForEach(sites, id: \.self) { site in
                Section(site) {
                    let siteNotes = notesFor(site)
                    if siteNotes.isEmpty {
                        Button {
                            addNote(for: site)
                        } label: {
                            Label("Add Note", systemImage: "plus")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ForEach(siteNotes) { note in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.content)
                                    .lineLimit(3)
                                
                                Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                modelContext.delete(siteNotes[index])
                            }
                        }
                        
                        Button {
                            addNote(for: site)
                        } label: {
                            Label("Add Note", systemImage: "plus")
                        }
                    }
                }
            }
        }
        .navigationTitle("Site Notes")
        .sheet(isPresented: $showingAddNote) {
            AddSiteNoteView()
        }
    }
    
    private func addNote(for site: String) {
        let note = SiteNote(siteName: site, content: "")
        modelContext.insert(note)
    }
}

struct AddSiteNoteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSite = "Left Arm"
    @State private var content = ""
    
    private let sites = ["Left Arm", "Right Arm", "Left Thigh", "Right Thigh", "Abdomen Left", "Abdomen Right"]
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Site", selection: $selectedSite) {
                    ForEach(sites, id: \.self) { site in
                        Text(site).tag(site)
                    }
                }
                
                Section("Note") {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let note = SiteNote(siteName: selectedSite, content: content)
                        modelContext.insert(note)
                        dismiss()
                    }
                    .disabled(content.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SiteNotesView()
    }
    .modelContainer(for: SiteNote.self, inMemory: true)
}
