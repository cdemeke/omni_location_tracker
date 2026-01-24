//
//  SettingsViewModel.swift
//  OmniSiteTracker
//
//  ViewModel for managing settings state and persistence.
//

import Foundation
import SwiftData

/// ViewModel for managing app settings including rest duration, site toggles, and custom sites.
/// Uses @Observable for SwiftUI integration with automatic UI updates.
@Observable
final class SettingsViewModel {
    private var modelContext: ModelContext?

    /// Configures the view model with a SwiftData model context
    /// - Parameter modelContext: The SwiftData model context for persistence
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Rest Duration Settings

    /// Gets the current minimum rest duration in days
    /// - Returns: The minimum rest days setting (default 3)
    func getRestDuration() -> Int {
        guard let modelContext else { return 3 }
        let settings = UserSettings.getOrCreate(context: modelContext)
        return settings.minimumRestDays
    }

    /// Updates the minimum rest duration setting
    /// - Parameter days: The new minimum rest days value
    func updateRestDuration(days: Int) {
        guard let modelContext else { return }
        let settings = UserSettings.getOrCreate(context: modelContext)
        settings.minimumRestDays = days
        settings.updatedAt = .now

        do {
            try modelContext.save()
        } catch {
            // Silent fail - setting will be available next launch
        }
    }

    // MARK: - Default Site Management

    /// Gets all currently disabled default body locations
    /// - Returns: Array of disabled BodyLocation values
    func getDisabledDefaultSites() -> [BodyLocation] {
        guard let modelContext else { return [] }

        let descriptor = FetchDescriptor<DisabledDefaultSite>()

        do {
            let disabledSites = try modelContext.fetch(descriptor)
            return disabledSites.compactMap { $0.location }
        } catch {
            return []
        }
    }

    /// Toggles a default body location's enabled/disabled state
    /// - Parameter location: The BodyLocation to toggle
    func toggleDefaultSite(location: BodyLocation) {
        guard let modelContext else { return }

        let descriptor = FetchDescriptor<DisabledDefaultSite>(
            predicate: #Predicate { $0.locationRawValue == location.rawValue }
        )

        do {
            let existingDisabled = try modelContext.fetch(descriptor)

            if let existing = existingDisabled.first {
                // Site is currently disabled, re-enable it by removing the record
                modelContext.delete(existing)
            } else {
                // Site is currently enabled, disable it by adding a record
                let newDisabled = DisabledDefaultSite(location: location)
                modelContext.insert(newDisabled)
            }

            try modelContext.save()
        } catch {
            // Silent fail
        }
    }

    // MARK: - Custom Site Management

    /// Gets all custom sites
    /// - Returns: Array of CustomSite objects
    func getCustomSites() -> [CustomSite] {
        guard let modelContext else { return [] }

        let descriptor = FetchDescriptor<CustomSite>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }

