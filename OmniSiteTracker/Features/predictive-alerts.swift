//
//  predictive-alerts.swift
//  OmniSiteTracker
//
//  Predictive site alerts
//

import SwiftUI

struct predictive_alertsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Predictive site alerts")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Track and analyze your predictive-alerts data")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .navigationTitle("Predictive site alerts")
    }
}

#Preview {
    NavigationStack {
        predictive_alertsView()
    }
}
