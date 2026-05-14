//
//  SharedDataManager.swift
//  OmniSiteTracker
//
//  Manages data sharing between the main app and widgets.
//  Uses App Groups for cross-target data access.
//

import Foundation
import SwiftData
import WidgetKit

/// Manages shared data for widgets
@MainActor
final class SharedDataManager {
    // MARK: - Singleton

    static let shared = SharedDataManager()

    // MARK: - Properties

    /// App Group identifier for shared container
    private let appGroupId = "group.com.omnisite.tracker"

    /// User defaults for quick widget data
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Data Update

    /// Updates shared data for widgets after a placement change
    /// - Parameter context: The SwiftData model context
    func updateWidgetData(context: ModelContext) {
        guard let defaults = sharedDefaults else { return }

        // Get placements
        let descriptor = FetchDescriptor<PlacementLog>(
            sortBy: [SortDescriptor(\.placedAt, order: .reverse)]
        )
        let placements = (try? context.fetch(descriptor)) ?? []

        // Get settings
        let settings = UserSettings.getOrCreate(context: context)

        // Calculate recommendation
        let recommendation = calculateRecommendation(placements: placements, minRestDays: settings.minimumRestDays)

        // Store recommendation
        if let rec = recommendation {
            defaults.set(rec.siteName, forKey: "recommendedSite")
            defaults.set(rec.daysSinceUse, forKey: "recommendedDays")
        } else {
            defaults.removeObject(forKey: "recommendedSite")
            defaults.removeObject(forKey: "recommendedDays")
        }

        // Store last placement
        if let last = placements.first {
            defaults.set(last.locationRawValue ?? last.customSiteName, forKey: "lastPlacementSite")
            defaults.set(last.placedAt, forKey: "lastPlacementDate")
        } else {
            defaults.removeObject(forKey: "lastPlacementSite")
            defaults.removeObject(forKey: "lastPlacementDate")
        }

        // Store streak
        let streak = calculateStreak(placements: placements)
        defaults.set(streak, forKey: "currentStreak")

        // Store site statuses
        let statuses = calculateSiteStatuses(placements: placements, minRestDays: settings.minimumRestDays)
        if let encoded = try? JSONEncoder().encode(statuses) {
            defaults.set(encoded, forKey: "siteStatuses")
        }

        defaults.set(Date.now, forKey: "lastUpdate")

        // Reload widgets
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Data Retrieval (for widgets)

    /// Gets the current recommendation
    func getRecommendation() -> (siteName: String, daysSinceUse: Int?)? {
        guard let defaults = sharedDefaults,
              let siteName = defaults.string(forKey: "recommendedSite") else {
            return nil
        }

        let days = defaults.object(forKey: "recommendedDays") as? Int
        return (siteName, days)
    }

    /// Gets the last placement info
    func getLastPlacement() -> (siteName: String, date: Date)? {
        guard let defaults = sharedDefaults,
              let siteName = defaults.string(forKey: "lastPlacementSite"),
              let date = defaults.object(forKey: "lastPlacementDate") as? Date else {
            return nil
        }

        return (siteName, date)
    }

    /// Gets the current streak
    func getCurrentStreak() -> Int {
        sharedDefaults?.integer(forKey: "currentStreak") ?? 0
    }

    /// Gets all site statuses
    func getSiteStatuses() -> [SiteStatus] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: "siteStatuses"),
              let statuses = try? JSONDecoder().decode([CodableSiteStatus].self, from: data) else {
            return []
        }

