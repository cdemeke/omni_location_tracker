//
//  Medication.swift
//  OmniSiteTracker
//
//  Model and manager for medication tracking.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Medication {
    var id: UUID
    var name: String
    var dosage: String
    var frequency: String
    var startDate: Date
    var notes: String?
    var isActive: Bool
    
    init(name: String, dosage: String, frequency: String, startDate: Date = .now, notes: String? = nil) {
        self.id = UUID()
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.startDate = startDate
        self.notes = notes
        self.isActive = true
    }
}

@Model
final class MedicationDose {
    var id: UUID
    var medicationId: UUID
    var takenAt: Date
    var dosageAmount: String
    var notes: String?
    
    init(medicationId: UUID, dosageAmount: String, notes: String? = nil) {
        self.id = UUID()
        self.medicationId = medicationId
        self.takenAt = .now
        self.dosageAmount = dosageAmount
        self.notes = notes
    }
}

struct MedicationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Medication.name) private var medications: [Medication]
    @State private var showingAddMedication = false
    
    var body: some View {
        List {
            ForEach(medications.filter(\.isActive)) { medication in
                MedicationRow(medication: medication)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let med = medications.filter(\.isActive)[index]
                    med.isActive = false
                }
            }
            
            Button("Add Medication") {
                showingAddMedication = true
            }
        }
        .navigationTitle("Medications")
        .sheet(isPresented: $showingAddMedication) {
            AddMedicationView()
        }
    }
}

struct MedicationRow: View {
    let medication: Medication
    @State private var showingLogDose = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(medication.name)
                    .font(.headline)
                Text("\(medication.dosage) • \(medication.frequency)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Log Dose") {
                showingLogDose = true
            }
            .buttonStyle(.bordered)
        }
        .sheet(isPresented: $showingLogDose) {
            LogDoseView(medication: medication)
        }
    }
}

struct AddMedicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = "Daily"
    
    let frequencies = ["Daily", "Twice Daily", "Weekly", "As Needed"]
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Medication Name", text: $name)
                TextField("Dosage (e.g., 10mg)", text: $dosage)
                Picker("Frequency", selection: $frequency) {
                    ForEach(frequencies, id: \.self) { Text($0) }
                }
            }
            .navigationTitle("Add Medication")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let med = Medication(name: name, dosage: dosage, frequency: frequency)
                        modelContext.insert(med)
                        dismiss()
                    }
                    .disabled(name.isEmpty || dosage.isEmpty)
                }
            }
        }
    }
}

struct LogDoseView: View {
    let medication: Medication
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(medication.name)
                        .font(.headline)
                    Text(medication.dosage)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    TextField("Notes (optional)", text: $notes)
                }
            }
            .navigationTitle("Log Dose")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        let dose = MedicationDose(medicationId: medication.id, dosageAmount: medication.dosage, notes: notes.isEmpty ? nil : notes)
                        modelContext.insert(dose)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MedicationListView()
    }
}
