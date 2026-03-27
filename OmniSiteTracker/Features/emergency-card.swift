//
//  emergency-card.swift
//  OmniSiteTracker
//
//  Emergency info card
//

import SwiftUI

struct emergencycardView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Emergency info card")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This feature is coming soon!")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    emergencycardView()
}
