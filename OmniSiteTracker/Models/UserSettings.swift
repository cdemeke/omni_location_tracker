//
//  UserSettings.swift
//  OmniSiteTracker
//
//  SwiftData model for persisting user preference settings.
//

import Foundation
import SwiftData

/// Singleton model for storing user preference settings.
/// Uses SwiftData for automatic persistence with local-only storage.
@Model
final class UserSettings {
    /// Minimum number of days a site should rest before being used again
    var minimumRestDays: Int

    /// Whether to show disabled sites in history and patterns views
    var showDisabledSitesInHistory: Bool

    /// Whether HealthKit integration is enabled for glucose correlation
    var healthKitEnabled: Bool

    /// Timestamp when settings were first created
    var createdAt: Date

    /// Timestamp when settings were last modified
    var updatedAt: Date

    /// Initializes user settings with default values
    init(
        minimumRestDays: Int = 18,
        showDisabledSitesInHistory: Bool = true,
        healthKitEnabled: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.minimumRestDays = minimumRestDays
        self.showDisabledSitesInHistory = showDisabledSitesInHistory
        self.healthKitEnabled = healthKitEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Retrieves existing settings or creates a new singleton instance
    /// - Parameter context: The SwiftData model context
    /// - Returns: The existing or newly created UserSettings instance
    static func getOrCreate(context: ModelContext) -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>()

        do {
            let existingSettings = try context.fetch(descriptor)
            if let settings = existingSettings.first {
                return settings
            }
        } catch {
            // If fetch fails, create new settings
        }

        // Create new settings with defaults
        let newSettings = UserSettings()
        context.insert(newSettings)
        return newSettings
    }
}
