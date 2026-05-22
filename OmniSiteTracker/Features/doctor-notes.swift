//
//  doctor-notes.swift
//  OmniSiteTracker
//
//  Doctor visit notes
//

import SwiftUI
import HealthKit

struct doctor_notesView: View {
    @State private var isEnabled = false
    
    var body: some View {
        List {
            Section {
                Toggle("Enable Doctor visit notes", isOn: $isEnabled)
            } header: {
                Text("Settings")
            }
            
            Section {
                Text("Doctor visit notes data will appear here")
                    .foregroundColor(.secondary)
            } header: {
                Text("Data")
            }
        }
        .navigationTitle("Doctor visit notes")
    }
}

#Preview {
    NavigationStack {
        doctor_notesView()
    }
}
