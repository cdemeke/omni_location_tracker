//
//  NotificationManager.swift
//  OmniSiteTracker
//
//  Manager class for handling local notifications for site rotation reminders.
//

import Foundation
import UserNotifications
import SwiftData

/// Singleton manager for handling local notifications related to site rotation reminders.
/// Uses UNUserNotificationCenter for scheduling and managing notifications.
final class NotificationManager {
    /// Shared singleton instance
    static let shared = NotificationManager()

    /// The notification center instance
    private let center = UNUserNotificationCenter.current()

    /// Notification identifier prefix for site ready notifications
    private let siteReadyPrefix = "site_ready_"

    private init() {}

    // MARK: - Permission Handling

    /// Requests notification permissions from the user.
    /// - Parameter completion: Called with the authorization status (true if granted)
    func requestPermission(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                completion(granted)
            }
        }
    }

    /// Checks if notification permissions are currently granted.
    /// - Parameter completion: Called with the current authorization status
    func checkPermissionStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    // MARK: - Scheduling Notifications

    /// Schedules a notification for when a specific site becomes ready to use again.
    /// - Parameters:
    ///   - location: The body location that will become ready
    ///   - readyDate: The date when the site becomes ready
    ///   - reminderHour: Hour component for the notification time (0-23)
    ///   - reminderMinute: Minute component for the notification time (0-59)
    ///   - daysBeforeReminder: Number of days before the ready date to send the notification
    func scheduleNotification(
        for location: BodyLocation,
        readyDate: Date,
        reminderHour: Int,
        reminderMinute: Int,
        daysBeforeReminder: Int
    ) {
        // Calculate notification date: readyDate - daysBeforeReminder, at the specified time
        let calendar = Calendar.current

        // Subtract daysBeforeReminder from the ready date
        guard let notificationDate = calendar.date(byAdding: .day, value: -daysBeforeReminder, to: readyDate) else {
            return
        }

        // Set the time to the user's preferred reminder time
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: notificationDate)
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute

        guard let finalNotificationDate = calendar.date(from: dateComponents) else {
            return
        }

        // Don't schedule if the notification date is in the past
        guard finalNotificationDate > Date() else {
            return
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Site Ready"
        content.body = "\(location.displayName) is ready to use again."
        content.sound = .default

        // Create date-based trigger
        let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: finalNotificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        // Create request with unique identifier for this location
        let identifier = "\(siteReadyPrefix)\(location.rawValue)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // Remove any existing notification for this location before adding new one
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        // Add the new notification request
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification for \(location.displayName): \(error.localizedDescription)")
            }
        }
    }

    /// Schedules a notification for when a custom site becomes ready to use again.
    /// - Parameters:
    ///   - customSiteId: The UUID of the custom site
    ///   - customSiteName: The display name of the custom site
    ///   - readyDate: The date when the site becomes ready
    ///   - reminderHour: Hour component for the notification time (0-23)
    ///   - reminderMinute: Minute component for the notification time (0-59)
    ///   - daysBeforeReminder: Number of days before the ready date to send the notification
    func scheduleNotification(
        forCustomSite customSiteId: UUID,
        customSiteName: String,
        readyDate: Date,
        reminderHour: Int,
        reminderMinute: Int,
        daysBeforeReminder: Int
    ) {
        // Calculate notification date: readyDate - daysBeforeReminder, at the specified time
        let calendar = Calendar.current

        // Subtract daysBeforeReminder from the ready date
        guard let notificationDate = calendar.date(byAdding: .day, value: -daysBeforeReminder, to: readyDate) else {
            return
        }

        // Set the time to the user's preferred reminder time
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: notificationDate)
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute

        guard let finalNotificationDate = calendar.date(from: dateComponents) else {
            return
        }

        // Don't schedule if the notification date is in the past
        guard finalNotificationDate > Date() else {
            return
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Site Ready"
        content.body = "\(customSiteName) is ready to use again."
        content.sound = .default

        // Create date-based trigger
        let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: finalNotificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        // Create request with unique identifier for this custom site
        let identifier = "\(siteReadyPrefix)custom_\(customSiteId.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // Remove any existing notification for this site before adding new one
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        // Add the new notification request
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification for \(customSiteName): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Cancellation

    /// Cancels all scheduled site ready notifications.
    /// Called when user disables reminders in settings.
    func cancelAllNotifications() {
        center.getPendingNotificationRequests { [weak self] requests in
            guard let self = self else { return }

            // Filter to only site ready notifications
            let siteReadyIdentifiers = requests
                .filter { $0.identifier.hasPrefix(self.siteReadyPrefix) }
                .map { $0.identifier }

            self.center.removePendingNotificationRequests(withIdentifiers: siteReadyIdentifiers)
        }
    }

    /// Cancels notification for a specific body location.
    /// - Parameter location: The body location to cancel notification for
    func cancelNotification(for location: BodyLocation) {
        let identifier = "\(siteReadyPrefix)\(location.rawValue)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Cancels notification for a specific custom site.
    /// - Parameter customSiteId: The UUID of the custom site to cancel notification for
    func cancelNotification(forCustomSite customSiteId: UUID) {
        let identifier = "\(siteReadyPrefix)custom_\(customSiteId.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Update Notifications After Placement

    /// Updates notifications after a new placement is logged.
    /// Schedules a notification for when the newly used site will be ready again.
    /// - Parameters:
    ///   - modelContext: SwiftData model context for fetching settings
    ///   - location: The body location where placement was logged (nil for custom sites)
    ///   - customSiteId: The UUID of the custom site (nil for default locations)
    ///   - customSiteName: The name of the custom site (nil for default locations)
    ///   - placedAt: The date when placement was made
    func updateNotificationsAfterPlacement(
        modelContext: ModelContext,
        location: BodyLocation? = nil,
        customSiteId: UUID? = nil,
        customSiteName: String? = nil,
        placedAt: Date
    ) {
        // Fetch notification settings
        let notificationSettings = NotificationSettings.getOrCreate(context: modelContext)

        // Only schedule if notifications are enabled
        guard notificationSettings.notificationsEnabled else {
            return
        }

        // Fetch user settings for rest duration
        let userSettings = UserSettings.getOrCreate(context: modelContext)
        let restDays = userSettings.minimumRestDays

        // Calculate when the site will be ready again
        let calendar = Calendar.current
        guard let readyDate = calendar.date(byAdding: .day, value: restDays, to: placedAt) else {
            return
        }

        // Schedule appropriate notification
        if let location = location {
            scheduleNotification(
                for: location,
                readyDate: readyDate,
                reminderHour: notificationSettings.reminderHour,
                reminderMinute: notificationSettings.reminderMinute,
                daysBeforeReminder: notificationSettings.daysBeforeReminder
            )
        } else if let customSiteId = customSiteId, let customSiteName = customSiteName {
            scheduleNotification(
                forCustomSite: customSiteId,
                customSiteName: customSiteName,
                readyDate: readyDate,
                reminderHour: notificationSettings.reminderHour,
                reminderMinute: notificationSettings.reminderMinute,
                daysBeforeReminder: notificationSettings.daysBeforeReminder
            )
        }
    }

    /// Reschedules all notifications based on current placements and settings.
    /// Useful when notification settings change (time, days before, etc.)
    /// - Parameter modelContext: SwiftData model context for fetching data
    func rescheduleAllNotifications(modelContext: ModelContext) {
        // First cancel all existing notifications
        cancelAllNotifications()

        // Fetch notification settings
        let notificationSettings = NotificationSettings.getOrCreate(context: modelContext)

        // Only reschedule if notifications are enabled
        guard notificationSettings.notificationsEnabled else {
            return
        }

        // Fetch user settings for rest duration
        let userSettings = UserSettings.getOrCreate(context: modelContext)
        let restDays = userSettings.minimumRestDays

        // Fetch all placements to find most recent for each location
        let descriptor = FetchDescriptor<PlacementLog>(
            sortBy: [SortDescriptor(\.placedAt, order: .reverse)]
        )

        do {
            let placements = try modelContext.fetch(descriptor)
            let calendar = Calendar.current

            // Track which locations we've already scheduled for (most recent only)
            var scheduledLocations = Set<BodyLocation>()
            var scheduledCustomSites = Set<UUID>()

            for placement in placements {
                if let location = placement.location, !scheduledLocations.contains(location) {
                    // Calculate ready date
                    if let readyDate = calendar.date(byAdding: .day, value: restDays, to: placement.placedAt) {
                        scheduleNotification(
                            for: location,
                            readyDate: readyDate,
                            reminderHour: notificationSettings.reminderHour,
                            reminderMinute: notificationSettings.reminderMinute,
                            daysBeforeReminder: notificationSettings.daysBeforeReminder
                        )
                        scheduledLocations.insert(location)
                    }
                } else if let customSiteId = placement.customSiteId,
                          let customSiteName = placement.customSiteName,
                          !scheduledCustomSites.contains(customSiteId) {
                    // Calculate ready date for custom site
                    if let readyDate = calendar.date(byAdding: .day, value: restDays, to: placement.placedAt) {
                        scheduleNotification(
                            forCustomSite: customSiteId,
                            customSiteName: customSiteName,
                            readyDate: readyDate,
                            reminderHour: notificationSettings.reminderHour,
                            reminderMinute: notificationSettings.reminderMinute,
                            daysBeforeReminder: notificationSettings.daysBeforeReminder
                        )
                        scheduledCustomSites.insert(customSiteId)
                    }
                }
            }
        } catch {
            print("Failed to fetch placements for rescheduling notifications: \(error.localizedDescription)")
        }
    }
}
