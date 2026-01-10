//
//  HeatmapBodyDiagramView.swift
//  OmniSiteTracker
//
//  Body diagram with color-coded zones showing usage density.
//  Colors range from gray (low usage) through orange to red (high usage).
//

import SwiftUI

struct HeatmapBodyDiagramView: View {
    let heatmapData: [HeatmapData]
    @State private var selectedView: BodyView = .front

    // Front view zones - same positioning as BodyDiagramView
    private let frontZones: [PlacementZone] = [
        PlacementZone(location: .abdomenLeft, corner: .topLeft, bodyX: 0.42, bodyY: 0.52),
        PlacementZone(location: .abdomenRight, corner: .topRight, bodyX: 0.58, bodyY: 0.52),
        PlacementZone(location: .leftThigh, corner: .bottomLeft, bodyX: 0.42, bodyY: 0.78),
        PlacementZone(location: .rightThigh, corner: .bottomRight, bodyX: 0.58, bodyY: 0.78),
    ]

    // Back view zones
    private let backZones: [PlacementZone] = [
        PlacementZone(location: .leftArm, corner: .topLeft, bodyX: 0.25, bodyY: 0.42),
        PlacementZone(location: .rightArm, corner: .topRight, bodyX: 0.75, bodyY: 0.42),
        PlacementZone(location: .lowerBack, corner: .bottomCenter, bodyX: 0.50, bodyY: 0.58),
    ]

    // Crop parameters (same as BodyDiagramView)
    private let cropTop: CGFloat = 0.10
    private let cropBottom: CGFloat = 0.68
    private var visibleHeight: CGFloat { cropBottom - cropTop }

    var body: some View {
        VStack(spacing: 16) {
            // Front/Back toggle
            BodyViewTabs(selection: $selectedView)

            // Body diagram with heatmap zones
            GeometryReader { geometry in
                let imageScale: CGFloat = 1 / visibleHeight
                let offsetY = geometry.size.height * (0.5 - (cropTop + cropBottom) / 2) * imageScale

                ZStack {
                    // Body silhouette (centered)
                    Image("bodyFront")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .saturation(0)
                        .opacity(0.85)
                        .colorMultiply(Color(red: 0.92, green: 0.94, blue: 0.96))
                        .scaleEffect(x: selectedView == .back ? -imageScale : imageScale, y: imageScale)
                        .offset(y: offsetY)

                    // Heatmap zone indicators
                    ForEach(currentZones) { zone in
                        HeatmapZoneIndicator(
                            zone: zone,
                            geometry: geometry,
                            intensity: intensityFor(location: zone.location)
                        )
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
            }
            .aspectRatio(1.0, contentMode: .fit)
        }
        .padding(16)
        .neumorphicCard()
    }

    private var currentZones: [PlacementZone] {
        selectedView == .front ? frontZones : backZones
    }

    private func intensityFor(location: BodyLocation) -> Double {
        heatmapData.first { $0.location == location }?.intensity ?? 0
    }
}

// MARK: - Heatmap Zone Indicator

struct HeatmapZoneIndicator: View {
    let zone: PlacementZone
    let geometry: GeometryProxy
    let intensity: Double

    private let buttonSize: CGFloat = 75
    private let buttonPadding: CGFloat = 8

    var body: some View {
        let buttonCenter = buttonPosition(in: geometry)
        let bodyTarget = CGPoint(
            x: geometry.size.width * zone.bodyPoint.x,
            y: geometry.size.height * zone.bodyPoint.y
        )

        ZStack {
            // Dotted line from button to body point
            DottedLine(from: buttonCenter, to: bodyTarget)
                .stroke(heatmapColor.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))

            // Circle on body point with intensity color
            Circle()
                .fill(heatmapColor.opacity(0.7))
                .frame(width: 14, height: 14)
                .position(bodyTarget)

            // Zone indicator in corner
            VStack(spacing: 4) {
                Text(zone.location.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: buttonSize, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(heatmapColor.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(heatmapColor.opacity(0.3), lineWidth: 1)
            )
            .position(buttonCenter)
        }
    }

    /// Calculates heatmap color based on intensity (0-1)
    /// Gray (0) -> Orange (0.5) -> Red (1.0)
    private var heatmapColor: Color {
        if intensity <= 0 {
            return Color.gray
        } else if intensity <= 0.5 {
            // Gray to Orange transition (0 to 0.5)
            let t = intensity * 2 // Normalize to 0-1 range
            return Color(
                red: 0.5 + (0.5 * t),      // 0.5 -> 1.0
                green: 0.5 - (0.15 * t),   // 0.5 -> 0.35
                blue: 0.5 - (0.5 * t)      // 0.5 -> 0.0
            )
        } else {
            // Orange to Red transition (0.5 to 1.0)
            let t = (intensity - 0.5) * 2 // Normalize to 0-1 range
            return Color(
                red: 1.0,                  // Stay at 1.0
                green: 0.35 - (0.35 * t),  // 0.35 -> 0.0
                blue: 0.0                  // Stay at 0.0
            )
        }
    }

    private func buttonPosition(in geometry: GeometryProxy) -> CGPoint {
        let width = geometry.size.width
        let height = geometry.size.height
        let halfButton = buttonSize / 2 + buttonPadding

        switch zone.buttonPosition {
        case .topLeft:
            return CGPoint(x: halfButton, y: halfButton)
        case .topRight:
            return CGPoint(x: width - halfButton, y: halfButton)
        case .bottomLeft:
            return CGPoint(x: halfButton, y: height - halfButton)
        case .bottomRight:
            return CGPoint(x: width - halfButton, y: height - halfButton)
        case .leftCenter:
            return CGPoint(x: halfButton, y: height / 2)
        case .rightCenter:
            return CGPoint(x: width - halfButton, y: height / 2)
        case .bottomCenter:
            return CGPoint(x: width / 2, y: height - halfButton)
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleData: [HeatmapData] = [
        HeatmapData(location: .abdomenLeft, usageCount: 10, intensity: 1.0, lastUsed: Date(), percentageOfTotal: 25),
        HeatmapData(location: .abdomenRight, usageCount: 8, intensity: 0.8, lastUsed: Date(), percentageOfTotal: 20),
        HeatmapData(location: .leftThigh, usageCount: 5, intensity: 0.5, lastUsed: Date(), percentageOfTotal: 12.5),
        HeatmapData(location: .rightThigh, usageCount: 3, intensity: 0.3, lastUsed: Date(), percentageOfTotal: 7.5),
        HeatmapData(location: .leftArm, usageCount: 6, intensity: 0.6, lastUsed: Date(), percentageOfTotal: 15),
        HeatmapData(location: .rightArm, usageCount: 4, intensity: 0.4, lastUsed: Date(), percentageOfTotal: 10),
        HeatmapData(location: .lowerBack, usageCount: 2, intensity: 0.2, lastUsed: Date(), percentageOfTotal: 5),
        HeatmapData(location: .lowerAbdomen, usageCount: 2, intensity: 0.2, lastUsed: Date(), percentageOfTotal: 5),
    ]

    return HeatmapBodyDiagramView(heatmapData: sampleData)
        .padding()
        .background(WarmGradientBackground())
}
