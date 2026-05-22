//
//  biometric-lock.swift
//  OmniSiteTracker
//
//  Biometric app lock
//

import SwiftUI

struct biometric_lockView: View {
    var body: some View {
        List {
            Section {
                Text("Biometric app lock settings")
            }
        }
        .navigationTitle("Biometric app lock")
    }
}

#Preview {
    biometric_lockView()
}
