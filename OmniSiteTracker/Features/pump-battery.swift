//
//  pump-battery.swift
//  OmniSiteTracker
//
//  Pump battery tracking
//

import SwiftUI

struct pump_batteryView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Pump battery tracking")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Track and analyze your pump-battery data")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .navigationTitle("Pump battery tracking")
    }
}

#Preview {
    NavigationStack {
        pump_batteryView()
    }
}
