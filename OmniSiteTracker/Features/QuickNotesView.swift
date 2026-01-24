//
//  QuickNotesView.swift
//  OmniSiteTracker
//
//  Quick note-taking for observations
//

import SwiftUI
import SwiftData

@Model
final class QuickNote {
    var id: UUID
    var content: String
    var createdAt: Date
    var isPinned: Bool
    var color: String
    
    init(content: String, color: String = "blue") {
        self.id = UUID()
        self.content = content
        self.createdAt = Date()
        self.isPinned = false
        self.color = color
    }
}

struct QuickNotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \QuickNote.createdAt, order: .reverse) private var notes: [QuickNote]
    @State private var newNoteContent = ""
    @State private var selectedColor = "blue"
    
    private let colors = ["blue", "green", "orange", "purple", "pink"]
    
    private var pinnedNotes: [QuickNote] {
        notes.filter { $0.isPinned }
    }
    
    private var unpinnedNotes: [QuickNote] {
        notes.filter { !$0.isPinned }
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Add a quick note...", text: $newNoteContent, axis: .vertical)
                        .lineLimit(3...6)
                    
                    HStack {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(colorFor(color))
                                .frame(width: 24, height: 24)
                                .overlay {
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .font(.caption)
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                        
                        Spacer()
                        
                        Button("Add") {
                            addNote()
                        }
                        .disabled(newNoteContent.isEmpty)
                    }
                }
            }
            
            if !pinnedNotes.isEmpty {
                Section("Pinned") {
                    ForEach(pinnedNotes) { note in
                        NoteRow(note: note)
                    }
                    .onDelete { indexSet in
                        deleteNotes(from: pinnedNotes, at: indexSet)
                    }
                }
            }
            
            Section("Notes") {
                ForEach(unpinnedNotes) { note in
                    NoteRow(note: note)
                }
                .onDelete { indexSet in
                    deleteNotes(from: unpinnedNotes, at: indexSet)
                }
            }
        }
        .navigationTitle("Quick Notes")
    }
    
    private func colorFor(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
    
    private func addNote() {
        let note = QuickNote(content: newNoteContent, color: selectedColor)
        modelContext.insert(note)
        newNoteContent = ""
    }
    
    private func deleteNotes(from array: [QuickNote], at indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(array[index])
        }
    }
}

struct NoteRow: View {
    @Bindable var note: QuickNote
    
    var body: some View {
        HStack(alignment: .top) {
            Circle()
                .fill(colorFor(note.color))
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(note.content)
                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                note.isPinned.toggle()
            } label: {
                Image(systemName: note.isPinned ? "pin.fill" : "pin")
                    .foregroundStyle(note.isPinned ? .orange : .secondary)
            }
        }
    }
    
    private func colorFor(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
}

#Preview {
    NavigationStack {
        QuickNotesView()
    }
    .modelContainer(for: QuickNote.self, inMemory: true)
}