        return statuses.map { SiteStatus(name: $0.name, daysSinceUse: $0.daysSinceUse, isReady: $0.isReady) }
    }

    // MARK: - Calculations

    private func calculateRecommendation(placements: [PlacementLog], minRestDays: Int) -> (siteName: String, daysSinceUse: Int?)? {
        // Build map of last used dates for each location
        var lastUsedDates: [String: Date] = [:]

        for placement in placements {
            let key = placement.locationRawValue ?? placement.customSiteName ?? ""
            if lastUsedDates[key] == nil {
                lastUsedDates[key] = placement.placedAt
            }
        }

        // Find best recommendation among default body locations
        let bodyLocations = ["abdomenRight", "abdomenLeft", "lowerAbdomen", "leftArm", "rightArm", "leftThigh", "rightThigh", "leftLowerBack", "rightLowerBack"]

        let locationDisplayNames: [String: String] = [
            "abdomenRight": "Abdomen Right",
            "abdomenLeft": "Abdomen Left",
            "lowerAbdomen": "Lower Abdomen",
            "leftArm": "Left Arm",
            "rightArm": "Right Arm",
            "leftThigh": "Left Thigh",
            "rightThigh": "Right Thigh",
            "leftLowerBack": "Left Lower Back",
            "rightLowerBack": "Right Lower Back"
        ]

        var bestLocation: String?
        var bestDays: Int?
        var maxDays = -1

        for location in bodyLocations {
            if let lastUsed = lastUsedDates[location] {
                let days = Calendar.current.dateComponents([.day], from: lastUsed, to: .now).day ?? 0
                if days >= minRestDays && days > maxDays {
                    maxDays = days
                    bestLocation = location
                    bestDays = days
                }
            } else {
                // Never used - this is the best choice
                return (locationDisplayNames[location] ?? location, nil)
            }
        }

        if let location = bestLocation {
            return (locationDisplayNames[location] ?? location, bestDays)
        }

        // If nothing is ready, return the one with most rest
        maxDays = -1
        for location in bodyLocations {
            if let lastUsed = lastUsedDates[location] {
                let days = Calendar.current.dateComponents([.day], from: lastUsed, to: .now).day ?? 0
                if days > maxDays {
                    maxDays = days
                    bestLocation = location
                    bestDays = days
                }
            }
        }

        if let location = bestLocation {
            return (locationDisplayNames[location] ?? location, bestDays)
        }

        return ("Abdomen Right", nil)
    }

    private func calculateStreak(placements: [PlacementLog]) -> Int {
        guard !placements.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedPlacements = placements.sorted { $0.placedAt > $1.placedAt }

        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        guard let mostRecent = sortedPlacements.first else { return 0 }
        let mostRecentDay = calendar.startOfDay(for: mostRecent.placedAt)

        guard mostRecentDay >= yesterday else { return 0 }

        var streak = 0
        var checkDate = mostRecentDay
        var placementDates: Set<Date> = []

        for placement in sortedPlacements {
            placementDates.insert(calendar.startOfDay(for: placement.placedAt))
        }

        while placementDates.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        return streak
    }

    private func calculateSiteStatuses(placements: [PlacementLog], minRestDays: Int) -> [CodableSiteStatus] {
        let bodyLocations = ["abdomenRight", "abdomenLeft", "lowerAbdomen", "leftArm", "rightArm", "leftThigh", "rightThigh", "leftLowerBack", "rightLowerBack"]

        let locationDisplayNames: [String: String] = [
            "abdomenRight": "Abdomen R",
            "abdomenLeft": "Abdomen L",
            "lowerAbdomen": "Lower Abd",
            "leftArm": "Left Arm",
            "rightArm": "Right Arm",
            "leftThigh": "Left Thigh",
            "rightThigh": "Right Thigh",
            "leftLowerBack": "LB Left",
            "rightLowerBack": "LB Right"
        ]

        // Build map of last used dates
        var lastUsedDates: [String: Date] = [:]
        for placement in placements {
            let key = placement.locationRawValue ?? ""
            if lastUsedDates[key] == nil && !key.isEmpty {
                lastUsedDates[key] = placement.placedAt
            }
        }

        return bodyLocations.map { location in
            let name = locationDisplayNames[location] ?? location
            if let lastUsed = lastUsedDates[location] {
                let days = Calendar.current.dateComponents([.day], from: lastUsed, to: .now).day ?? 0
                return CodableSiteStatus(name: name, daysSinceUse: days, isReady: days >= minRestDays)
            } else {
                return CodableSiteStatus(name: name, daysSinceUse: nil, isReady: true)
            }
        }
    }
}

// MARK: - Codable Site Status

/// Codable version of SiteStatus for storage
struct CodableSiteStatus: Codable {
    let name: String
    let daysSinceUse: Int?
    let isReady: Bool
}

// MARK: - SiteStatus for Widget

/// Status of a single body site (used by widget)
struct SiteStatus: Identifiable {
    let id = UUID()
    let name: String
    let daysSinceUse: Int?
    let isReady: Bool
}
