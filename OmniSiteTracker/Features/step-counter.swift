//
//  step-counter.swift
//  OmniSiteTracker
//
//  Daily step tracking
//

import SwiftUI
import HealthKit

struct step_counterView: View {
    @State private var isEnabled = false
    
    var body: some View {
        List {
            Section {
                Toggle("Enable Daily step tracking", isOn: $isEnabled)
            } header: {
                Text("Settings")
            }
            
            Section {
                Text("Daily step tracking data will appear here")
                    .foregroundColor(.secondary)
            } header: {
                Text("Data")
            }
        }
        .navigationTitle("Daily step tracking")
    }
}

#Preview {
    NavigationStack {
        step_counterView()
    }
}
