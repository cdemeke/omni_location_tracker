//
//  sync-conflicts.swift
//  OmniSiteTracker
//
//  Sync conflict resolver
//

import SwiftUI

struct sync_conflictsView: View {
    var body: some View {
        List {
            Section {
                Text("Sync conflict resolver settings")
            }
        }
        .navigationTitle("Sync conflict resolver")
    }
}

#Preview {
    sync_conflictsView()
}
