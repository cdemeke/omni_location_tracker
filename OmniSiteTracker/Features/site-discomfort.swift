//
//  site-discomfort.swift
//  OmniSiteTracker
//
//  Site discomfort logging
//

import SwiftUI

struct site_discomfortView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Site discomfort logging")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Track and analyze your site-discomfort data")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .navigationTitle("Site discomfort logging")
    }
}

#Preview {
    NavigationStack {
        site_discomfortView()
    }
}
