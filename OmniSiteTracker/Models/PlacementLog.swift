//
//  PlacementLog.swift
//  OmniSiteTracker
//
//  SwiftData model for persisting insulin pump placement records.
//

import Foundation
import SwiftData

/// Represents a single pump placement event stored in the local database.
/// Uses SwiftData for automatic persistence with no cloud sync.
@Model
final class PlacementLog {
    /// Unique identifier for this placement record
    var id: UUID

    /// The body location where the pump was placed
    /// Stored as raw string value for SwiftData compatibility
    var locationRawValue: String

    /// The date and time when the pump was placed
    var placedAt: Date

    /// Optional user note for this placement (e.g., "Site felt tender")
    var note: String?

    /// Computed property to access the strongly-typed BodyLocation enum
    var location: BodyLocation {
        get {
            BodyLocation(rawValue: locationRawValue) ?? .abdomenRight
        }
        set {
            locationRawValue = newValue.rawValue
        }
    }

    /// Initializes a new placement log entry
    /// - Parameters:
    ///   - location: The body location where the pump was placed
    ///   - placedAt: The date/time of placement (defaults to current time)
    ///   - note: Optional note about this placement
    init(location: BodyLocation, placedAt: Date = .now, note: String? = nil) {
        self.id = UUID()
        self.locationRawValue = location.rawValue
        self.placedAt = placedAt
        self.note = note
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
