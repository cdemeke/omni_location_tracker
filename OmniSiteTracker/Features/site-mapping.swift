//
//  site-mapping.swift
//  OmniSiteTracker
//
//  Body site mapping tool
//

import SwiftUI

struct site_mappingView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Body site mapping tool")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Track and analyze your site-mapping data")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .navigationTitle("Body site mapping tool")
    }
}

#Preview {
    NavigationStack {
        site_mappingView()
    }
}
