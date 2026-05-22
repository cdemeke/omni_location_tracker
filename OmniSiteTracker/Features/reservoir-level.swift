//
//  reservoir-level.swift
//  OmniSiteTracker
//
//  Reservoir level alerts
//

import SwiftUI

struct reservoir_levelView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Reservoir level alerts")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Track and analyze your reservoir-level data")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .navigationTitle("Reservoir level alerts")
    }
}

#Preview {
    NavigationStack {
        reservoir_levelView()
    }
}
