//
//  heart-rate.swift
//  OmniSiteTracker
//
//  Heart rate monitoring
//

import SwiftUI
import HealthKit

struct heart_rateView: View {
    @State private var isEnabled = false
    
    var body: some View {
        List {
            Section {
                Toggle("Enable Heart rate monitoring", isOn: $isEnabled)
            } header: {
                Text("Settings")
            }
            
            Section {
                Text("Heart rate monitoring data will appear here")
                    .foregroundColor(.secondary)
            } header: {
                Text("Data")
            }
        }
        .navigationTitle("Heart rate monitoring")
    }
}

#Preview {
    NavigationStack {
        heart_rateView()
    }
}
