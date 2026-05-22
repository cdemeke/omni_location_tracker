//
//  family-sharing.swift
//  OmniSiteTracker
//
//  Family sharing features
//

import SwiftUI
import HealthKit

struct family_sharingView: View {
    @State private var isEnabled = false
    
    var body: some View {
        List {
            Section {
                Toggle("Enable Family sharing features", isOn: $isEnabled)
            } header: {
                Text("Settings")
            }
            
            Section {
                Text("Family sharing features data will appear here")
                    .foregroundColor(.secondary)
            } header: {
                Text("Data")
            }
        }
        .navigationTitle("Family sharing features")
    }
}

#Preview {
    NavigationStack {
        family_sharingView()
    }
}
