//
//  NotificationSettings.swift
//  OmniSiteTracker
//
//  SwiftData model for persisting notification preferences.
//

import Foundation
import SwiftData

/// Singleton model for storing notification preference settings.
/// Uses SwiftData for automatic persistence with local-only storage.
@Model
final class NotificationSettings {
    /// Whether reminder notifications are enabled
    var notificationsEnabled: Bool

    /// Hour component of the reminder time (0-23)
    var reminderHour: Int

    /// Minute component of the reminder time (0-59)
    var reminderMinute: Int

    /// Number of days before site becomes ready to send reminder
    var daysBeforeReminder: Int

    /// Initializes notification settings with default values
    init(
        notificationsEnabled: Bool = false,
        reminderHour: Int = 9,
        reminderMinute: Int = 0,
        daysBeforeReminder: Int = 0
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.daysBeforeReminder = daysBeforeReminder
    }

    /// Retrieves existing settings or creates a new singleton instance
    /// - Parameter context: The SwiftData model context
    /// - Returns: The existing or newly created NotificationSettings instance
    static func getOrCreate(context: ModelContext) -> NotificationSettings {
        let descriptor = FetchDescriptor<NotificationSettings>()

        do {
            let existingSettings = try context.fetch(descriptor)
            if let settings = existingSettings.first {
                return settings
            }
        } catch {
            // If fetch fails, create new settings
        }

        // Create new settings with defaults
        let newSettings = NotificationSettings()
        context.insert(newSettings)
        return newSettings
    }
}
