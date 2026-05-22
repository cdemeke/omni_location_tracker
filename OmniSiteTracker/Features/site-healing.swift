//
//  site-healing.swift
//  OmniSiteTracker
//
//  Site healing progress tracker
//

import SwiftUI
import HealthKit

struct site_healingView: View {
    @State private var isEnabled = false
    
    var body: some View {
        List {
            Section {
                Toggle("Enable Site healing progress tracker", isOn: $isEnabled)
            } header: {
                Text("Settings")
            }
            
            Section {
                Text("Site healing progress tracker data will appear here")
                    .foregroundColor(.secondary)
            } header: {
                Text("Data")
            }
        }
        .navigationTitle("Site healing progress tracker")
    }
}

#Preview {
    NavigationStack {
        site_healingView()
    }
}
