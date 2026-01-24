//
//  SymptomTrackerView.swift
//  OmniSiteTracker
//
//  Detailed symptom tracking and analysis
//

import SwiftUI
import SwiftData

@Model
final class SymptomEntry {
    var id: UUID
    var symptomType: String
    var severity: Int
    var site: String
    var notes: String?
    var recordedAt: Date
    
    init(symptomType: String, severity: Int, site: String, notes: String? = nil) {
        self.id = UUID()
        self.symptomType = symptomType
        self.severity = severity
        self.site = site
        self.notes = notes
        self.recordedAt = Date()
    }
}

struct SymptomTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SymptomEntry.recordedAt, order: .reverse) private var symptoms: [SymptomEntry]
    @State private var showingAddSymptom = false
    
    private let symptomTypes = ["Irritation", "Redness", "Swelling", "Pain", "Bruising", "Itching", "Other"]
    
    var body: some View {
        List {
            Section {
                Button {
                    showingAddSymptom = true
                } label: {
                    Label("Log Symptom", systemImage: "plus.circle.fill")
                }
            }
            
            Section("Recent Symptoms") {
                if symptoms.isEmpty {
                    Text("No symptoms recorded")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(symptoms) { symptom in
                        SymptomRow(symptom: symptom)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            modelContext.delete(symptoms[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("Symptom Tracker")
        .sheet(isPresented: $showingAddSymptom) {
            AddSymptomView()
        }
    }
}

struct SymptomRow: View {
    let symptom: SymptomEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(symptom.symptomType)
                    .font(.headline)
                
                Spacer()
                
                SeverityBadge(severity: symptom.severity)
            }
            
            Text(symptom.site)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let notes = symptom.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(symptom.recordedAt.formatted())
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct SeverityBadge: View {
    let severity: Int
    
    var body: some View {
        Text("Level \(severity)")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(colorForSeverity.opacity(0.2))
            .foregroundStyle(colorForSeverity)
            .clipShape(Capsule())
    }
    
    private var colorForSeverity: Color {
        switch severity {
        case 1...2: return .green
        case 3...4: return .yellow
        case 5...7: return .orange
        default: return .red
        }
    }
}

struct AddSymptomView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var symptomType = "Irritation"
    @State private var severity = 3
    @State private var site = ""
    @State private var notes = ""
    
    private let symptomTypes = ["Irritation", "Redness", "Swelling", "Pain", "Bruising", "Itching", "Other"]
    private let sites = ["Left Arm", "Right Arm", "Left Thigh", "Right Thigh", "Abdomen Left", "Abdomen Right"]
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Symptom Type", selection: $symptomType) {
                    ForEach(symptomTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                
                Section("Severity") {
                    Slider(value: .init(get: { Double(severity) }, set: { severity = Int($0) }), in: 1...10, step: 1)
                    Text("Level: \(severity)")
                        .foregroundStyle(.secondary)
                }
                
                Picker("Site", selection: $site) {
                    ForEach(sites, id: \.self) { s in
                        Text(s).tag(s)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Log Symptom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let entry = SymptomEntry(
                            symptomType: symptomType,
                            severity: severity,
                            site: site,
                            notes: notes.isEmpty ? nil : notes
                        )
                        modelContext.insert(entry)
                        dismiss()
                    }
                    .disabled(site.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SymptomTrackerView()
    }
    .modelContainer(for: SymptomEntry.self, inMemory: true)
}
