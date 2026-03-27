//
//  MedicalReportGenerator.swift
//  OmniSiteTracker
//
//  Generates professional medical reports for healthcare providers.
//  Creates PDF documents with placement history, statistics, and recommendations.
//

import Foundation
import SwiftUI
import PDFKit
import UIKit

/// Generates comprehensive medical reports for pump site placements
@MainActor
final class MedicalReportGenerator {
    // MARK: - Properties

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - Report Generation

    /// Generates a PDF medical report
    /// - Parameters:
    ///   - placements: All placement logs to include
    ///   - settings: User settings for context
    ///   - patientName: Optional patient name for the report
    ///   - startDate: Start of report period
    ///   - endDate: End of report period
    /// - Returns: PDF data if successful
    func generateReport(
        placements: [PlacementLog],
        settings: UserSettings,
        patientName: String?,
        startDate: Date,
        endDate: Date
    ) -> Data? {
        // Filter placements to date range
        let filteredPlacements = placements.filter {
            $0.placedAt >= startDate && $0.placedAt <= endDate
        }.sorted { $0.placedAt > $1.placedAt }

        // Create PDF
        let pdfMetaData = [
            kCGPDFContextCreator: "OmniSite Tracker",
            kCGPDFContextAuthor: "OmniSite Tracker App",
            kCGPDFContextTitle: "Pump Site Placement Report"
        ]

        let pageWidth: CGFloat = 612  // US Letter width in points
        let pageHeight: CGFloat = 792 // US Letter height in points
        let margin: CGFloat = 50

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)

        let data = renderer.pdfData { context in
            // Page 1: Summary
            context.beginPage()
            var yPosition = drawHeader(context: context, pageWidth: pageWidth, margin: margin, patientName: patientName, startDate: startDate, endDate: endDate)

            yPosition = drawSummarySection(context: context, placements: filteredPlacements, settings: settings, margin: margin, yPosition: yPosition, pageWidth: pageWidth)

            yPosition = drawRotationAnalysis(context: context, placements: filteredPlacements, settings: settings, margin: margin, yPosition: yPosition, pageWidth: pageWidth)

            // Page 2+: Detailed History
            yPosition = drawPlacementHistory(context: context, placements: filteredPlacements, margin: margin, yPosition: yPosition, pageWidth: pageWidth, pageHeight: pageHeight)

            // Footer on last page
            drawFooter(context: context, pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)
        }

