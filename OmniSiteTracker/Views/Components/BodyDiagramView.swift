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

    // Zones positioned for CROPPED view (shoulders to mid-thigh)
    // Original image cropped from y=0.10 to y=0.68 (58% of height visible)
    // Zone positions recalculated: new_y = (old_y - 0.10) / 0.58
    // Zone sizes scaled up for better tap targets
    private let frontZones: [PlacementZone] = [
        PlacementZone(location: .abdomenLeft, centerX: 0.38, centerY: 0.40, width: 0.18, height: 0.10),
        PlacementZone(location: .abdomenRight, centerX: 0.62, centerY: 0.40, width: 0.18, height: 0.10),
        PlacementZone(location: .lowerAbdomen, centerX: 0.50, centerY: 0.56, width: 0.22, height: 0.09),
        PlacementZone(location: .leftThigh, centerX: 0.40, centerY: 0.82, width: 0.16, height: 0.14),
        PlacementZone(location: .rightThigh, centerX: 0.60, centerY: 0.82, width: 0.16, height: 0.14),
    ]

    private let backZones: [PlacementZone] = [
        PlacementZone(location: .leftArm, centerX: 0.22, centerY: 0.46, width: 0.12, height: 0.18),
        PlacementZone(location: .rightArm, centerX: 0.78, centerY: 0.46, width: 0.12, height: 0.18),
        PlacementZone(location: .lowerBack, centerX: 0.50, centerY: 0.56, width: 0.22, height: 0.09),
    ]

    // Crop parameters: show from 10% to 68% of original image height
    private let cropTop: CGFloat = 0.10
    private let cropBottom: CGFloat = 0.68
    private var visibleHeight: CGFloat { cropBottom - cropTop }  // 0.58

    var body: some View {
        VStack(spacing: 16) {
            viewToggle

            GeometryReader { geometry in
                let imageScale: CGFloat = 1 / visibleHeight  // ~1.72x zoom
                let offsetY = geometry.size.height * (0.5 - (cropTop + cropBottom) / 2) * imageScale

                ZStack {
                    // Professional body silhouette from BodyMapPicker
                    // Cropped to show shoulders to mid-thigh
                    Image("bodyFront")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .saturation(0)
                        .opacity(0.85)
                        .colorMultiply(Color(red: 0.92, green: 0.94, blue: 0.96))
                        .scaleEffect(x: selectedView == .back ? -imageScale : imageScale, y: imageScale)
                        .offset(y: offsetY)

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
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
            }
            // New aspect ratio for cropped view: original was 353:908, now showing 58% of height
            .aspectRatio(353.0 / (908.0 * visibleHeight), contentMode: .fit)
        }
        .frame(maxWidth: .infinity)
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
                // Zone fill with border
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.85))
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(color.opacity(0.6), lineWidth: 1)

                if recommended {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.white, lineWidth: 2)
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.appHighlight, lineWidth: 2.5)
                }

                Text(zone.location.zoneLabel)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)
            }
        }
        .buttonStyle(.plain)
        .frame(width: w, height: h)
        .position(x: x, y: y)
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
