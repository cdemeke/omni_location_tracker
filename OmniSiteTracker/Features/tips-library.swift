//
//  tips-library.swift
//  OmniSiteTracker
//
//  Tips and best practices library
//

import SwiftUI

struct tipslibraryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Tips and best practices library")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This feature is coming soon!")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    tipslibraryView()
}
