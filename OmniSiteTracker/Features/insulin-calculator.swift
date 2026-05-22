//
//  insulin-calculator.swift
//  OmniSiteTracker
//
//  Insulin dose calculator
//

import SwiftUI

struct insulincalculatorView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Insulin dose calculator")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This feature is coming soon!")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    insulincalculatorView()
}
