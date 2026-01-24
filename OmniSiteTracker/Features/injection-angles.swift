//
//  injection-angles.swift
//  OmniSiteTracker
//
//  Injection angle guide
//

import SwiftUI

struct injection_anglesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Injection angle guide")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Track and analyze your injection-angles data")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .navigationTitle("Injection angle guide")
    }
}

#Preview {
    NavigationStack {
        injection_anglesView()
    }
}
