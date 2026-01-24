//
//  a1c-tracker.swift
//  OmniSiteTracker
//
//  A1C level tracking
//

import SwiftUI
import HealthKit

struct a1c_trackerView: View {
    @State private var isEnabled = false
    
    var body: some View {
        List {
            Section {
                Toggle("Enable A1C level tracking", isOn: $isEnabled)
            } header: {
                Text("Settings")
            }
            
            Section {
                Text("A1C level tracking data will appear here")
                    .foregroundColor(.secondary)
            } header: {
                Text("Data")
            }
        }
        .navigationTitle("A1C level tracking")
    }
}

#Preview {
    NavigationStack {
        a1c_trackerView()
    }
}
