//
//  site-temperature.swift
//  OmniSiteTracker
//
//  Site temperature monitoring
//

import SwiftUI

struct site_temperatureView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Site temperature monitoring")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Track and analyze your site-temperature data")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .navigationTitle("Site temperature monitoring")
    }
}

#Preview {
    NavigationStack {
        site_temperatureView()
    }
}
