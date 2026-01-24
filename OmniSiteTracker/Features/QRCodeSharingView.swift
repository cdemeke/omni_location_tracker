//
//  QRCodeSharingView.swift
//  OmniSiteTracker
//
//  QR code generation and scanning for data sharing
//

import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins
import AVFoundation

@MainActor
@Observable
final class QRCodeManager {
    static let shared = QRCodeManager()
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    func generateSiteQRCode(site: String, date: Date) -> UIImage? {
        let payload = SiteQRPayload(site: site, date: date)
        guard let jsonData = try? JSONEncoder().encode(payload),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        return generateQRCode(from: "omnitracker://site?\(jsonString)")
    }
    
    func generateProfileQRCode(profileId: String, name: String) -> UIImage? {
        let payload = ProfileQRPayload(profileId: profileId, name: name)
        guard let jsonData = try? JSONEncoder().encode(payload),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        return generateQRCode(from: "omnitracker://profile?\(jsonString)")
    }
    
    func parseQRCode(_ string: String) -> QRPayload? {
        guard string.hasPrefix("omnitracker://") else { return nil }
        
        if string.contains("site?") {
            let jsonString = string.replacingOccurrences(of: "omnitracker://site?", with: "")
            if let data = jsonString.data(using: .utf8),
               let payload = try? JSONDecoder().decode(SiteQRPayload.self, from: data) {
                return .site(payload)
            }
        } else if string.contains("profile?") {
            let jsonString = string.replacingOccurrences(of: "omnitracker://profile?", with: "")
            if let data = jsonString.data(using: .utf8),
               let payload = try? JSONDecoder().decode(ProfileQRPayload.self, from: data) {
                return .profile(payload)
            }
        }
        
        return nil
    }
}

struct SiteQRPayload: Codable {
    let site: String
    let date: Date
}

struct ProfileQRPayload: Codable {
    let profileId: String
    let name: String
}

enum QRPayload {
    case site(SiteQRPayload)
    case profile(ProfileQRPayload)
}

struct QRCodeGeneratorView: View {
    @State private var manager = QRCodeManager.shared
    @State private var selectedSite = "Abdomen - Left"
    @State private var qrImage: UIImage?
    @State private var showShareSheet = false
    
    let sites = ["Abdomen - Left", "Abdomen - Right", "Upper Arm - Left", "Upper Arm - Right", "Thigh - Left", "Thigh - Right"]
    
    var body: some View {
        VStack(spacing: 24) {
            // QR Code Display
            if let image = qrImage {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 8)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray5))
                    .frame(width: 250, height: 250)
                    .overlay {
                        VStack {
                            Image(systemName: "qrcode")
                                .font(.largeTitle)
                            Text("Select a site to generate")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
            }
            
            // Site Picker
            VStack(alignment: .leading) {
                Text("Select Site")
                    .font(.headline)
                
                Picker("Site", selection: $selectedSite) {
                    ForEach(sites, id: \.self) { site in
                        Text(site).tag(site)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Actions
            HStack(spacing: 20) {
                Button {
                    generateQRCode()
                } label: {
                    Label("Generate", systemImage: "qrcode")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    showShareSheet = true
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(qrImage == nil)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Generate QR Code")
        .sheet(isPresented: $showShareSheet) {
            if let image = qrImage {
                ShareSheet(activityItems: [image])
            }
        }
        .onAppear {
            generateQRCode()
        }
    }
    
    private func generateQRCode() {
        qrImage = manager.generateSiteQRCode(site: selectedSite, date: Date())
    }
}

struct QRCodeScannerView: View {
    @State private var isScanning = false
    @State private var scannedCode: String?
    @State private var parsedPayload: QRPayload?
    @State private var showResult = false
    
    var body: some View {
        VStack {
            if isScanning {
                QRScannerRepresentable { code in
                    scannedCode = code
                    parsedPayload = QRCodeManager.shared.parseQRCode(code)
                    isScanning = false
                    showResult = true
                }
                .ignoresSafeArea()
            } else {
                VStack(spacing: 24) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 100))
                        .foregroundStyle(.blue)
                    
                    Text("Scan a QR code to import site data")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    
                    Button("Start Scanning") {
                        isScanning = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .navigationTitle("Scan QR Code")
        .alert("QR Code Scanned", isPresented: $showResult) {
            Button("Import") {
                // Handle import
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let payload = parsedPayload {
                switch payload {
                case .site(let site):
                    Text("Site: \(site.site)\nDate: \(site.date.formatted())")
                case .profile(let profile):
                    Text("Profile: \(profile.name)")
                }
            } else {
                Text("Unknown QR code format")
            }
        }
    }
}

struct QRScannerRepresentable: UIViewControllerRepresentable {
    let completion: (String) -> Void
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.completion = completion
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var completion: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScanner()
    }
    
    private func setupScanner() {
        let session = AVCaptureSession()
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        session.addInput(input)
        
        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession = session
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = object.stringValue else {
            return
        }
        
        captureSession?.stopRunning()
        completion?(code)
    }
}

struct QRCodeSharingView: View {
    var body: some View {
        List {
            Section {
                NavigationLink(destination: QRCodeGeneratorView()) {
                    Label("Generate QR Code", systemImage: "qrcode")
                }
                
                NavigationLink(destination: QRCodeScannerView()) {
                    Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                }
            }
            
            Section("About QR Sharing") {
                Label("Share site rotations instantly", systemImage: "bolt")
                Label("Import from other users", systemImage: "person.2")
                Label("Works offline", systemImage: "wifi.slash")
            }
        }
        .navigationTitle("QR Code Sharing")
    }
}

#Preview {
    NavigationStack {
        QRCodeSharingView()
    }
}
