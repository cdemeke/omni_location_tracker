//
//  CaregiverModeView.swift
//  OmniSiteTracker
//
//  Simplified interface for caregivers
//

import SwiftUI

@MainActor
@Observable
final class CaregiverManager {
    var isEnabled = false
    var patientName = ""
    var emergencyContact = ""
    var notes = ""
    var lastCheckIn: Date?
    
    func enableCaregiverMode() {
        isEnabled = true
        lastCheckIn = Date()
    }
    
    func disableCaregiverMode() {
        isEnabled = false
    }
    
    func checkIn() {
        lastCheckIn = Date()
    }
}

struct CaregiverModeView: View {
    @State private var manager = CaregiverManager()
    @State private var showingSetup = false
    
    var body: some View {
        List {
            if manager.isEnabled {
                Section("Patient") {
                    Text(manager.patientName)
                        .font(.title2)
                }
                
                Section("Quick Actions") {
                    NavigationLink {
                        SimplifiedLogView()
                    } label: {
                        Label("Log New Site", systemImage: "plus.circle.fill")
                    }
                    
                    NavigationLink {
                        Text("View History")
                    } label: {
                        Label("View History", systemImage: "clock.fill")
                    }
                    
                    Button {
                        manager.checkIn()
                    } label: {
                        Label("Check In", systemImage: "checkmark.circle.fill")
                    }
                }
                
                if let lastCheckIn = manager.lastCheckIn {
                    Section("Last Check-In") {
                        Text(lastCheckIn.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $manager.notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button("Exit Caregiver Mode", role: .destructive) {
                        manager.disableCaregiverMode()
                    }
                }
            } else {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        
                        Text("Caregiver Mode")
                            .font(.title2)
                            .bold()
                        
                        Text("Simplified interface for caregivers to help manage site rotation")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        
                        Button("Enable Caregiver Mode") {
                            showingSetup = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Caregiver Mode")
        .sheet(isPresented: $showingSetup) {
            CaregiverSetupView(manager: manager)
        }
    }
}

struct CaregiverSetupView: View {
    @Bindable var manager: CaregiverManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var patientName = ""
    @State private var emergencyContact = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Patient Information") {
                    TextField("Patient Name", text: $patientName)
                    TextField("Emergency Contact", text: $emergencyContact)
                }
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        manager.patientName = patientName
                        manager.emergencyContact = emergencyContact
                        manager.enableCaregiverMode()
                        dismiss()
                    }
                    .disabled(patientName.isEmpty)
                }
            }
        }
    }
}

struct SimplifiedLogView: View {
    @State private var selectedSite = ""
    @Environment(\.dismiss) private var dismiss
    
    private let sites = ["Left Arm", "Right Arm", "Left Thigh", "Right Thigh", "Abdomen Left", "Abdomen Right"]
    
    var body: some View {
        List {
            Section("Select Site") {
                ForEach(sites, id: \.self) { site in
                    Button {
                        selectedSite = site
                    } label: {
                        HStack {
                            Text(site)
                                .font(.title3)
                            Spacer()
                            if selectedSite == site {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            if !selectedSite.isEmpty {
                Section {
                    Button("Confirm & Log") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .font(.headline)
                }
            }
        }
        .navigationTitle("Log Site")
    }
}

#Preview {
    NavigationStack {
        CaregiverModeView()
    }
}
