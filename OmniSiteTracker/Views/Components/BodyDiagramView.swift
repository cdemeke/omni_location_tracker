//
//  BodyDiagramView.swift
//  OmniSiteTracker
//
//  Interactive body diagram showing insulin pump placement sites.
//

import SwiftUI

struct PlacementZone: Identifiable {
    let id: BodyLocation
    let location: BodyLocation
    let center: CGPoint
    let size: CGSize

    init(location: BodyLocation, centerX: CGFloat, centerY: CGFloat, width: CGFloat, height: CGFloat) {
        self.id = location
        self.location = location
        self.center = CGPoint(x: centerX, y: centerY)
        self.size = CGSize(width: width, height: height)
    }
}

struct BodyDiagramView: View {
    let viewModel: PlacementViewModel
    let onLocationSelected: (BodyLocation) -> Void

    @State private var selectedView: BodyView = .front

    enum BodyView: String, CaseIterable {
        case front = "Front"
        case back = "Back"
    }

    private let frontZones: [PlacementZone] = [
        PlacementZone(location: .abdomenLeft, centerX: 0.42, centerY: 0.34, width: 0.10, height: 0.07),
        PlacementZone(location: .abdomenRight, centerX: 0.58, centerY: 0.34, width: 0.10, height: 0.07),
        PlacementZone(location: .lowerAbdomen, centerX: 0.50, centerY: 0.44, width: 0.12, height: 0.06),
        PlacementZone(location: .leftThigh, centerX: 0.43, centerY: 0.64, width: 0.08, height: 0.09),
        PlacementZone(location: .rightThigh, centerX: 0.57, centerY: 0.64, width: 0.08, height: 0.09),
    ]

    private let backZones: [PlacementZone] = [
        PlacementZone(location: .leftArm, centerX: 0.34, centerY: 0.32, width: 0.06, height: 0.10),
        PlacementZone(location: .rightArm, centerX: 0.66, centerY: 0.32, width: 0.06, height: 0.10),
        PlacementZone(location: .lowerBack, centerX: 0.50, centerY: 0.44, width: 0.12, height: 0.06),
    ]

    var body: some View {
        VStack(spacing: 16) {
            viewToggle

            GeometryReader { geometry in
                ZStack {
                    if selectedView == .front {
                        BodyOutlineFront()
                            .fill(Color(red: 0.95, green: 0.96, blue: 0.97))
                        BodyOutlineFront()
                            .stroke(Color(red: 0.68, green: 0.72, blue: 0.78), lineWidth: 1.5)
                    } else {
                        BodyOutlineBack()
                            .fill(Color(red: 0.95, green: 0.96, blue: 0.97))
                        BodyOutlineBack()
                            .stroke(Color(red: 0.68, green: 0.72, blue: 0.78), lineWidth: 1.5)
                    }

                    ForEach(currentZones) { zone in
                        ZoneButton(
                            zone: zone,
                            geo: geometry,
                            color: viewModel.statusColor(for: zone.location),
                            recommended: viewModel.recommendedSite?.location == zone.location,
                            onTap: { onLocationSelected(zone.location) }
                        )
                    }
                }
            }
            .aspectRatio(0.5, contentMode: .fit)
            .padding(.horizontal, 30)
        }
    }

    private var currentZones: [PlacementZone] {
        selectedView == .front ? frontZones : backZones
    }

    private var viewToggle: some View {
        HStack(spacing: 0) {
            ForEach(BodyView.allCases, id: \.self) { view in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedView = view
                    }
                } label: {
                    Text(view.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(selectedView == view ? .white : .textSecondary)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(selectedView == view ? Color.appAccent : Color.clear)
                        .cornerRadius(12)
                }
            }
        }
        .padding(4)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct ZoneButton: View {
    let zone: PlacementZone
    let geo: GeometryProxy
    let color: Color
    let recommended: Bool
    let onTap: () -> Void

    var body: some View {
        let w = geo.size.width * zone.size.width
        let h = geo.size.height * zone.size.height
        let x = geo.size.width * zone.center.x
        let y = geo.size.height * zone.center.y

        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
                    .shadow(color: color.opacity(0.4), radius: 2, y: 1)

                if recommended {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.white, lineWidth: 1.5)
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.appHighlight, lineWidth: 2)
                }

                Text(zone.location.zoneLabel)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .padding(2)
            }
        }
        .buttonStyle(.plain)
        .frame(width: w, height: h)
        .position(x: x, y: y)
    }
}

// MARK: - Body Outline Shapes
// Simple, clean medical-style human silhouette

