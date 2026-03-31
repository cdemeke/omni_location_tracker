//
//  infusion-time.swift
//  OmniSiteTracker
//
//  Infusion time tracking
//

import SwiftUI

struct infusion_timeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Infusion time tracking")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Track and analyze your infusion-time data")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .navigationTitle("Infusion time tracking")
    }
}

#Preview {
    NavigationStack {
        infusion_timeView()
    }
}
