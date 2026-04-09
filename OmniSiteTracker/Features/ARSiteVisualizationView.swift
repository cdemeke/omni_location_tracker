//
//  ARSiteVisualizationView.swift
//  OmniSiteTracker
//
//  AR visualization for injection site guidance
//

import SwiftUI
import ARKit
import RealityKit

@MainActor
@Observable
final class ARSiteManager {
    static let shared = ARSiteManager()
    
    private(set) var isARSupported = false
    private(set) var selectedSite: String?
    private(set) var showGuide = true
    
    let sitePositions: [String: SIMD3<Float>] = [
        "Abdomen - Left": SIMD3(-0.1, -0.2, 0.3),
        "Abdomen - Right": SIMD3(0.1, -0.2, 0.3),
        "Upper Arm - Left": SIMD3(-0.25, 0.1, 0.2),
        "Upper Arm - Right": SIMD3(0.25, 0.1, 0.2),
        "Thigh - Left": SIMD3(-0.1, -0.5, 0.3),
        "Thigh - Right": SIMD3(0.1, -0.5, 0.3)
    ]
    
    init() {
        isARSupported = ARWorldTrackingConfiguration.isSupported
    }
    
    func selectSite(_ site: String) {
        selectedSite = site
    }
    
    func toggleGuide() {
        showGuide.toggle()
    }
}

struct ARSiteVisualizationView: View {
    @State private var manager = ARSiteManager.shared
    @State private var showARView = false
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "arkit")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text("AR Site Guide")
                            .font(.headline)
                        Text(manager.isARSupported ? "AR Supported" : "AR Not Supported")
                            .font(.subheadline)
                            .foregroundStyle(manager.isARSupported ? .green : .red)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Select Site to Visualize") {
                ForEach(Array(manager.sitePositions.keys.sorted()), id: \.self) { site in
                    Button {
                        manager.selectSite(site)
                    } label: {
                        HStack {
                            Text(site)
                            Spacer()
                            if manager.selectedSite == site {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Section {
                Button {
                    showARView = true
                } label: {
                    Label("Launch AR View", systemImage: "arkit")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!manager.isARSupported || manager.selectedSite == nil)
            }
            
            Section("How It Works") {
                Label("Point camera at your body", systemImage: "camera.fill")
                Label("AR markers show injection sites", systemImage: "mappin.circle")
                Label("Follow the visual guide", systemImage: "arrow.right.circle")
                Label("Log site when complete", systemImage: "checkmark.circle")
            }
            
            Section("Settings") {
                Toggle("Show Guide Overlay", isOn: Binding(
                    get: { manager.showGuide },
                    set: { _ in manager.toggleGuide() }
                ))
            }
        }
        .navigationTitle("AR Visualization")
        .fullScreenCover(isPresented: $showARView) {
            ARViewContainer(site: manager.selectedSite ?? "")
        }
    }
}

struct ARViewContainer: View {
    let site: String
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmation = false
    
    var body: some View {
        ZStack {
            ARViewRepresentable(site: site)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding()
                    }
                    Spacer()
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Text("Point camera at: \(site)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.black.opacity(0.6))
                        .cornerRadius(12)
                    
                    Button {
                        showConfirmation = true
                    } label: {
                        Label("Log This Site", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .alert("Site Logged", isPresented: $showConfirmation) {
            Button("OK") { dismiss() }
        } message: {
            Text("\(site) has been logged successfully!")
        }
    }
}

struct ARViewRepresentable: UIViewRepresentable {
    let site: String
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)
        
        // Add AR content
        let anchor = AnchorEntity(plane: .horizontal)
        
        let sphere = MeshResource.generateSphere(radius: 0.05)
        let material = SimpleMaterial(color: .systemBlue, isMetallic: false)
        let entity = ModelEntity(mesh: sphere, materials: [material])
        
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

#Preview {
    NavigationStack {
        ARSiteVisualizationView()
    }
}
