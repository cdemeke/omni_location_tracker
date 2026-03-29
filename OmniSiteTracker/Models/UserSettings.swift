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

    /// Timestamp when settings were first created
    var createdAt: Date

    /// Timestamp when settings were last modified
    var updatedAt: Date

    // MARK: - iCloud Sync Settings

    /// Whether iCloud sync is enabled
    var iCloudSyncEnabled: Bool

    /// Whether to sync photos to iCloud
    var iCloudSyncPhotos: Bool

    /// Whether to only sync on WiFi
    var iCloudWifiOnly: Bool

    /// When settings were last synced to iCloud
    var iCloudLastSyncDate: Date?

    /// Initializes user settings with default values
    init(
        minimumRestDays: Int = 18,
        showDisabledSitesInHistory: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        iCloudSyncEnabled: Bool = true,
        iCloudSyncPhotos: Bool = false,
        iCloudWifiOnly: Bool = false
    ) {
        self.minimumRestDays = minimumRestDays
        self.showDisabledSitesInHistory = showDisabledSitesInHistory
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.iCloudSyncEnabled = iCloudSyncEnabled
        self.iCloudSyncPhotos = iCloudSyncPhotos
        self.iCloudWifiOnly = iCloudWifiOnly
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
