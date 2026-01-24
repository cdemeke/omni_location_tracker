//
//  smart-scheduling.swift
//  OmniSiteTracker
//
//  Smart scheduling system
//

import SwiftUI

struct smart_schedulingView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Smart scheduling system")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Track and analyze your smart-scheduling data")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .navigationTitle("Smart scheduling system")
    }
}

#Preview {
    NavigationStack {
        smart_schedulingView()
    }
}
