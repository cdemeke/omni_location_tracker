//
//  QuickLogWidgetView.swift
//  OmniSiteTracker
//
//  Quick logging widget component
//

import SwiftUI
import SwiftData

struct QuickLogWidgetView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedSite: String?
    @State private var showingConfirmation = false
    
    private let quickSites = [
        ("Left Arm", "L.arm"),
        ("Right Arm", "R.arm"),
        ("Left Thigh", "L.thigh"),
        ("Right Thigh", "R.thigh"),
        ("Abdomen L", "Abd.L"),
        ("Abdomen R", "Abd.R")
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Quick Log")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(quickSites, id: \.0) { site in
                    QuickLogButton(
                        fullName: site.0,
                        shortName: site.1,
                        isSelected: selectedSite == site.0
                    ) {
                        selectedSite = site.0
                        logSite(site.0)
                    }
                }
            }
            
            if showingConfirmation {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Logged!")
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func logSite(_ site: String) {
        let log = PlacementLog(site: site, placedAt: Date(), notes: nil)
        modelContext.insert(log)
        
        withAnimation {
            showingConfirmation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingConfirmation = false
                selectedSite = nil
            }
        }
    }
}

struct QuickLogButton: View {
    let fullName: String
    let shortName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                Text(shortName)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue : Color.secondary.opacity(0.2))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    QuickLogWidgetView()
        .modelContainer(for: PlacementLog.self, inMemory: true)
        .padding()
}
