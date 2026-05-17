//
//  PlacementLog.swift
//  OmniSiteTracker
//
//  SwiftData model for persisting insulin pump placement records.
//

import Foundation
import SwiftData

/// Represents a single pump placement event stored in the local database.
/// Uses SwiftData for automatic persistence with iCloud sync support.
@Model
final class PlacementLog {
    /// Unique identifier for this placement record
    var id: UUID

    /// The body location where the pump was placed (for default sites)
    /// Stored as raw string value for SwiftData compatibility
    /// Will be nil for custom site placements
    var locationRawValue: String?

    /// The date and time when the pump was placed
    var placedAt: Date

    /// Optional user note for this placement (e.g., "Site felt tender")
    var note: String?

    /// Optional ID of the custom site (for custom site placements)
    /// Will be nil for default BodyLocation placements
    var customSiteId: UUID?

    /// Optional name of the custom site for display purposes
    /// Stored separately to preserve history even if custom site is deleted
    var customSiteName: String?

    // MARK: - Additional Metadata

    /// Whether this was the recommended site when placed
    var wasRecommended: Bool = false

    /// Whether a reminder was scheduled for this placement
    var reminderScheduled: Bool = false

    /// Filename of attached photo (if any)
    var photoFileName: String?

    /// ID of the user profile this placement belongs to
    var profileId: UUID?

    // MARK: - iCloud Sync

    /// Whether this record needs to be synced to iCloud
    var needsCloudSync: Bool = true

    /// When this record was last synced to iCloud
    var cloudSyncedAt: Date?

    /// Computed property to access the strongly-typed BodyLocation enum
    /// Returns nil for custom site placements
    var location: BodyLocation? {
        get {
            guard let rawValue = locationRawValue else { return nil }
            return BodyLocation(rawValue: rawValue)
        }
        set {
            locationRawValue = newValue?.rawValue
        }
    }

    /// Computed property to determine if this is a custom site placement
    var isCustomSite: Bool {
        customSiteId != nil
    }

    /// Initializes a new placement log entry for a default body location
    /// - Parameters:
    ///   - location: The body location where the pump was placed
    ///   - placedAt: The date/time of placement (defaults to current time)
    ///   - note: Optional note about this placement
    init(location: BodyLocation, placedAt: Date = .now, note: String? = nil) {
        self.id = UUID()
        self.locationRawValue = location.rawValue
        self.placedAt = placedAt
        self.note = note
        self.customSiteId = nil
        self.customSiteName = nil
    }

    /// Initializes a new placement log entry for a custom site
    /// - Parameters:
    ///   - customSite: The custom site where the pump was placed
    ///   - placedAt: The date/time of placement (defaults to current time)
    ///   - note: Optional note about this placement
    init(customSite: CustomSite, placedAt: Date = .now, note: String? = nil) {
        self.id = UUID()
        self.locationRawValue = nil
        self.placedAt = placedAt
        self.note = note
        self.customSiteId = customSite.id
        self.customSiteName = customSite.name
    }

    /// Initializes a placement with a specific ID (used for CloudKit sync)
    /// - Parameters:
    ///   - id: The unique identifier
    ///   - placedAt: The date/time of placement
    init(id: UUID, placedAt: Date) {
        self.id = id
        self.placedAt = placedAt
    }
}

// MARK: - Convenience Extensions

extension PlacementLog {
    /// Returns the number of days since this placement
    var daysSincePlacement: Int {
        Calendar.current.dateComponents([.day], from: placedAt, to: .now).day ?? 0
    }

    /// Returns a human-readable relative time string
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: placedAt, relativeTo: .now)
    }

    /// Returns a formatted date string for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: placedAt)
    }
}
