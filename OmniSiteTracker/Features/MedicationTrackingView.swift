//
//  MedicationTrackingView.swift
//  OmniSiteTracker
//
//  Medication and insulin tracking
//

import SwiftUI
import SwiftData

@Model
final class MedicationDose {
    var id: UUID
    var medicationName: String
    var dosage: Double
    var unit: String
    var takenAt: Date
    var notes: String?
    var site: String?
    
    init(medicationName: String, dosage: Double, unit: String, site: String? = nil, notes: String? = nil) {
        self.id = UUID()
        self.medicationName = medicationName
        self.dosage = dosage
        self.unit = unit
        self.takenAt = Date()
        self.site = site
        self.notes = notes
    }
}

struct MedicationTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MedicationDose.takenAt, order: .reverse) private var doses: [MedicationDose]
    @State private var showLogSheet = false
    
    var todaysDoses: [MedicationDose] {
        doses.filter { Calendar.current.isDateInToday($0.takenAt) }
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Today's Doses").font(.headline)
                        Text("\(todaysDoses.count) logged").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { showLogSheet = true } label: { Image(systemName: "plus.circle.fill").font(.title2) }
                }
            }
            
            if !todaysDoses.isEmpty {
                Section("Today") {
                    ForEach(todaysDoses) { dose in
                        DoseRow(dose: dose)
                    }.onDelete { indexSet in
                        for index in indexSet { modelContext.delete(todaysDoses[index]) }
                    }
                }
            }
            
            Section("History") {
                ForEach(doses.filter { !Calendar.current.isDateInToday($0.takenAt) }.prefix(20)) { dose in
                    DoseRow(dose: dose)
                }
            }
        }
        .navigationTitle("Medication")
        .sheet(isPresented: $showLogSheet) { LogMedicationView() }
    }
}

struct DoseRow: View {
    let dose: MedicationDose
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(dose.medicationName).font(.headline)
                HStack {
                    Text("\(dose.dosage, specifier: "%.1f") \(dose.unit)")
                    if let site = dose.site { Text("• \(site)") }
                }.font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(dose.takenAt.formatted(date: .omitted, time: .shortened)).font(.subheadline).foregroundStyle(.secondary)
        }
    }
}

struct LogMedicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMedication = "Insulin"
    @State private var dosage = 10.0
    @State private var selectedUnit = "units"
    @State private var selectedSite = "Abdomen - Left"
    @State private var notes = ""
    
    let medications = ["Insulin", "Humalog", "Novolog", "Lantus", "Tresiba"]
    let sites = ["Abdomen - Left", "Abdomen - Right", "Arm - Left", "Arm - Right", "Thigh - Left", "Thigh - Right"]
    let units = ["units", "mg", "ml"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    Picker("Medication", selection: $selectedMedication) {
                        ForEach(medications, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section("Dosage") {
                    HStack {
                        TextField("Amount", value: $dosage, format: .number).keyboardType(.decimalPad)
                        Picker("Unit", selection: $selectedUnit) {
                            ForEach(units, id: \.self) { Text($0).tag($0) }
                        }.pickerStyle(.menu)
                    }
                    Stepper("Quick: \(Int(dosage)) \(selectedUnit)", value: $dosage, in: 1...100)
                }
                Section("Site") {
                    Picker("Site", selection: $selectedSite) {
                        ForEach(sites, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section { TextField("Notes", text: $notes, axis: .vertical) }
                Section {
                    Button("Log Dose") {
                        let dose = MedicationDose(medicationName: selectedMedication, dosage: dosage, unit: selectedUnit, site: selectedSite, notes: notes.isEmpty ? nil : notes)
                        modelContext.insert(dose)
                        dismiss()
                    }.frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Log Medication")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}

#Preview {
    NavigationStack { MedicationTrackingView() }
        .modelContainer(for: MedicationDose.self, inMemory: true)
}
