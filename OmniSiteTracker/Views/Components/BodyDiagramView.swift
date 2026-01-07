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

    // Zones positioned to match contrapposto silhouette
    // Waist 36.5%, Hip 44%, Crotch 46.5%, Knee 68-72%
    private let frontZones: [PlacementZone] = [
        PlacementZone(location: .abdomenLeft, centerX: 0.41, centerY: 0.30, width: 0.10, height: 0.05),
        PlacementZone(location: .abdomenRight, centerX: 0.59, centerY: 0.30, width: 0.10, height: 0.05),
        PlacementZone(location: .lowerAbdomen, centerX: 0.50, centerY: 0.395, width: 0.13, height: 0.045),
        PlacementZone(location: .leftThigh, centerX: 0.43, centerY: 0.57, width: 0.10, height: 0.09),
        PlacementZone(location: .rightThigh, centerX: 0.57, centerY: 0.565, width: 0.10, height: 0.09),
    ]

    private let backZones: [PlacementZone] = [
        PlacementZone(location: .leftArm, centerX: 0.31, centerY: 0.32, width: 0.065, height: 0.085),
        PlacementZone(location: .rightArm, centerX: 0.69, centerY: 0.315, width: 0.065, height: 0.085),
        PlacementZone(location: .lowerBack, centerX: 0.50, centerY: 0.395, width: 0.13, height: 0.045),
    ]

    var body: some View {
        VStack(spacing: 16) {
            viewToggle

            GeometryReader { geometry in
                ZStack {
                    // Sophisticated color palette
                    let primaryStroke = Color(red: 0.55, green: 0.58, blue: 0.65)
                    let secondaryStroke = Color(red: 0.65, green: 0.68, blue: 0.74)
                    let limbStroke = StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round)
                    let torsoStroke = StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)

                    // Multi-stop gradient for natural 3D form
                    // Simulates light from upper-left with soft ambient fill
                    let bodyGradient = RadialGradient(
                        stops: [
                            .init(color: Color(red: 0.98, green: 0.99, blue: 1.0), location: 0.0),
                            .init(color: Color(red: 0.96, green: 0.97, blue: 0.98), location: 0.3),
                            .init(color: Color(red: 0.93, green: 0.94, blue: 0.96), location: 0.6),
                            .init(color: Color(red: 0.90, green: 0.91, blue: 0.94), location: 1.0)
                        ],
                        center: .init(x: 0.42, y: 0.28),  // Light from upper-left
                        startRadius: 0,
                        endRadius: geometry.size.height * 0.55
                    )

                    if selectedView == .front {
                        // Soft shadow layer for depth
                        BodyOutlineFront()
                            .fill(Color.black.opacity(0.03))
                            .offset(x: 1, y: 2)
                            .blur(radius: 2)

                        // Main body fill
                        BodyOutlineFront()
                            .fill(bodyGradient)

                        // Primary stroke (limbs - lighter)
                        BodyOutlineFront()
                            .stroke(secondaryStroke, style: limbStroke)

                        // Torso emphasis stroke (heavier, darker)
                        TorsoOverlayFront()
                            .stroke(primaryStroke, style: torsoStroke)
                    } else {
                        BodyOutlineBack()
                            .fill(Color.black.opacity(0.03))
                            .offset(x: 1, y: 2)
                            .blur(radius: 2)

                        BodyOutlineBack()
                            .fill(bodyGradient)

                        BodyOutlineBack()
                            .stroke(secondaryStroke, style: limbStroke)

                        TorsoOverlayBack()
                            .stroke(primaryStroke, style: torsoStroke)
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
        // Reduced width by ~8%, increased vertical padding
        let w = geo.size.width * zone.size.width * 0.92
        let h = geo.size.height * zone.size.height * 1.05
        let x = geo.size.width * zone.center.x
        let y = geo.size.height * zone.center.y

        Button(action: onTap) {
            ZStack {
                // Slightly lower opacity fill with thin outline
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.85))
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(color.opacity(0.6), lineWidth: 0.5)

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
                    .padding(.horizontal, 3)
                    .padding(.vertical, 4)
            }
        }
        .buttonStyle(.plain)
        .frame(width: w, height: h)
        .position(x: x, y: y)
    }
}

