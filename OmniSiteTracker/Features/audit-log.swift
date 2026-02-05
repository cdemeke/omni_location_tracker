//
//  audit-log.swift
//  OmniSiteTracker
//
//  Security audit log
//

import SwiftUI

struct audit_logView: View {
    var body: some View {
        List {
            Section {
                Text("Security audit log settings")
            }
        }
        .navigationTitle("Security audit log")
    }
}

#Preview {
    audit_logView()
}
