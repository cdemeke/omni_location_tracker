//
//  DataExporter.swift
//  OmniSiteTracker
//
//  Handles exporting placement data to various formats.
//  Supports CSV, JSON, and PDF export with date range filtering.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers
import UIKit
import CoreGraphics

/// Manages export of placement data to various formats
@MainActor
final class DataExporter {
    // MARK: - Export Format

    enum ExportFormat: String, CaseIterable, Identifiable {
        case csv = "CSV"
        case json = "JSON"
        case pdf = "PDF"

        var id: String { rawValue }

        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .json: return "json"
            case .pdf: return "pdf"
            }
        }

        var mimeType: String {
            switch self {
            case .csv: return "text/csv"
            case .json: return "application/json"
            case .pdf: return "application/pdf"
            }
        }

        var utType: UTType {
            switch self {
            case .csv: return .commaSeparatedText
            case .json: return .json
            case .pdf: return .pdf
            }
        }

        var description: String {
            switch self {
            case .csv: return "Spreadsheet-compatible format"
            case .json: return "For developers and backups"
            case .pdf: return "Printable report format"
            }
        }
    }

    // MARK: - Date Range

    enum DateRange: String, CaseIterable, Identifiable {
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
        case last90Days = "Last 90 Days"
        case last365Days = "Last Year"
        case allTime = "All Time"
        case custom = "Custom Range"

        var id: String { rawValue }

        var startDate: Date? {
            let calendar = Calendar.current
            switch self {
            case .last7Days:
                return calendar.date(byAdding: .day, value: -7, to: .now)
            case .last30Days:
                return calendar.date(byAdding: .day, value: -30, to: .now)
            case .last90Days:
                return calendar.date(byAdding: .day, value: -90, to: .now)
            case .last365Days:
                return calendar.date(byAdding: .year, value: -1, to: .now)
            case .allTime:
                return nil
            case .custom:
                return nil
            }
        }
    }

    // MARK: - Export Result

    struct ExportResult {
        let data: Data
        let filename: String
        let format: ExportFormat

        var url: URL? {
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(filename)
            do {
                try data.write(to: fileURL)
                return fileURL
            } catch {
                return nil
            }
        }
    }

    // MARK: - Export Methods

    /// Exports placements to the specified format
    static func export(
        placements: [PlacementLog],
        format: ExportFormat,
        includeNotes: Bool = true,
        includeMetadata: Bool = false
    ) throws -> ExportResult {
        let dateFormatter = ISO8601DateFormatter()
        let filename = "OmniSiteTracker_\(dateFormatter.string(from: .now)).\(format.fileExtension)"
            .replacingOccurrences(of: ":", with: "-")

        let data: Data
        switch format {
        case .csv:
            data = try exportToCSV(placements: placements, includeNotes: includeNotes)
        case .json:
            data = try exportToJSON(placements: placements, includeMetadata: includeMetadata)
        case .pdf:
            data = try exportToPDF(placements: placements, includeNotes: includeNotes)
        }

        return ExportResult(data: data, filename: filename, format: format)
    }

    // MARK: - CSV Export

    private static func exportToCSV(placements: [PlacementLog], includeNotes: Bool) throws -> Data {
        var csv = "Date,Time,Location,Site Type,Days Since Previous"
        if includeNotes {
            csv += ",Notes"
        }
        csv += "\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        for placement in placements.sorted(by: { $0.placedAt > $1.placedAt }) {
            let date = dateFormatter.string(from: placement.placedAt)
            let time = timeFormatter.string(from: placement.placedAt)
            let location = placement.locationRawValue ?? placement.customSiteName ?? "Unknown"
            let siteType = placement.isCustomSite ? "Custom" : "Default"
            let daysSince = String(placement.daysSincePlacement)

            var row = "\"\(date)\",\"\(time)\",\"\(location)\",\"\(siteType)\",\(daysSince)"

            if includeNotes {
                let note = placement.note?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
                row += ",\"\(note)\""
            }

            csv += row + "\n"
        }

        guard let data = csv.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }

        return data
    }

    // MARK: - JSON Export

    private static func exportToJSON(placements: [PlacementLog], includeMetadata: Bool) throws -> Data {
        let exportData = ExportData(
            exportedAt: .now,
            version: "1.0",
            placements: placements.map { placement in
                ExportPlacement(
                    id: placement.id.uuidString,
                    placedAt: placement.placedAt,
                    location: placement.locationRawValue,
                    customSiteName: placement.customSiteName,
                    customSiteId: placement.customSiteId?.uuidString,
                    note: placement.note,
                    isCustomSite: placement.isCustomSite
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        return try encoder.encode(exportData)
    }

    // MARK: - PDF Export

    private static func exportToPDF(placements: [PlacementLog], includeNotes: Bool) throws -> Data {
        let pageWidth: CGFloat = 612 // US Letter width in points
        let pageHeight: CGFloat = 792 // US Letter height in points
        let margin: CGFloat = 50

        let pdfData = NSMutableData()

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: nil, nil) else {
            throw ExportError.pdfCreationFailed
        }

        var pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        var yPosition = pageHeight - margin

        func startNewPage() {
            context.endPage()
            context.beginPage(mediaBox: &pageRect)
            yPosition = pageHeight - margin
        }

        context.beginPage(mediaBox: &pageRect)

        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]

        let title = "OmniSite Tracker - Placement History"
        let titleSize = (title as NSString).size(withAttributes: titleAttributes)
        (title as NSString).draw(
            at: CGPoint(x: margin, y: yPosition - titleSize.height),
            withAttributes: titleAttributes
        )
        yPosition -= titleSize.height + 20

        // Export date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short

        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.gray
        ]

        let subtitle = "Exported on \(dateFormatter.string(from: .now))"
        let subtitleSize = (subtitle as NSString).size(withAttributes: subtitleAttributes)
        (subtitle as NSString).draw(
            at: CGPoint(x: margin, y: yPosition - subtitleSize.height),
            withAttributes: subtitleAttributes
        )
        yPosition -= subtitleSize.height + 30

        // Placements
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]

        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.darkGray
        ]

        let noteAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.italicSystemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]

        for placement in placements.sorted(by: { $0.placedAt > $1.placedAt }) {
            if yPosition < margin + 100 {
                startNewPage()
            }

            // Location header
            let location = placement.locationRawValue ?? placement.customSiteName ?? "Unknown Location"
            let locationSize = (location as NSString).size(withAttributes: headerAttributes)
            (location as NSString).draw(
                at: CGPoint(x: margin, y: yPosition - locationSize.height),
                withAttributes: headerAttributes
            )
            yPosition -= locationSize.height + 5

            // Date and details
            let details = "\(dateFormatter.string(from: placement.placedAt)) • \(placement.daysSincePlacement) days ago"
            let detailsSize = (details as NSString).size(withAttributes: bodyAttributes)
            (details as NSString).draw(
                at: CGPoint(x: margin, y: yPosition - detailsSize.height),
                withAttributes: bodyAttributes
            )
            yPosition -= detailsSize.height + 5

            // Note if present
            if includeNotes, let note = placement.note, !note.isEmpty {
                let noteSize = (note as NSString).size(withAttributes: noteAttributes)
                (note as NSString).draw(
                    at: CGPoint(x: margin, y: yPosition - noteSize.height),
                    withAttributes: noteAttributes
                )
                yPosition -= noteSize.height + 5
            }

            yPosition -= 15 // Spacing between entries
        }

        context.endPage()
        context.closePDF()

        return pdfData as Data
    }
}