// MARK: - Body Outline Shapes
// Lifelike human silhouette with contrapposto pose and flowing organic curves

struct BodyOutlineFront: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let midX = w / 2

        var path = Path()

        // ═══════════════════════════════════════════════════════════════
        // CONTRAPPOSTO - Classical pose creating life and movement
        // Weight on RIGHT leg → right hip UP, left shoulder UP
        // Creates S-curve through entire body
        // ═══════════════════════════════════════════════════════════════

        // Weight distribution creates asymmetry
        let weightLeg: CGFloat = 1        // 1 = right leg bears weight
        let hipTilt = h * 0.008 * weightLeg      // Right hip raised
        let shoulderTilt = h * 0.005 * weightLeg // Left shoulder raised (counter)
        let headLean = w * 0.01 * weightLeg      // Head leans toward relaxed leg
        let spineShift = w * 0.008               // Subtle S-curve in spine

        // Relaxed leg (left) positioning
        let relaxedKneeBend = w * 0.015   // Left knee bends inward
        let relaxedLegForward = h * 0.005 // Left foot slightly forward

        // ═══════════════════════════════════════════════════════════════
        // GOLDEN RATIO PROPORTIONS (φ = 1.618)
        // 7.5 heads tall for natural adult proportions
        // ═══════════════════════════════════════════════════════════════

        let headUnit = h / 7.5  // One "head" unit

        // HEAD - Slightly oval, tilted with contrapposto
        let headWidth = w * 0.215
        let headHeight = headUnit * 1.05
        let headCenterX = midX - headLean
        let headTop = h * 0.015

        // Oval head (not perfect circle - slightly taller)
        path.addEllipse(in: CGRect(
            x: headCenterX - headWidth/2,
            y: headTop,
            width: headWidth,
            height: headHeight
        ))

        // ═══════════════════════════════════════════════════════════════
        // VERTICAL LANDMARKS (Y positions)
        // ═══════════════════════════════════════════════════════════════

        let neckY = headTop + headHeight - h * 0.008  // Neck overlaps head slightly
        let clavicleY = h * 0.155                      // Collarbone hint
        let shoulderTopL = h * 0.175 + shoulderTilt   // Left shoulder (raised)
        let shoulderTopR = h * 0.175 - shoulderTilt   // Right shoulder
        let deltoidPeakL = h * 0.195 + shoulderTilt   // Deltoid muscle peak
        let deltoidPeakR = h * 0.195 - shoulderTilt
        let armpitY = h * 0.235
        let elbowL = h * 0.39                          // Elbow at waist level
        let elbowR = h * 0.385
        let wristL = h * 0.52                          // Wrists at hip level
        let wristR = h * 0.51

        // Torso landmarks
        let ribBaseY = h * 0.32                        // Bottom of ribcage
        let waistY = h * 0.365                         // Narrowest point
        let navelY = h * 0.40                          // Golden ratio ≈ 0.382 from top
        let hipTopL = h * 0.42 - hipTilt              // Left hip (lowered - relaxed)
        let hipTopR = h * 0.42 + hipTilt              // Right hip (raised - weight)
        let hipPeakL = h * 0.44 - hipTilt * 0.5
        let hipPeakR = h * 0.44 + hipTilt * 0.5
        let crotchY = h * 0.465                        // Just below halfway

        // Leg landmarks
        let thighMidL = h * 0.56 + relaxedLegForward
        let thighMidR = h * 0.555
        let kneeTopL = h * 0.68 + relaxedLegForward
        let kneeTopR = h * 0.675
        let kneeCapL = h * 0.695 + relaxedLegForward  // Patella bulge
        let kneeCapR = h * 0.69
        let kneeBotL = h * 0.72 + relaxedLegForward
        let kneeBotR = h * 0.715
        let calfPeakL = h * 0.765 + relaxedLegForward * 0.5
        let calfPeakR = h * 0.76
        let ankleL = h * 0.905 + relaxedLegForward * 0.3
        let ankleR = h * 0.90
        let heelY = h * 0.955
        let toeY = h * 0.975

        // ═══════════════════════════════════════════════════════════════
        // HORIZONTAL WIDTHS (X positions from center)
        // ═══════════════════════════════════════════════════════════════

        let neckW = w * 0.058                          // Neck width
        let neckBaseW = w * 0.075                      // Neck widens at base
        let trapezW = w * 0.13                         // Trapezius muscle width
        let shoulderW = w * 0.21                       // Shoulder point (acromion)
        let deltoidW = w * 0.225                       // Deltoid muscle bulge
        let chestW = w * 0.175                         // Chest/armpit width
        let ribW = w * 0.165                           // Ribcage width
        let waistW = w * 0.135                         // Waist (narrowest)
        let hipW = w * 0.185                           // Hip width (iliac crest)
        let pelvisW = w * 0.17                         // Lower pelvis
        let upperThighW = w * 0.125                    // Upper thigh
        let midThighW = w * 0.105                      // Mid thigh
        let kneeW = w * 0.075                          // Knee width
        let kneeCapW = w * 0.08                        // Kneecap protrusion
        let calfW = w * 0.085                          // Calf muscle
        let ankleW = w * 0.045                         // Ankle (narrow)
        let ankleBoneW = w * 0.052                     // Malleolus protrusion
        let heelW = w * 0.038
        let footW = w * 0.07                           // Foot length indicator
        let armW = w * 0.05                            // Upper arm
        let forearmW = w * 0.042                       // Forearm
        let wristW = w * 0.032                         // Wrist
        let handW = w * 0.045                          // Hand width
        let legGap = w * 0.012                         // Gap between legs

        // ═══════════════════════════════════════════════════════════════
        // DRAW THE BODY - All curves flow organically
        // Using cubic Beziers for smooth S-curves throughout
        // ═══════════════════════════════════════════════════════════════

        // --- START: Left side of neck ---
        path.move(to: CGPoint(x: midX - neckW - headLean * 0.3, y: neckY))

        // Neck to trapezius - gentle concave curve (sternocleidomastoid hint)
        path.addCurve(
            to: CGPoint(x: midX - trapezW - spineShift, y: clavicleY),
            control1: CGPoint(x: midX - neckBaseW - headLean * 0.2, y: neckY + h * 0.015),
            control2: CGPoint(x: midX - trapezW * 0.7, y: clavicleY - h * 0.01)
        )

        // Trapezius to shoulder - the characteristic slope
        path.addCurve(
            to: CGPoint(x: midX - shoulderW, y: shoulderTopL),
            control1: CGPoint(x: midX - trapezW - w * 0.02, y: clavicleY + h * 0.008),
            control2: CGPoint(x: midX - shoulderW * 0.85, y: shoulderTopL - h * 0.005)
        )

        // Deltoid cap - rounded muscle over shoulder
        path.addCurve(
            to: CGPoint(x: midX - deltoidW, y: deltoidPeakL),
            control1: CGPoint(x: midX - shoulderW - w * 0.02, y: shoulderTopL + h * 0.005),
            control2: CGPoint(x: midX - deltoidW - w * 0.008, y: deltoidPeakL - h * 0.008)
        )

        // Deltoid to armpit - muscle curves back in
        path.addCurve(
            to: CGPoint(x: midX - chestW - armW, y: armpitY),
            control1: CGPoint(x: midX - deltoidW + w * 0.005, y: deltoidPeakL + h * 0.015),
            control2: CGPoint(x: midX - chestW - armW - w * 0.01, y: armpitY - h * 0.015)
        )

        // --- LEFT ARM (relaxed, slight bend, hand near thigh) ---

        // Upper arm - slight outward curve for bicep
        path.addCurve(
            to: CGPoint(x: midX - chestW - armW + w * 0.01, y: elbowL),
            control1: CGPoint(x: midX - chestW - armW - w * 0.008, y: armpitY + h * 0.05),
            control2: CGPoint(x: midX - chestW - armW - w * 0.005, y: elbowL - h * 0.04)
        )

        // Elbow to wrist - forearm tapers
        path.addCurve(
            to: CGPoint(x: midX - hipW + w * 0.025, y: wristL),
            control1: CGPoint(x: midX - chestW - armW + w * 0.02, y: elbowL + h * 0.03),
            control2: CGPoint(x: midX - hipW + w * 0.01, y: wristL - h * 0.04)
        )

        // Left hand - simple rounded shape
        path.addCurve(
            to: CGPoint(x: midX - hipW + w * 0.08, y: wristL + h * 0.005),
            control1: CGPoint(x: midX - hipW + w * 0.035, y: wristL + h * 0.018),
            control2: CGPoint(x: midX - hipW + w * 0.06, y: wristL + h * 0.018)
        )

        // Hand back up - inner arm
        path.addCurve(
            to: CGPoint(x: midX - chestW + w * 0.01, y: elbowL),
            control1: CGPoint(x: midX - hipW + w * 0.05, y: wristL - h * 0.03),
            control2: CGPoint(x: midX - chestW + w * 0.02, y: elbowL + h * 0.03)
        )

        // Inner arm to armpit
        path.addCurve(
            to: CGPoint(x: midX - chestW + w * 0.015, y: armpitY),
            control1: CGPoint(x: midX - chestW, y: elbowL - h * 0.04),
            control2: CGPoint(x: midX - chestW + w * 0.005, y: armpitY + h * 0.03)
        )

        // --- LEFT TORSO - Flowing S-curve from armpit to hip ---

        // Armpit to ribcage - chest curves in
        path.addCurve(
            to: CGPoint(x: midX - ribW - spineShift * 0.5, y: ribBaseY),
            control1: CGPoint(x: midX - chestW + w * 0.02, y: armpitY + h * 0.03),
            control2: CGPoint(x: midX - ribW + w * 0.01, y: ribBaseY - h * 0.025)
        )

        // Ribcage to waist - the inward curve
        path.addCurve(
            to: CGPoint(x: midX - waistW - spineShift, y: waistY),
            control1: CGPoint(x: midX - ribW - w * 0.01, y: ribBaseY + h * 0.015),
            control2: CGPoint(x: midX - waistW + w * 0.008, y: waistY - h * 0.015)
        )

        // Waist to hip - outward curve (left hip is lowered/relaxed)
        path.addCurve(
            to: CGPoint(x: midX - hipW - spineShift * 0.5, y: hipPeakL),
            control1: CGPoint(x: midX - waistW - w * 0.02, y: waistY + h * 0.02),
            control2: CGPoint(x: midX - hipW - w * 0.015, y: hipPeakL - h * 0.015)
        )

        // Hip to pelvis
        path.addCurve(
            to: CGPoint(x: midX - pelvisW + relaxedKneeBend * 0.3, y: crotchY - h * 0.01),
            control1: CGPoint(x: midX - hipW - w * 0.005, y: hipPeakL + h * 0.01),
            control2: CGPoint(x: midX - pelvisW - w * 0.01, y: crotchY - h * 0.025)
        )

        // --- LEFT LEG (relaxed, knee bent inward, foot forward) ---

        // Pelvis to upper thigh
        path.addCurve(
            to: CGPoint(x: midX - upperThighW + relaxedKneeBend, y: thighMidL),
            control1: CGPoint(x: midX - pelvisW + relaxedKneeBend * 0.5, y: crotchY + h * 0.02),
            control2: CGPoint(x: midX - upperThighW + relaxedKneeBend * 0.7, y: thighMidL - h * 0.04)
        )

        // Thigh to knee - tapers with subtle quad curve
        path.addCurve(
            to: CGPoint(x: midX - kneeW + relaxedKneeBend, y: kneeTopL),
            control1: CGPoint(x: midX - midThighW + relaxedKneeBend, y: thighMidL + h * 0.04),
            control2: CGPoint(x: midX - kneeW + relaxedKneeBend + w * 0.01, y: kneeTopL - h * 0.02)
        )

        // Kneecap bulge (patella)
        path.addCurve(
            to: CGPoint(x: midX - kneeCapW + relaxedKneeBend, y: kneeCapL),
            control1: CGPoint(x: midX - kneeW + relaxedKneeBend - w * 0.005, y: kneeTopL + h * 0.005),
            control2: CGPoint(x: midX - kneeCapW + relaxedKneeBend - w * 0.005, y: kneeCapL - h * 0.005)
        )

        // Below knee - curves back in
        path.addCurve(
            to: CGPoint(x: midX - kneeW + relaxedKneeBend * 0.8, y: kneeBotL),
            control1: CGPoint(x: midX - kneeCapW + relaxedKneeBend + w * 0.003, y: kneeCapL + h * 0.008),
            control2: CGPoint(x: midX - kneeW + relaxedKneeBend * 0.8 - w * 0.003, y: kneeBotL - h * 0.005)
        )

        // Calf muscle - characteristic bulge
        path.addCurve(
            to: CGPoint(x: midX - calfW + relaxedKneeBend * 0.5, y: calfPeakL),
            control1: CGPoint(x: midX - kneeW + relaxedKneeBend * 0.8 - w * 0.015, y: kneeBotL + h * 0.015),
            control2: CGPoint(x: midX - calfW + relaxedKneeBend * 0.5 - w * 0.01, y: calfPeakL - h * 0.015)
        )

        // Calf to ankle - aggressive taper with Achilles curve
        path.addCurve(
            to: CGPoint(x: midX - ankleW + relaxedKneeBend * 0.2, y: ankleL),
            control1: CGPoint(x: midX - calfW + relaxedKneeBend * 0.4 + w * 0.015, y: calfPeakL + h * 0.04),
            control2: CGPoint(x: midX - ankleW + relaxedKneeBend * 0.2 - w * 0.01, y: ankleL - h * 0.04)
        )

        // Lateral malleolus (outer ankle bone) - subtle bump
        path.addCurve(
            to: CGPoint(x: midX - ankleBoneW + relaxedKneeBend * 0.1, y: ankleL + h * 0.012),
            control1: CGPoint(x: midX - ankleW + relaxedKneeBend * 0.2 - w * 0.008, y: ankleL + h * 0.003),
            control2: CGPoint(x: midX - ankleBoneW + relaxedKneeBend * 0.1 - w * 0.005, y: ankleL + h * 0.008)
        )

        // Ankle to heel
        path.addCurve(
            to: CGPoint(x: midX - heelW - footW * 0.3, y: heelY),
            control1: CGPoint(x: midX - ankleBoneW + relaxedKneeBend * 0.1 + w * 0.005, y: ankleL + h * 0.025),
            control2: CGPoint(x: midX - heelW - footW * 0.2, y: heelY - h * 0.015)
        )

        // Left foot - points slightly outward
        path.addCurve(
            to: CGPoint(x: midX - legGap - footW * 0.6, y: toeY),
            control1: CGPoint(x: midX - heelW - footW * 0.35, y: heelY + h * 0.012),
            control2: CGPoint(x: midX - legGap - footW * 0.8, y: toeY - h * 0.005)
        )

        // Foot inner edge to arch
        path.addCurve(
            to: CGPoint(x: midX - legGap, y: ankleL + h * 0.015),
            control1: CGPoint(x: midX - legGap - footW * 0.3, y: toeY + h * 0.008),
            control2: CGPoint(x: midX - legGap - w * 0.01, y: heelY)
        )

        // --- LEFT INNER LEG ---
        path.addCurve(
            to: CGPoint(x: midX - legGap, y: crotchY),
            control1: CGPoint(x: midX - legGap + w * 0.003, y: ankleL - h * 0.1),
            control2: CGPoint(x: midX - legGap - w * 0.005, y: crotchY + h * 0.15)
        )

        // --- CROTCH CURVE ---
        path.addCurve(
            to: CGPoint(x: midX + legGap, y: crotchY),
            control1: CGPoint(x: midX - legGap + w * 0.005, y: crotchY + h * 0.01),
            control2: CGPoint(x: midX + legGap - w * 0.005, y: crotchY + h * 0.01)
        )

        // --- RIGHT INNER LEG ---
        path.addCurve(
            to: CGPoint(x: midX + legGap, y: ankleR + h * 0.015),
            control1: CGPoint(x: midX + legGap + w * 0.005, y: crotchY + h * 0.15),
            control2: CGPoint(x: midX + legGap - w * 0.003, y: ankleR - h * 0.1)
        )

        // --- RIGHT FOOT (weight-bearing, more planted) ---
        path.addCurve(
            to: CGPoint(x: midX + legGap + footW * 0.5, y: toeY),
            control1: CGPoint(x: midX + legGap + w * 0.01, y: heelY),
            control2: CGPoint(x: midX + legGap + footW * 0.25, y: toeY + h * 0.008)
        )

        // Right foot outer
        path.addCurve(
            to: CGPoint(x: midX + heelW + footW * 0.25, y: heelY),
            control1: CGPoint(x: midX + legGap + footW * 0.7, y: toeY - h * 0.005),
            control2: CGPoint(x: midX + heelW + footW * 0.3, y: heelY + h * 0.012)
        )

        // Right ankle bone (medial malleolus)
        path.addCurve(
            to: CGPoint(x: midX + ankleBoneW, y: ankleR + h * 0.012),
            control1: CGPoint(x: midX + heelW + footW * 0.15, y: heelY - h * 0.015),
            control2: CGPoint(x: midX + ankleBoneW - w * 0.005, y: ankleR + h * 0.025)
        )

        // Right ankle
        path.addCurve(
            to: CGPoint(x: midX + ankleW, y: ankleR),
            control1: CGPoint(x: midX + ankleBoneW + w * 0.005, y: ankleR + h * 0.008),
            control2: CGPoint(x: midX + ankleW + w * 0.008, y: ankleR + h * 0.003)
        )

        // Right calf
        path.addCurve(
            to: CGPoint(x: midX + calfW, y: calfPeakR),
            control1: CGPoint(x: midX + ankleW + w * 0.01, y: ankleR - h * 0.04),
            control2: CGPoint(x: midX + calfW - w * 0.015, y: calfPeakR + h * 0.04)
        )

        // Right below knee
        path.addCurve(
            to: CGPoint(x: midX + kneeW, y: kneeBotR),
            control1: CGPoint(x: midX + calfW + w * 0.01, y: calfPeakR - h * 0.015),
            control2: CGPoint(x: midX + kneeW + w * 0.015, y: kneeBotR + h * 0.015)
        )

        // Right kneecap
        path.addCurve(
            to: CGPoint(x: midX + kneeCapW, y: kneeCapR),
            control1: CGPoint(x: midX + kneeW + w * 0.003, y: kneeBotR - h * 0.005),
            control2: CGPoint(x: midX + kneeCapW - w * 0.003, y: kneeCapR + h * 0.008)
        )

        // Right knee top
        path.addCurve(
            to: CGPoint(x: midX + kneeW, y: kneeTopR),
            control1: CGPoint(x: midX + kneeCapW + w * 0.005, y: kneeCapR - h * 0.005),
            control2: CGPoint(x: midX + kneeW - w * 0.01, y: kneeTopR + h * 0.02)
        )

        // Right thigh
        path.addCurve(
            to: CGPoint(x: midX + upperThighW, y: thighMidR),
            control1: CGPoint(x: midX + kneeW + w * 0.01, y: kneeTopR - h * 0.02),
            control2: CGPoint(x: midX + midThighW, y: thighMidR + h * 0.04)
        )

        // Right upper thigh to pelvis
        path.addCurve(
            to: CGPoint(x: midX + pelvisW, y: crotchY - h * 0.01),
            control1: CGPoint(x: midX + upperThighW, y: thighMidR - h * 0.04),
            control2: CGPoint(x: midX + pelvisW + w * 0.01, y: crotchY + h * 0.02)
        )

        // --- RIGHT HIP AND TORSO ---

        // Right hip (raised - weight bearing)
        path.addCurve(
            to: CGPoint(x: midX + hipW + spineShift * 0.5, y: hipPeakR),
            control1: CGPoint(x: midX + pelvisW + w * 0.01, y: crotchY - h * 0.025),
            control2: CGPoint(x: midX + hipW + w * 0.005, y: hipPeakR + h * 0.01)
        )

        // Hip to waist
        path.addCurve(
            to: CGPoint(x: midX + waistW + spineShift, y: waistY),
            control1: CGPoint(x: midX + hipW + w * 0.015, y: hipPeakR - h * 0.015),
            control2: CGPoint(x: midX + waistW + w * 0.02, y: waistY + h * 0.02)
        )

        // Waist to ribcage
        path.addCurve(
            to: CGPoint(x: midX + ribW + spineShift * 0.5, y: ribBaseY),
            control1: CGPoint(x: midX + waistW - w * 0.008, y: waistY - h * 0.015),
            control2: CGPoint(x: midX + ribW + w * 0.01, y: ribBaseY + h * 0.015)
        )

        // Ribcage to armpit
        path.addCurve(
            to: CGPoint(x: midX + chestW - w * 0.015, y: armpitY),
            control1: CGPoint(x: midX + ribW - w * 0.01, y: ribBaseY - h * 0.025),
            control2: CGPoint(x: midX + chestW - w * 0.02, y: armpitY + h * 0.03)
        )

        // --- RIGHT ARM ---

        // Armpit to elbow (inner arm)
        path.addCurve(
            to: CGPoint(x: midX + chestW - w * 0.01, y: elbowR),
            control1: CGPoint(x: midX + chestW - w * 0.005, y: armpitY + h * 0.03),
            control2: CGPoint(x: midX + chestW, y: elbowR - h * 0.04)
        )

        // Elbow to wrist (inner arm)
        path.addCurve(
            to: CGPoint(x: midX + hipW - w * 0.08, y: wristR + h * 0.005),
            control1: CGPoint(x: midX + chestW - w * 0.02, y: elbowR + h * 0.03),
            control2: CGPoint(x: midX + hipW - w * 0.05, y: wristR - h * 0.03)
        )

        // Right hand
        path.addCurve(
            to: CGPoint(x: midX + hipW - w * 0.025, y: wristR),
            control1: CGPoint(x: midX + hipW - w * 0.06, y: wristR + h * 0.018),
            control2: CGPoint(x: midX + hipW - w * 0.035, y: wristR + h * 0.018)
        )

        // Outer forearm
        path.addCurve(
            to: CGPoint(x: midX + chestW + armW - w * 0.01, y: elbowR),
            control1: CGPoint(x: midX + hipW - w * 0.01, y: wristR - h * 0.04),
            control2: CGPoint(x: midX + chestW + armW - w * 0.02, y: elbowR + h * 0.03)
        )

        // Outer upper arm
        path.addCurve(
            to: CGPoint(x: midX + chestW + armW, y: armpitY),
            control1: CGPoint(x: midX + chestW + armW + w * 0.005, y: elbowR - h * 0.04),
            control2: CGPoint(x: midX + chestW + armW + w * 0.008, y: armpitY + h * 0.05)
        )

        // --- RIGHT SHOULDER AND NECK ---

        // Armpit to deltoid
        path.addCurve(
            to: CGPoint(x: midX + deltoidW, y: deltoidPeakR),
            control1: CGPoint(x: midX + chestW + armW + w * 0.01, y: armpitY - h * 0.015),
            control2: CGPoint(x: midX + deltoidW - w * 0.005, y: deltoidPeakR + h * 0.015)
        )

        // Deltoid to shoulder
        path.addCurve(
            to: CGPoint(x: midX + shoulderW, y: shoulderTopR),
            control1: CGPoint(x: midX + deltoidW + w * 0.008, y: deltoidPeakR - h * 0.008),
            control2: CGPoint(x: midX + shoulderW + w * 0.02, y: shoulderTopR + h * 0.005)
        )

        // Shoulder to trapezius
        path.addCurve(
            to: CGPoint(x: midX + trapezW + spineShift, y: clavicleY),
            control1: CGPoint(x: midX + shoulderW * 0.85, y: shoulderTopR - h * 0.005),
            control2: CGPoint(x: midX + trapezW + w * 0.02, y: clavicleY + h * 0.008)
        )

        // Trapezius to neck
        path.addCurve(
            to: CGPoint(x: midX + neckW - headLean * 0.3, y: neckY),
            control1: CGPoint(x: midX + trapezW * 0.7, y: clavicleY - h * 0.01),
            control2: CGPoint(x: midX + neckBaseW + headLean * 0.2, y: neckY + h * 0.015)
        )

        path.closeSubpath()

        return path
    }
}

