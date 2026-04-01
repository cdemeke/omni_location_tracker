//
//  handoff.swift
//  OmniSiteTracker
//
//  Handoff between devices
//

import SwiftUI

struct handoffView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Handoff between devices")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This feature is coming soon!")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    handoffView()
}
