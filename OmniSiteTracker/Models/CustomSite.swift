//
//  CustomSite.swift
//  OmniSiteTracker
//
//  SwiftData model for storing user-defined custom site locations.
//

import Foundation
import SwiftData

/// Model for storing user-defined custom site locations.
/// Allows users to add and manage their own injection/placement sites beyond the default body locations.
@Model
final class CustomSite {
    /// Unique identifier for the custom site
    var id: UUID

    /// User-defined name for the custom site
    var name: String

    /// SF Symbol name for the custom site icon
    var iconName: String

    /// Whether this custom site is enabled for use
    var isEnabled: Bool

    /// Timestamp when the custom site was created
    var createdAt: Date

    /// Initializes a new custom site with the given properties
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - name: Name of the custom site
    ///   - iconName: SF Symbol name for the icon (defaults to "star.fill")
    ///   - isEnabled: Whether the site is enabled (defaults to true)
    ///   - createdAt: Creation timestamp (defaults to now)
    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "star.fill",
        isEnabled: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
}
