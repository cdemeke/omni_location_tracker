//
//  water-intake.swift
//  OmniSiteTracker
//
//  Water intake logging
//

import SwiftUI
import HealthKit

struct water_intakeView: View {
    @State private var isEnabled = false
    
    var body: some View {
        List {
            Section {
                Toggle("Enable Water intake logging", isOn: $isEnabled)
            } header: {
                Text("Settings")
            }
            
            Section {
                Text("Water intake logging data will appear here")
                    .foregroundColor(.secondary)
            } header: {
                Text("Data")
            }
        }
        .navigationTitle("Water intake logging")
    }
}

#Preview {
    NavigationStack {
        water_intakeView()
    }
}
