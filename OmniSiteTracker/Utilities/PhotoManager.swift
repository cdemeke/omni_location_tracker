//
//  PhotoManager.swift
//  OmniSiteTracker
//
//  Manages photo storage and retrieval for pump site documentation.
//  Photos are stored locally in the app's documents directory.
//

import Foundation
import SwiftUI
import UIKit

/// Manages photo storage for pump site placements
@MainActor
final class PhotoManager {
    // MARK: - Singleton

    static let shared = PhotoManager()

    // MARK: - Properties

    /// Directory for storing placement photos
    private var photosDirectory: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photosDir = documentsDirectory.appendingPathComponent("PlacementPhotos", isDirectory: true)

        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: photosDir.path) {
            try? FileManager.default.createDirectory(at: photosDir, withIntermediateDirectories: true)
        }

        return photosDir
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Photo Operations

    /// Saves a photo for a placement
    /// - Parameters:
    ///   - image: The image to save
    ///   - placementId: The UUID of the placement
    /// - Returns: The filename if saved successfully, nil otherwise
    func savePhoto(_ image: UIImage, for placementId: UUID) -> String? {
        let fileName = "\(placementId.uuidString).jpg"
        let fileURL = photosDirectory.appendingPathComponent(fileName)

        // Compress and convert to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }

        do {
            try imageData.write(to: fileURL)
            return fileName
        } catch {
            print("Failed to save photo: \(error)")
            return nil
        }
    }

    /// Loads a photo by filename
    /// - Parameter fileName: The filename of the photo
    /// - Returns: The UIImage if found, nil otherwise
    func loadPhoto(fileName: String) -> UIImage? {
        let fileURL = photosDirectory.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        guard let imageData = try? Data(contentsOf: fileURL) else {
            return nil
        }

        return UIImage(data: imageData)
    }

    /// Checks if a photo exists
    /// - Parameter fileName: The filename to check
    /// - Returns: True if the photo exists
    func photoExists(fileName: String) -> Bool {
        let fileURL = photosDirectory.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// Deletes a photo
    /// - Parameter fileName: The filename to delete
    func deletePhoto(fileName: String) {
        let fileURL = photosDirectory.appendingPathComponent(fileName)

        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            print("Failed to delete photo: \(error)")
        }
    }

    /// Gets the URL for a photo
    /// - Parameter fileName: The filename
    /// - Returns: The file URL if it exists
    func getPhotoURL(fileName: String) -> URL? {
        let fileURL = photosDirectory.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        return fileURL
    }

    /// Creates a thumbnail from an image
    /// - Parameters:
    ///   - image: The source image
    ///   - size: The target size for the thumbnail
    /// - Returns: A thumbnail image
    func createThumbnail(from image: UIImage, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { _ in
            let aspectWidth = size.width / image.size.width
            let aspectHeight = size.height / image.size.height
            let aspectRatio = max(aspectWidth, aspectHeight)

            let scaledWidth = image.size.width * aspectRatio
            let scaledHeight = image.size.height * aspectRatio
            let x = (size.width - scaledWidth) / 2
            let y = (size.height - scaledHeight) / 2

            image.draw(in: CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight))
        }
    }

    /// Calculates total storage used by photos
    /// - Returns: Size in bytes
    func totalStorageUsed() -> Int64 {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: photosDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        ) else {
            return 0
        }

        return contents.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size)
        }
    }

    /// Formats storage size for display
    /// - Parameter bytes: Size in bytes
    /// - Returns: Formatted string (e.g., "5.2 MB")
    func formattedStorageSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    /// Clears all placement photos
    func clearAllPhotos() {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: photosDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            return
        }

        for url in contents {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
