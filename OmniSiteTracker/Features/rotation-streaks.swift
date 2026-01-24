//
//  rotation-streaks.swift
//  OmniSiteTracker
//
//  Rotation streak rewards
//

import SwiftUI
import HealthKit

struct rotation_streaksView: View {
    @State private var isEnabled = false
    
    var body: some View {
        List {
            Section {
                Toggle("Enable Rotation streak rewards", isOn: $isEnabled)
            } header: {
                Text("Settings")
            }
            
            Section {
                Text("Rotation streak rewards data will appear here")
                    .foregroundColor(.secondary)
            } header: {
                Text("Data")
            }
        }
        .navigationTitle("Rotation streak rewards")
    }
}

#Preview {
    NavigationStack {
        rotation_streaksView()
    }
}
