//
//  control-center.swift
//  OmniSiteTracker
//
//  Control Center widget integration
//

import SwiftUI

struct controlcenterView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Control Center widget integration")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This feature is coming soon!")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    controlcenterView()
}
