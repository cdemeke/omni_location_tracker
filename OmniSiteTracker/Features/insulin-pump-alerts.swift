//
//  insulin-pump-alerts.swift
//  OmniSiteTracker
//
//  Pump alert management
//

import SwiftUI
import HealthKit

struct insulin_pump_alertsView: View {
    @State private var isEnabled = false
    
    var body: some View {
        List {
            Section {
                Toggle("Enable Pump alert management", isOn: $isEnabled)
            } header: {
                Text("Settings")
            }
            
            Section {
                Text("Pump alert management data will appear here")
                    .foregroundColor(.secondary)
            } header: {
                Text("Data")
            }
        }
        .navigationTitle("Pump alert management")
    }
}

#Preview {
    NavigationStack {
        insulin_pump_alertsView()
    }
}
