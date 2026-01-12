//
//  BodyDiagramView.swift
//  OmniSiteTracker
//
//  Interactive body diagram showing insulin pump placement sites.
//  Zone buttons in corners with dotted lines to body parts.
//

import SwiftUI

/// View selection for body diagram
enum BodyView: String, CaseIterable {
    case front = "Front"
    case back = "Back"
}

struct PlacementZone: Identifiable {
    let id: BodyLocation
    let location: BodyLocation
    /// Position of the button (in corners)
    let buttonPosition: ButtonCorner
    /// Target point on body for the dotted line (normalized 0-1)
    let bodyPoint: CGPoint

    enum ButtonCorner {
        case topLeft, topRight, bottomLeft, bottomRight
        case leftCenter, rightCenter, bottomCenter
    }

    init(location: BodyLocation, corner: ButtonCorner, bodyX: CGFloat, bodyY: CGFloat) {
        self.id = location
        self.location = location
        self.buttonPosition = corner
        self.bodyPoint = CGPoint(x: bodyX, y: bodyY)
    }
}

struct BodyDiagramView: View {
    let viewModel: PlacementViewModel
    let onLocationSelected: (BodyLocation) -> Void
    @Binding var selectedView: BodyView
    /// Set of enabled body locations to display. If nil, all locations are shown.
    var enabledLocations: Set<BodyLocation>?

    // Front view zones - buttons in corners, body points where lines connect
    private let allFrontZones: [PlacementZone] = [
        PlacementZone(location: .abdomenLeft, corner: .topLeft, bodyX: 0.42, bodyY: 0.52),
        PlacementZone(location: .abdomenRight, corner: .topRight, bodyX: 0.58, bodyY: 0.52),
        PlacementZone(location: .leftThigh, corner: .bottomLeft, bodyX: 0.42, bodyY: 0.78),
        PlacementZone(location: .rightThigh, corner: .bottomRight, bodyX: 0.58, bodyY: 0.78),
    ]

    // Back view zones
    private let allBackZones: [PlacementZone] = [
        PlacementZone(location: .leftArm, corner: .topLeft, bodyX: 0.25, bodyY: 0.42),
        PlacementZone(location: .rightArm, corner: .topRight, bodyX: 0.75, bodyY: 0.42),
        PlacementZone(location: .leftLowerBack, corner: .bottomLeft, bodyX: 0.42, bodyY: 0.58),
        PlacementZone(location: .rightLowerBack, corner: .bottomRight, bodyX: 0.58, bodyY: 0.58),
    ]

    /// Front zones filtered by enabled locations
    private var frontZones: [PlacementZone] {
        guard let enabled = enabledLocations else { return allFrontZones }
        return allFrontZones.filter { enabled.contains($0.location) }
    }

    /// Back zones filtered by enabled locations
    private var backZones: [PlacementZone] {
        guard let enabled = enabledLocations else { return allBackZones }
        return allBackZones.filter { enabled.contains($0.location) }
    }

    // Crop parameters
    private let cropTop: CGFloat = 0.10
    private let cropBottom: CGFloat = 0.68
    private var visibleHeight: CGFloat { cropBottom - cropTop }

    var body: some View {
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

                    // Dotted lines and zone buttons
                    ForEach(currentZones) { zone in
                        ZoneWithLine(
                            zone: zone,
                            geometry: geometry,
                            color: viewModel.statusColor(for: zone.location),
                            recommended: viewModel.recommendedSite?.location == zone.location,
                            onTap: { onLocationSelected(zone.location) }
                        )
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .aspectRatio(1.0, contentMode: .fit)
    }

    private var currentZones: [PlacementZone] {
        selectedView == .front ? frontZones : backZones
    }
}

// MARK: - Zone with connecting line

struct ZoneWithLine: View {
    let zone: PlacementZone
    let geometry: GeometryProxy
    let color: Color
    let recommended: Bool
    let onTap: () -> Void

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
                .stroke(color.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))

            // Small circle on body point
            Circle()
                .fill(color.opacity(0.6))
                .frame(width: 10, height: 10)
                .position(bodyTarget)

            // Zone button in corner
            Button(action: onTap) {
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
                        .fill(color.opacity(0.9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(recommended ? Color.appHighlight : color.opacity(0.3), lineWidth: recommended ? 2.5 : 1)
                )
            }
            .buttonStyle(.plain)
            .position(buttonCenter)
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

// MARK: - Dotted Line Shape

struct DottedLine: Shape {
    var from: CGPoint
    var to: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        return path
    }
}

// MARK: - Preview

#Preview {
    BodyDiagramView(
        viewModel: PlacementViewModel(),
        onLocationSelected: { _ in },
        selectedView: .constant(.front)
    )
    .padding()
    .background(Color.appBackground)
}