struct BodyOutlineFront: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let midX = w / 2

        var path = Path()

        // === HEAD ===
        let headRadius = w * 0.09
        let headCenterY = h * 0.07
        path.addEllipse(in: CGRect(
            x: midX - headRadius,
            y: headCenterY - headRadius,
            width: headRadius * 2,
            height: headRadius * 2
        ))

        // === BODY (single continuous path) ===
        let neckWidth = w * 0.06
        let shoulderWidth = w * 0.36
        let armWidth = w * 0.05
        let torsoWidth = w * 0.24
        let waistWidth = w * 0.20
        let hipWidth = w * 0.26
        let legWidth = w * 0.10
        let footWidth = w * 0.06
        let legGap = w * 0.04

        let neckY = h * 0.12
        let shoulderY = h * 0.18
        let armEndY = h * 0.46
        let chestY = h * 0.24
        let waistY = h * 0.40
        let hipY = h * 0.50
        let crotchY = h * 0.54
        let kneeY = h * 0.74
        let ankleY = h * 0.94

        // Start at left neck
        path.move(to: CGPoint(x: midX - neckWidth/2, y: neckY))

        // Neck to left shoulder
        path.addLine(to: CGPoint(x: midX - neckWidth/2, y: shoulderY - h*0.02))
        path.addQuadCurve(
            to: CGPoint(x: midX - shoulderWidth/2, y: shoulderY),
            control: CGPoint(x: midX - shoulderWidth/4, y: shoulderY - h*0.01)
        )

        // Left arm (outer)
        path.addLine(to: CGPoint(x: midX - shoulderWidth/2 + armWidth/2, y: armEndY))

        // Left hand
        path.addQuadCurve(
            to: CGPoint(x: midX - shoulderWidth/2 + armWidth*1.5, y: armEndY),
            control: CGPoint(x: midX - shoulderWidth/2 + armWidth, y: armEndY + h*0.015)
        )

        // Left arm (inner) back up to armpit
        path.addLine(to: CGPoint(x: midX - torsoWidth/2, y: chestY))

        // Left side of torso
        path.addLine(to: CGPoint(x: midX - waistWidth/2, y: waistY))
        path.addLine(to: CGPoint(x: midX - hipWidth/2, y: hipY))

        // Transition to left leg
        path.addQuadCurve(
            to: CGPoint(x: midX - legGap/2 - legWidth, y: crotchY),
            control: CGPoint(x: midX - hipWidth/2, y: crotchY)
        )

        // Left leg outer
        path.addLine(to: CGPoint(x: midX - legGap/2 - legWidth*0.7, y: kneeY))
        path.addLine(to: CGPoint(x: midX - legGap/2 - footWidth, y: ankleY))

        // Left foot
        path.addQuadCurve(
            to: CGPoint(x: midX - legGap/2, y: ankleY),
            control: CGPoint(x: midX - legGap/2 - footWidth/2, y: ankleY + h*0.012)
        )

        // Left leg inner
        path.addLine(to: CGPoint(x: midX - legGap/2, y: crotchY))

        // Crotch curve
        path.addQuadCurve(
            to: CGPoint(x: midX + legGap/2, y: crotchY),
            control: CGPoint(x: midX, y: crotchY + h*0.01)
        )

        // Right leg inner
        path.addLine(to: CGPoint(x: midX + legGap/2, y: ankleY))

        // Right foot
        path.addQuadCurve(
            to: CGPoint(x: midX + legGap/2 + footWidth, y: ankleY),
            control: CGPoint(x: midX + legGap/2 + footWidth/2, y: ankleY + h*0.012)
        )

        // Right leg outer
        path.addLine(to: CGPoint(x: midX + legGap/2 + legWidth*0.7, y: kneeY))
        path.addLine(to: CGPoint(x: midX + legGap/2 + legWidth, y: crotchY))

        // Transition from right leg to hip
        path.addQuadCurve(
            to: CGPoint(x: midX + hipWidth/2, y: hipY),
            control: CGPoint(x: midX + hipWidth/2, y: crotchY)
        )

        // Right side of torso
        path.addLine(to: CGPoint(x: midX + waistWidth/2, y: waistY))
        path.addLine(to: CGPoint(x: midX + torsoWidth/2, y: chestY))

        // Right arm inner down to hand
        path.addLine(to: CGPoint(x: midX + shoulderWidth/2 - armWidth*1.5, y: armEndY))

        // Right hand
        path.addQuadCurve(
            to: CGPoint(x: midX + shoulderWidth/2 - armWidth/2, y: armEndY),
            control: CGPoint(x: midX + shoulderWidth/2 - armWidth, y: armEndY + h*0.015)
        )

        // Right arm outer up to shoulder
        path.addLine(to: CGPoint(x: midX + shoulderWidth/2, y: shoulderY))

        // Right shoulder to neck
        path.addQuadCurve(
            to: CGPoint(x: midX + neckWidth/2, y: shoulderY - h*0.02),
            control: CGPoint(x: midX + shoulderWidth/4, y: shoulderY - h*0.01)
        )
        path.addLine(to: CGPoint(x: midX + neckWidth/2, y: neckY))

        path.closeSubpath()

        return path
    }
}

struct BodyOutlineBack: Shape {
    func path(in rect: CGRect) -> Path {
        var path = BodyOutlineFront().path(in: rect)

        let w = rect.width
        let h = rect.height
        let midX = w / 2

        // Simple spine line
        path.move(to: CGPoint(x: midX, y: h * 0.16))
        path.addLine(to: CGPoint(x: midX, y: h * 0.48))

        return path
    }
}

#Preview {
    BodyDiagramView(
        viewModel: PlacementViewModel(),
        onLocationSelected: { _ in }
    )
    .padding()
    .background(Color.appBackground)
}
