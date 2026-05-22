//
//  BodyMapView.swift
//  OmniSiteTracker
//
//  Interactive body diagram for site selection
//

import SwiftUI

struct BodyRegion: Identifiable {
    let id = UUID()
    let name: String
    let position: CGPoint
    let size: CGSize
    var lastUsed: Date?
    var usageCount: Int = 0
}

struct BodyMapView: View {
    @State private var regions: [BodyRegion] = [
        BodyRegion(name: "Left Arm", position: CGPoint(x: 0.15, y: 0.35), size: CGSize(width: 0.1, height: 0.15)),
        BodyRegion(name: "Right Arm", position: CGPoint(x: 0.85, y: 0.35), size: CGSize(width: 0.1, height: 0.15)),
        BodyRegion(name: "Left Thigh", position: CGPoint(x: 0.35, y: 0.65), size: CGSize(width: 0.12, height: 0.18)),
        BodyRegion(name: "Right Thigh", position: CGPoint(x: 0.65, y: 0.65), size: CGSize(width: 0.12, height: 0.18)),
        BodyRegion(name: "Abdomen Left", position: CGPoint(x: 0.4, y: 0.45), size: CGSize(width: 0.1, height: 0.1)),
        BodyRegion(name: "Abdomen Right", position: CGPoint(x: 0.6, y: 0.45), size: CGSize(width: 0.1, height: 0.1))
    ]
    
    @State private var selectedRegion: BodyRegion?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Body outline
                Image(systemName: "figure.stand")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.secondary.opacity(0.3))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Tappable regions
                ForEach(regions) { region in
                    Button {
                        selectedRegion = region
                    } label: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorForRegion(region).opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(colorForRegion(region), lineWidth: 2)
                            )
                    }
                    .frame(
                        width: region.size.width * geometry.size.width,
                        height: region.size.height * geometry.size.height
                    )
                    .position(
                        x: region.position.x * geometry.size.width,
                        y: region.position.y * geometry.size.height
                    )
                }
            }
        }
        .navigationTitle("Body Map")
        .sheet(item: $selectedRegion) { region in
            RegionDetailView(region: region)
        }
    }
    
    private func colorForRegion(_ region: BodyRegion) -> Color {
        guard let lastUsed = region.lastUsed else { return .green }
        let daysSince = Calendar.current.dateComponents([.day], from: lastUsed, to: Date()).day ?? 0
        
        if daysSince < 3 { return .red }
        if daysSince < 7 { return .orange }
        return .green
    }
}

struct RegionDetailView: View {
    let region: BodyRegion
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(region.name)
                        .font(.title2)
                }
                
                Section("Statistics") {
                    LabeledContent("Total Uses", value: "\(region.usageCount)")
                    if let lastUsed = region.lastUsed {
                        LabeledContent("Last Used", value: lastUsed.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                
                Section {
                    Button("Log This Site") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Site Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        BodyMapView()
    }
}
