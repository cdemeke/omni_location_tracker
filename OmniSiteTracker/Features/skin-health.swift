//
//  skin-health.swift
//  OmniSiteTracker
//
//  Skin health monitoring and tips
//

import SwiftUI

struct skinhealthView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Skin health monitoring and tips")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This feature is coming soon!")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    skinhealthView()
}