        return data
    }

    // MARK: - Drawing Methods

    private func drawHeader(context: UIGraphicsPDFRendererContext, pageWidth: CGFloat, margin: CGFloat, patientName: String?, startDate: Date, endDate: Date) -> CGFloat {
        var yPosition: CGFloat = margin

        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        let title = "Insulin Pump Site Placement Report"
        title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
        yPosition += 35

        // Subtitle with date range
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]
        let subtitle = "Report Period: \(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
        subtitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: subtitleAttributes)
        yPosition += 20

        // Patient name if provided
        if let name = patientName, !name.isEmpty {
            let patientAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.black
            ]
            "Patient: \(name)".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: patientAttributes)
            yPosition += 25
        }

        // Divider line
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: yPosition))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
        UIColor.lightGray.setStroke()
        path.stroke()
        yPosition += 20

        return yPosition
    }

    private func drawSummarySection(context: UIGraphicsPDFRendererContext, placements: [PlacementLog], settings: UserSettings, margin: CGFloat, yPosition: CGFloat, pageWidth: CGFloat) -> CGFloat {
        var y = yPosition

        // Section title
        let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        "Summary Statistics".draw(at: CGPoint(x: margin, y: y), withAttributes: sectionTitleAttributes)
        y += 25

        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]

        // Calculate statistics
        let totalPlacements = placements.count
        let uniqueSites = Set(placements.compactMap { $0.locationRawValue }).count
        let customSitePlacements = placements.filter { $0.isCustomSite }.count
        let averageDaysBetween = calculateAverageDaysBetweenPlacements(placements: placements)

        // Draw statistics
        let stats = [
            "Total Placements: \(totalPlacements)",
            "Unique Body Sites Used: \(uniqueSites) of 9",
            "Custom Site Placements: \(customSitePlacements)",
            "Average Days Between Placements: \(String(format: "%.1f", averageDaysBetween))",
            "Configured Minimum Rest Days: \(settings.minimumRestDays)"
        ]

        for stat in stats {
            stat.draw(at: CGPoint(x: margin + 20, y: y), withAttributes: bodyAttributes)
            y += 18
        }

        y += 15
        return y
    }

    private func drawRotationAnalysis(context: UIGraphicsPDFRendererContext, placements: [PlacementLog], settings: UserSettings, margin: CGFloat, yPosition: CGFloat, pageWidth: CGFloat) -> CGFloat {
        var y = yPosition

        // Section title
        let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        "Site Distribution Analysis".draw(at: CGPoint(x: margin, y: y), withAttributes: sectionTitleAttributes)
        y += 25

        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.black
        ]

        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.black
        ]

        // Table header
        "Body Site".draw(at: CGPoint(x: margin + 20, y: y), withAttributes: headerAttributes)
        "Count".draw(at: CGPoint(x: margin + 200, y: y), withAttributes: headerAttributes)
        "Percentage".draw(at: CGPoint(x: margin + 280, y: y), withAttributes: headerAttributes)
        "Last Used".draw(at: CGPoint(x: margin + 380, y: y), withAttributes: headerAttributes)
        y += 18

        // Count placements by location
        var locationCounts: [String: (count: Int, lastUsed: Date?)] = [:]
        for location in BodyLocation.allCases {
            locationCounts[location.displayName] = (0, nil)
        }

        for placement in placements {
            if let location = placement.location {
                let name = location.displayName
                var current = locationCounts[name] ?? (0, nil)
                current.count += 1
                if current.lastUsed == nil || (placement.placedAt > current.lastUsed!) {
                    current.lastUsed = placement.placedAt
                }
                locationCounts[name] = current
            }
        }

        let total = placements.count

        // Sort by count
        let sortedLocations = locationCounts.sorted { $0.value.count > $1.value.count }

        for (name, data) in sortedLocations {
            let percentage = total > 0 ? Double(data.count) / Double(total) * 100 : 0
            let lastUsedStr = data.lastUsed != nil ? dateFormatter.string(from: data.lastUsed!) : "Never"

            name.draw(at: CGPoint(x: margin + 20, y: y), withAttributes: bodyAttributes)
            "\(data.count)".draw(at: CGPoint(x: margin + 200, y: y), withAttributes: bodyAttributes)
            String(format: "%.1f%%", percentage).draw(at: CGPoint(x: margin + 280, y: y), withAttributes: bodyAttributes)
            lastUsedStr.draw(at: CGPoint(x: margin + 380, y: y), withAttributes: bodyAttributes)
            y += 16
        }

        y += 15

        // Rotation compliance
        let compliance = calculateRotationCompliance(placements: placements, minRestDays: settings.minimumRestDays)
        let complianceColor: UIColor = compliance >= 80 ? .systemGreen : (compliance >= 50 ? .systemOrange : .systemRed)

        let complianceAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: complianceColor
        ]

        "Rotation Compliance Score: \(String(format: "%.0f%%", compliance))".draw(at: CGPoint(x: margin + 20, y: y), withAttributes: complianceAttributes)
        y += 30

        return y
    }

    private func drawPlacementHistory(context: UIGraphicsPDFRendererContext, placements: [PlacementLog], margin: CGFloat, yPosition: CGFloat, pageWidth: CGFloat, pageHeight: CGFloat) -> CGFloat {
        var y = yPosition

        // Check if we need a new page
        if y > pageHeight - 150 {
            context.beginPage()
            y = margin
        }

        // Section title
        let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        "Detailed Placement History".draw(at: CGPoint(x: margin, y: y), withAttributes: sectionTitleAttributes)
        y += 25

        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: UIColor.black
        ]

        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.black
        ]

        // Table header
        "Date & Time".draw(at: CGPoint(x: margin + 10, y: y), withAttributes: headerAttributes)
        "Location".draw(at: CGPoint(x: margin + 140, y: y), withAttributes: headerAttributes)
        "Notes".draw(at: CGPoint(x: margin + 300, y: y), withAttributes: headerAttributes)
        y += 16

        // Draw divider
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        UIColor.lightGray.setStroke()
        path.stroke()
        y += 5

        // Placement rows
        for placement in placements {
            // Check for page break
            if y > pageHeight - 60 {
                drawFooter(context: context, pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)
                context.beginPage()
                y = margin

                // Redraw header on new page
                "Detailed Placement History (continued)".draw(at: CGPoint(x: margin, y: y), withAttributes: sectionTitleAttributes)
                y += 25

                "Date & Time".draw(at: CGPoint(x: margin + 10, y: y), withAttributes: headerAttributes)
                "Location".draw(at: CGPoint(x: margin + 140, y: y), withAttributes: headerAttributes)
                "Notes".draw(at: CGPoint(x: margin + 300, y: y), withAttributes: headerAttributes)
                y += 16
            }

            let dateStr = dateTimeFormatter.string(from: placement.placedAt)
            let locationStr = placement.locationRawValue ?? placement.customSiteName ?? "Unknown"
            let noteStr = placement.note ?? "—"

            dateStr.draw(at: CGPoint(x: margin + 10, y: y), withAttributes: bodyAttributes)
            locationStr.draw(at: CGPoint(x: margin + 140, y: y), withAttributes: bodyAttributes)

            // Truncate notes if too long
            let truncatedNote = noteStr.count > 40 ? String(noteStr.prefix(40)) + "..." : noteStr
            truncatedNote.draw(at: CGPoint(x: margin + 300, y: y), withAttributes: bodyAttributes)

            y += 14
        }

        return y
    }

    private func drawFooter(context: UIGraphicsPDFRendererContext, pageWidth: CGFloat, pageHeight: CGFloat, margin: CGFloat) {
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.gray
        ]

        let footerY = pageHeight - 30
        let generatedText = "Generated by OmniSite Tracker on \(dateFormatter.string(from: .now))"
        generatedText.draw(at: CGPoint(x: margin, y: footerY), withAttributes: footerAttributes)

        let disclaimer = "This report is for informational purposes. Consult your healthcare provider for medical advice."
        disclaimer.draw(at: CGPoint(x: margin, y: footerY + 12), withAttributes: footerAttributes)
    }

    // MARK: - Calculation Helpers

    private func calculateAverageDaysBetweenPlacements(placements: [PlacementLog]) -> Double {
        guard placements.count >= 2 else { return 0 }

        let sortedPlacements = placements.sorted { $0.placedAt < $1.placedAt }
        var totalDays = 0

        for i in 1..<sortedPlacements.count {
            let days = Calendar.current.dateComponents([.day], from: sortedPlacements[i-1].placedAt, to: sortedPlacements[i].placedAt).day ?? 0
            totalDays += days
        }

        return Double(totalDays) / Double(sortedPlacements.count - 1)
    }

    private func calculateRotationCompliance(placements: [PlacementLog], minRestDays: Int) -> Double {
        guard placements.count >= 2 else { return 100 }

        var violations = 0
        var checks = 0

        var lastUsedByLocation: [String: Date] = [:]

        let sortedPlacements = placements.sorted { $0.placedAt < $1.placedAt }

        for placement in sortedPlacements {
            let location = placement.locationRawValue ?? placement.customSiteId?.uuidString ?? ""

            if let lastUsed = lastUsedByLocation[location] {
                let daysSince = Calendar.current.dateComponents([.day], from: lastUsed, to: placement.placedAt).day ?? 0
                checks += 1
                if daysSince < minRestDays {
                    violations += 1
                }
            }

            lastUsedByLocation[location] = placement.placedAt
        }

        guard checks > 0 else { return 100 }
        return (1.0 - Double(violations) / Double(checks)) * 100
    }
}

// MARK: - Share Sheet

/// View for sharing the generated report
struct ReportShareSheet: UIViewControllerRepresentable {
    let data: Data
    let filename: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: tempURL)

        let activityVC = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )

        return activityVC
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