// MARK: - Export Data Models

struct ExportData: Codable {
    let exportedAt: Date
    let version: String
    let placements: [ExportPlacement]
}

struct ExportPlacement: Codable {
    let id: String
    let placedAt: Date
    let location: String?
    let customSiteName: String?
    let customSiteId: String?
    let note: String?
    let isCustomSite: Bool
}

// MARK: - Import Support

extension DataExporter {
    /// Imports placements from JSON data
    static func importFromJSON(data: Data, modelContext: ModelContext) throws -> Int {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let exportData = try decoder.decode(ExportData.self, from: data)
        var importedCount = 0

        for exportPlacement in exportData.placements {
            // Check if placement already exists
            let existingId = UUID(uuidString: exportPlacement.id)
            if let existingId = existingId {
                let descriptor = FetchDescriptor<PlacementLog>(
                    predicate: #Predicate { $0.id == existingId }
                )
                let existing = try modelContext.fetch(descriptor)
                if !existing.isEmpty {
                    continue // Skip duplicates
                }
            }

            // Create new placement
            let placement = PlacementLog(
                id: existingId ?? UUID(),
                placedAt: exportPlacement.placedAt
            )
            placement.locationRawValue = exportPlacement.location
            placement.customSiteName = exportPlacement.customSiteName
            if let customSiteIdString = exportPlacement.customSiteId {
                placement.customSiteId = UUID(uuidString: customSiteIdString)
            }
            placement.note = exportPlacement.note

            modelContext.insert(placement)
            importedCount += 1
        }

        try modelContext.save()
        return importedCount
    }
}

// MARK: - Errors

enum ExportError: LocalizedError {
    case encodingFailed
    case pdfCreationFailed
    case importFailed(String)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode data"
        case .pdfCreationFailed:
            return "Failed to create PDF"
        case .importFailed(let message):
            return "Import failed: \(message)"
        }
    }
}