struct BodyOutlineBack: Shape {
    func path(in rect: CGRect) -> Path {
        return BodyOutlineFront().path(in: rect)
    }
}

// MARK: - Torso Overlay Shapes
// Separate torso paths for heavier stroke weight on central body

struct TorsoOverlayFront: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let midX = w / 2

        var path = Path()

        // Matching contrapposto from main shape
        let hipTilt = h * 0.008
        let shoulderTilt = h * 0.005
        let spineShift = w * 0.008

        // Y positions (matching contrapposto body)
        let shoulderTopL = h * 0.175 + shoulderTilt
        let shoulderTopR = h * 0.175 - shoulderTilt
        let deltoidPeakL = h * 0.195 + shoulderTilt
        let deltoidPeakR = h * 0.195 - shoulderTilt
        let armpitY = h * 0.235
        let ribBaseY = h * 0.32
        let waistY = h * 0.365
        let hipPeakL = h * 0.44 - hipTilt * 0.5
        let hipPeakR = h * 0.44 + hipTilt * 0.5
        let crotchY = h * 0.465

        // X widths
        let shoulderW = w * 0.21
        let deltoidW = w * 0.225
        let chestW = w * 0.175
        let ribW = w * 0.165
        let waistW = w * 0.135
        let hipW = w * 0.185
        let pelvisW = w * 0.17

        // Left shoulder and deltoid
        path.move(to: CGPoint(x: midX - shoulderW, y: shoulderTopL))
        path.addCurve(
            to: CGPoint(x: midX - deltoidW, y: deltoidPeakL),
            control1: CGPoint(x: midX - shoulderW - w * 0.02, y: shoulderTopL + h * 0.005),
            control2: CGPoint(x: midX - deltoidW - w * 0.008, y: deltoidPeakL - h * 0.008)
        )

        // Left torso contour
        path.move(to: CGPoint(x: midX - chestW + w * 0.015, y: armpitY))
        path.addCurve(
            to: CGPoint(x: midX - ribW - spineShift * 0.5, y: ribBaseY),
            control1: CGPoint(x: midX - chestW + w * 0.02, y: armpitY + h * 0.03),
            control2: CGPoint(x: midX - ribW + w * 0.01, y: ribBaseY - h * 0.025)
        )
        path.addCurve(
            to: CGPoint(x: midX - waistW - spineShift, y: waistY),
            control1: CGPoint(x: midX - ribW - w * 0.01, y: ribBaseY + h * 0.015),
            control2: CGPoint(x: midX - waistW + w * 0.008, y: waistY - h * 0.015)
        )
        path.addCurve(
            to: CGPoint(x: midX - hipW - spineShift * 0.5, y: hipPeakL),
            control1: CGPoint(x: midX - waistW - w * 0.02, y: waistY + h * 0.02),
            control2: CGPoint(x: midX - hipW - w * 0.015, y: hipPeakL - h * 0.015)
        )

        // Right torso contour
        path.move(to: CGPoint(x: midX + hipW + spineShift * 0.5, y: hipPeakR))
        path.addCurve(
            to: CGPoint(x: midX + waistW + spineShift, y: waistY),
            control1: CGPoint(x: midX + hipW + w * 0.015, y: hipPeakR - h * 0.015),
            control2: CGPoint(x: midX + waistW + w * 0.02, y: waistY + h * 0.02)
        )
        path.addCurve(
            to: CGPoint(x: midX + ribW + spineShift * 0.5, y: ribBaseY),
            control1: CGPoint(x: midX + waistW - w * 0.008, y: waistY - h * 0.015),
            control2: CGPoint(x: midX + ribW + w * 0.01, y: ribBaseY + h * 0.015)
        )
        path.addCurve(
            to: CGPoint(x: midX + chestW - w * 0.015, y: armpitY),
            control1: CGPoint(x: midX + ribW - w * 0.01, y: ribBaseY - h * 0.025),
            control2: CGPoint(x: midX + chestW - w * 0.02, y: armpitY + h * 0.03)
        )

        // Right shoulder and deltoid
        path.move(to: CGPoint(x: midX + deltoidW, y: deltoidPeakR))
        path.addCurve(
            to: CGPoint(x: midX + shoulderW, y: shoulderTopR),
            control1: CGPoint(x: midX + deltoidW + w * 0.008, y: deltoidPeakR - h * 0.008),
            control2: CGPoint(x: midX + shoulderW + w * 0.02, y: shoulderTopR + h * 0.005)
        )

        return path
    }
}

struct TorsoOverlayBack: Shape {
    func path(in rect: CGRect) -> Path {
        return TorsoOverlayFront().path(in: rect)
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
