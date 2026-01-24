//
//  MedicalNotesView.swift
//  OmniSiteTracker
//
//  Store medical consultation notes
//

import SwiftUI
import SwiftData

@Model
final class MedicalNote {
    var id: UUID
    var title: String
    var content: String
    var doctorName: String?
    var appointmentDate: Date?
    var createdAt: Date
    var isPinned: Bool
    
    init(title: String, content: String, doctorName: String? = nil, appointmentDate: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.doctorName = doctorName
        self.appointmentDate = appointmentDate
        self.createdAt = Date()
        self.isPinned = false
    }
}

struct MedicalNotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MedicalNote.createdAt, order: .reverse) private var notes: [MedicalNote]
    @State private var showingAddNote = false
    
    private var pinnedNotes: [MedicalNote] { notes.filter { $0.isPinned } }
    private var unpinnedNotes: [MedicalNote] { notes.filter { !$0.isPinned } }
    
    var body: some View {
        List {
            if !pinnedNotes.isEmpty {
                Section("Pinned") {
                    ForEach(pinnedNotes) { note in
                        MedicalNoteRow(note: note)
                    }
                }
            }
            
            Section("Notes") {
                if unpinnedNotes.isEmpty && pinnedNotes.isEmpty {
                    Text("No medical notes yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(unpinnedNotes) { note in
                        MedicalNoteRow(note: note)
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    modelContext.delete(unpinnedNotes[index])
                }
            }
        }
        .navigationTitle("Medical Notes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddNote = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddNote) {
            AddMedicalNoteView()
        }
    }
}

struct MedicalNoteRow: View {
    @Bindable var note: MedicalNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.title)
                    .font(.headline)
                
                Spacer()
                
                Button {
                    note.isPinned.toggle()
                } label: {
                    Image(systemName: note.isPinned ? "pin.fill" : "pin")
                        .foregroundStyle(note.isPinned ? .orange : .secondary)
                }
            }
            
            Text(note.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            HStack {
                if let doctor = note.doctorName {
                    Label(doctor, systemImage: "person")
                }
                
                if let date = note.appointmentDate {
                    Label(date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AddMedicalNoteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var content = ""
    @State private var doctorName = ""
    @State private var hasAppointmentDate = false
    @State private var appointmentDate = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                
                Section("Note") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }
                
                Section("Details (Optional)") {
                    TextField("Doctor Name", text: $doctorName)
                    
                    Toggle("Appointment Date", isOn: $hasAppointmentDate)
                    if hasAppointmentDate {
                        DatePicker("Date", selection: $appointmentDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let note = MedicalNote(
                            title: title,
                            content: content,
                            doctorName: doctorName.isEmpty ? nil : doctorName,
                            appointmentDate: hasAppointmentDate ? appointmentDate : nil
                        )
                        modelContext.insert(note)
                        dismiss()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MedicalNotesView()
    }
    .modelContainer(for: MedicalNote.self, inMemory: true)
}
