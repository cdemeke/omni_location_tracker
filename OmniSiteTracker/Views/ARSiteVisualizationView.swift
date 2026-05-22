//
//  ARSiteVisualizationView.swift
//  OmniSiteTracker
//
//  AR visualization of pump sites on the body.
//

import SwiftUI
import ARKit
import RealityKit

struct ARSiteVisualizationView: View {
    @State private var selectedSite: String?
    @State private var showingAR = false
    
    let sites = [
        ("Abdomen Left", CGPoint(x: 0.35, y: 0.45)),
        ("Abdomen Right", CGPoint(x: 0.65, y: 0.45)),
        ("Left Thigh", CGPoint(x: 0.35, y: 0.7)),
        ("Right Thigh", CGPoint(x: 0.65, y: 0.7)),
        ("Left Arm", CGPoint(x: 0.15, y: 0.35)),
        ("Right Arm", CGPoint(x: 0.85, y: 0.35)),
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Site Visualization")
                .font(.title2)
                .fontWeight(.bold)
            
            // Body diagram
            ZStack {
                // Body outline
                Image(systemName: "figure.arms.open")
                    .font(.system(size: 200))
                    .foregroundColor(.gray.opacity(0.3))
                
                // Site markers
                ForEach(sites, id: \.0) { site in
                    SiteMarker(name: site.0, isSelected: selectedSite == site.0)
                        .position(x: site.1.x * 300, y: site.1.y * 400)
                        .onTapGesture {
                            selectedSite = site.0
                        }
                }
            }
            .frame(width: 300, height: 400)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)
            
            if let site = selectedSite {
                VStack(spacing: 8) {
                    Text(site)
                        .font(.headline)
                    Text("Tap to view in AR")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if ARWorldTrackingConfiguration.isSupported {
                Button(action: { showingAR = true }) {
                    Label("View in AR", systemImage: "arkit")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            } else {
                Text("AR not supported on this device")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .fullScreenCover(isPresented: $showingAR) {
            ARViewContainer(selectedSite: selectedSite ?? "Abdomen Left")
        }
    }
}

struct SiteMarker: View {
    let name: String
    let isSelected: Bool
    
    var body: some View {
        Circle()
            .fill(isSelected ? Color.blue : Color.green)
            .frame(width: isSelected ? 30 : 20, height: isSelected ? 30 : 20)
            .overlay {
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                }
            }
            .shadow(radius: 4)
            .animation(.spring(), value: isSelected)
    }
}

struct ARViewContainer: View {
    let selectedSite: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            ARViewRepresentable()
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }
                
                Spacer()
                
                Text("Point camera at body to visualize \(selectedSite)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                    .padding()
            }
        }
    }
}

struct ARViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)
        
        // Add a simple anchor for visualization
        let anchor = AnchorEntity(plane: .any)
        let sphere = ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [SimpleMaterial(color: .green, isMetallic: false)])
        anchor.addChild(sphere)
        arView.scene.addAnchor(anchor)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

#Preview {
    ARSiteVisualizationView()
}