    /// Gets a custom site by its ID
    /// - Parameter id: The UUID of the custom site to fetch
    /// - Returns: The CustomSite if found, nil otherwise
    func getCustomSite(byId id: UUID) -> CustomSite? {
        guard let modelContext else { return nil }

        let descriptor = FetchDescriptor<CustomSite>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            return nil
        }
    }

    /// Adds a new custom site
    /// - Parameters:
    ///   - name: The name of the custom site
    ///   - iconName: The SF Symbol name for the icon (defaults to "star.fill")
    func addCustomSite(name: String, iconName: String) {
        guard let modelContext else { return }

        let newSite = CustomSite(name: name, iconName: iconName)
        modelContext.insert(newSite)

        do {
            try modelContext.save()
        } catch {
            // Silent fail
        }
    }

    /// Deletes a custom site by its ID
    /// - Parameter id: The UUID of the custom site to delete
    func deleteCustomSite(id: UUID) {
        guard let modelContext else { return }

        let descriptor = FetchDescriptor<CustomSite>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            let sites = try modelContext.fetch(descriptor)
            if let site = sites.first {
                modelContext.delete(site)
                try modelContext.save()
            }
        } catch {
            // Silent fail
        }
    }

    /// Toggles a custom site's enabled/disabled state
    /// - Parameter id: The UUID of the custom site to toggle
    func toggleCustomSite(id: UUID) {
        guard let modelContext else { return }

        let descriptor = FetchDescriptor<CustomSite>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            let sites = try modelContext.fetch(descriptor)
            if let site = sites.first {
                site.isEnabled.toggle()
                try modelContext.save()
            }
        } catch {
            // Silent fail
        }
    }

    // MARK: - Display Preferences

    /// Gets whether disabled sites should be shown in history and patterns views
    /// - Returns: True if disabled sites should be shown
    func getShowDisabledSitesInHistory() -> Bool {
        guard let modelContext else { return true }
        let settings = UserSettings.getOrCreate(context: modelContext)
        return settings.showDisabledSitesInHistory
    }

    /// Updates the show disabled sites in history preference
    /// - Parameter show: Whether to show disabled sites
    func updateShowDisabledSitesInHistory(show: Bool) {
        guard let modelContext else { return }
        let settings = UserSettings.getOrCreate(context: modelContext)
        settings.showDisabledSitesInHistory = show
        settings.updatedAt = .now

        do {
            try modelContext.save()
        } catch {
            // Silent fail
        }
    }

    // MARK: - HealthKit Settings

    /// Gets whether HealthKit integration is enabled
    /// - Returns: True if HealthKit is enabled
    func getHealthKitEnabled() -> Bool {
        guard let modelContext else { return false }
        let settings = UserSettings.getOrCreate(context: modelContext)
        return settings.healthKitEnabled
    }

    /// Updates whether HealthKit integration is enabled
    /// - Parameter enabled: Whether HealthKit should be enabled
    func updateHealthKitEnabled(_ enabled: Bool) {
        guard let modelContext else { return }
        let settings = UserSettings.getOrCreate(context: modelContext)
        settings.healthKitEnabled = enabled
        settings.updatedAt = .now

        do {
            try modelContext.save()
        } catch {
            // Silent fail
        }
    }

    // MARK: - Notification Settings

    /// Gets the current notification settings
    /// - Returns: Tuple containing notificationsEnabled, reminderHour, reminderMinute, and daysBeforeReminder
    func getNotificationSettings() -> (enabled: Bool, hour: Int, minute: Int, daysBefore: Int) {
        guard let modelContext else { return (false, 9, 0, 0) }
        let settings = NotificationSettings.getOrCreate(context: modelContext)
        return (settings.notificationsEnabled, settings.reminderHour, settings.reminderMinute, settings.daysBeforeReminder)
    }

    /// Updates whether notifications are enabled
    /// - Parameter enabled: Whether notifications should be enabled
    func updateNotificationsEnabled(_ enabled: Bool) {
        guard let modelContext else { return }
        let settings = NotificationSettings.getOrCreate(context: modelContext)
        settings.notificationsEnabled = enabled

        do {
            try modelContext.save()
        } catch {
            // Silent fail
        }
    }

    /// Updates the notification reminder time
    /// - Parameters:
    ///   - hour: Hour component (0-23)
    ///   - minute: Minute component (0-59)
    func updateReminderTime(hour: Int, minute: Int) {
        guard let modelContext else { return }
        let settings = NotificationSettings.getOrCreate(context: modelContext)
        settings.reminderHour = hour
        settings.reminderMinute = minute

        do {
            try modelContext.save()
        } catch {
            // Silent fail
        }
    }

    /// Updates the number of days before site is ready to send reminder
    /// - Parameter days: Number of days (0-7)
    func updateDaysBeforeReminder(days: Int) {
        guard let modelContext else { return }
        let settings = NotificationSettings.getOrCreate(context: modelContext)
        settings.daysBeforeReminder = days

        do {
            try modelContext.save()
        } catch {
            // Silent fail
        }
    }

    // MARK: - Reset to Defaults

    /// Resets all settings to their default values
    /// - Resets rest days to 3
    /// - Enables all default sites
    /// - Deletes all custom sites
    /// - Disables notifications
    /// - Sets show disabled sites in history to ON
    func resetToDefaults() {
        guard let modelContext else { return }

        do {
            // Reset UserSettings to defaults
            let userSettings = UserSettings.getOrCreate(context: modelContext)
            userSettings.minimumRestDays = 3
            userSettings.showDisabledSitesInHistory = true
            userSettings.healthKitEnabled = false
            userSettings.updatedAt = .now

            // Re-enable all default sites by deleting all DisabledDefaultSite records
            let disabledDescriptor = FetchDescriptor<DisabledDefaultSite>()
            let disabledSites = try modelContext.fetch(disabledDescriptor)
            for disabledSite in disabledSites {
                modelContext.delete(disabledSite)
            }

            // Delete all custom sites
            let customDescriptor = FetchDescriptor<CustomSite>()
            let customSites = try modelContext.fetch(customDescriptor)
            for customSite in customSites {
                modelContext.delete(customSite)
            }

            // Reset notification settings to defaults
            let notificationSettings = NotificationSettings.getOrCreate(context: modelContext)
            notificationSettings.notificationsEnabled = false
            notificationSettings.reminderHour = 9
            notificationSettings.reminderMinute = 0
            notificationSettings.daysBeforeReminder = 0

            try modelContext.save()
        } catch {
            // Silent fail
        }
    }
}
