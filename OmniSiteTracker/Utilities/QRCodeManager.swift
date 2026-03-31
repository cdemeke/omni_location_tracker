//
//  QRCodeManager.swift
//  OmniSiteTracker
//
//  Generates QR codes for sharing site history and settings.
//

import Foundation
import CoreImage.CIFilterBuiltins
import SwiftUI

@MainActor
@Observable
final class QRCodeManager {
    static let shared = QRCodeManager()
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    private init() {}
    
    func generateQRCode(from data: Data) -> UIImage? {
        filter.message = data
        filter.correctionLevel = "M"
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let scale = 10.0
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = outputImage.transformed(by: transform)
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    func generateShareableData(placements: [PlacementData], settings: ShareableSettings) throws -> Data {
        let shareData = ShareableData(
            version: "1.0",
            createdAt: .now,
            placements: placements,
            settings: settings
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(shareData)
    }
    
    func parseQRData(_ data: Data) throws -> ShareableData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ShareableData.self, from: data)
    }
}

struct ShareableData: Codable {
    let version: String
    let createdAt: Date
    let placements: [PlacementData]
    let settings: ShareableSettings
}

struct PlacementData: Codable {
    let site: String
    let date: Date
    let note: String?
}

struct ShareableSettings: Codable {
    let minimumRestDays: Int
    let enabledSites: [String]
}

struct QRCodeView: View {
    let data: Data
    @State private var qrImage: UIImage?
    
    var body: some View {
        VStack(spacing: 16) {
            if let image = qrImage {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
            } else {
                ProgressView()
                    .frame(width: 250, height: 250)
            }
            
            Text("Scan to import data")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear {
            qrImage = QRCodeManager.shared.generateQRCode(from: data)
        }
    }
}

struct QRScannerView: View {
    @Binding var scannedData: Data?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("Point camera at QR code")
                .font(.headline)
                .padding()
            
            // Camera view placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black)
                .frame(height: 400)
                .overlay {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 100))
                        .foregroundColor(.white.opacity(0.5))
                }
            
            Button("Cancel") {
                dismiss()
            }
            .padding()
        }
    }
}
