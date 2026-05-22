//
//  app-clips.swift
//  OmniSiteTracker
//
//  App Clips for quick placement logging
//

import SwiftUI

struct appclipsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("App Clips for quick placement logging")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This feature is coming soon!")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    appclipsView()
}
