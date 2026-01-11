//
//  DisabledDefaultSite.swift
//  OmniSiteTracker
//
//  SwiftData model for tracking which default body locations the user has disabled.
//

import Foundation
import SwiftData

/// Model for tracking disabled default body locations.
/// Stores the raw value of BodyLocation enum to persist user's disabled site preferences.
@Model
final class DisabledDefaultSite {
    /// Unique identifier for this disabled site record
    var id: UUID

    /// Raw string value of the BodyLocation enum (e.g., "left_arm", "abdomen_right")
    var locationRawValue: String

    /// Timestamp when this site was disabled
    var disabledAt: Date

    /// Computed property to convert the raw value back to a BodyLocation enum
    var location: BodyLocation? {
        BodyLocation(rawValue: locationRawValue)
    }

    /// Initializes a new disabled default site record
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - locationRawValue: The raw string value of the BodyLocation enum
    ///   - disabledAt: Timestamp when the site was disabled (defaults to now)
    init(
        id: UUID = UUID(),
        locationRawValue: String,
        disabledAt: Date = .now
    ) {
        self.id = id
        self.locationRawValue = locationRawValue
        self.disabledAt = disabledAt
    }

    /// Convenience initializer using BodyLocation enum directly
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - location: The BodyLocation to disable
    ///   - disabledAt: Timestamp when the site was disabled (defaults to now)
    convenience init(
        id: UUID = UUID(),
        location: BodyLocation,
        disabledAt: Date = .now
    ) {
        self.init(id: id, locationRawValue: location.rawValue, disabledAt: disabledAt)
    }
}
