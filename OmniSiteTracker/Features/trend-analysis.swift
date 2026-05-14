//
//  trend-analysis.swift
//  OmniSiteTracker
//
//  Long-term trend analysis
//

import SwiftUI

struct trend_analysisView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Long-term trend analysis")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Track and analyze your trend-analysis data")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .navigationTitle("Long-term trend analysis")
    }
}

#Preview {
    NavigationStack {
        trend_analysisView()
    }
}
