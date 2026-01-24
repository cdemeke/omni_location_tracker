//
//  blood-pressure.swift
//  OmniSiteTracker
//
//  Blood pressure tracking integration
//

import SwiftUI
import HealthKit

struct blood_pressureView: View {
    @State private var isEnabled = false
    
    var body: some View {
        List {
            Section {
                Toggle("Enable Blood pressure tracking integration", isOn: $isEnabled)
            } header: {
                Text("Settings")
            }
            
            Section {
                Text("Blood pressure tracking integration data will appear here")
                    .foregroundColor(.secondary)
            } header: {
                Text("Data")
            }
        }
        .navigationTitle("Blood pressure tracking integration")
    }
}

#Preview {
    NavigationStack {
        blood_pressureView()
    }
}
