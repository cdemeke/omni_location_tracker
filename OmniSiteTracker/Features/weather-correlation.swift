//
//  weather-correlation.swift
//  OmniSiteTracker
//
//  Weather correlation with site comfort
//

import SwiftUI

struct weathercorrelationView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Weather correlation with site comfort")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This feature is coming soon!")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    weathercorrelationView()
}
