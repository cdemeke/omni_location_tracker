//
//  SmartNotificationManager.swift
//  OmniSiteTracker
//
//  Intelligent notification system for pump site management.
//  Provides customizable reminders, streak alerts, and site warnings.
//

import Foundation
import UserNotifications
import SwiftUI
import SwiftData

/// Manages smart notifications for the app
@MainActor
@Observable
final class SmartNotificationManager {
    // MARK: - Singleton

    static let shared = SmartNotificationManager()

    // MARK: - Properties

    private let notificationCenter = UNUserNotificationCenter.current()

    /// Current authorization status
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// Whether notifications are authorized
    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }

    // MARK: - Notification Types

    enum NotificationType: String {
        case siteChange = "site_change"
        case streakReminder = "streak_reminder"
        case siteWarning = "site_warning"
        case dailyReminder = "daily_reminder"
        case weeklyReport = "weekly_report"
        case rotationSuggestion = "rotation_suggestion"

        var categoryIdentifier: String {
            "omnisite_\(rawValue)"
        }
    }

    // MARK: - Initialization

    private init() {
        Task {
            await checkAuthorizationStatus()
            await registerCategories()
        }
    }

    // MARK: - Authorization

    /// Requests notification permission
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge, .criticalAlert]
            )
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    private func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // MARK: - Category Registration

    private func registerCategories() async {
        // Site change category with actions
        let logAction = UNNotificationAction(
            identifier: "LOG_PLACEMENT",
            title: "Log Placement",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_1H",
            title: "Remind in 1 Hour",
            options: []
        )

        let siteChangeCategory = UNNotificationCategory(
            identifier: NotificationType.siteChange.categoryIdentifier,
            actions: [logAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        // Streak reminder category
        let viewStreakAction = UNNotificationAction(
            identifier: "VIEW_STREAK",
            title: "View Streak",
            options: [.foreground]
        )

        let streakCategory = UNNotificationCategory(
            identifier: NotificationType.streakReminder.categoryIdentifier,
            actions: [viewStreakAction],
            intentIdentifiers: [],
            options: []
        )

        // Register categories
        notificationCenter.setNotificationCategories([siteChangeCategory, streakCategory])
    }

    // MARK: - Scheduling Notifications

    /// Schedules a site change reminder
    func scheduleSiteChangeReminder(
        nextSite: String,
        at date: Date,
        identifier: String? = nil
    ) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }

        let content = UNMutableNotificationContent()
        content.title = "Time to Change Pump Site"
        content.body = "Your recommended site is: \(nextSite)"
        content.sound = .default
        content.categoryIdentifier = NotificationType.siteChange.categoryIdentifier
        content.userInfo = ["type": NotificationType.siteChange.rawValue, "site": nextSite]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let id = identifier ?? UUID().uuidString
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        try await notificationCenter.add(request)
    }

    /// Schedules a streak reminder
    func scheduleStreakReminder(
        currentStreak: Int,
        at date: Date
    ) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }

        let content = UNMutableNotificationContent()
        content.title = "Keep Your Streak Going!"
        content.body = "You're on a \(currentStreak)-day streak. Don't forget to log today!"
        content.sound = .default
        content.categoryIdentifier = NotificationType.streakReminder.categoryIdentifier
        content.userInfo = ["type": NotificationType.streakReminder.rawValue, "streak": currentStreak]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "streak_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    /// Schedules a site overuse warning
    func scheduleSiteWarning(
        site: String,
        usageCount: Int,
        daysSinceRest: Int
    ) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }

        let content = UNMutableNotificationContent()
        content.title = "Site Rotation Reminder"
        content.body = "\(site) has been used \(usageCount) times. Consider rotating to a different site."
        content.sound = .default
        content.categoryIdentifier = NotificationType.siteWarning.categoryIdentifier
        content.userInfo = ["type": NotificationType.siteWarning.rawValue, "site": site]

        // Deliver immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "warning_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    /// Schedules a daily reminder at a specific time
    func scheduleDailyReminder(hour: Int, minute: Int) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }

        // Cancel existing daily reminders
        await cancelNotifications(ofType: .dailyReminder)

        let content = UNMutableNotificationContent()
        content.title = "Daily Check-In"
        content.body = "Don't forget to log your pump site if you changed it today!"
        content.sound = .default
        content.userInfo = ["type": NotificationType.dailyReminder.rawValue]

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    /// Schedules weekly report notification
    func scheduleWeeklyReport(dayOfWeek: Int, hour: Int) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }

        // Cancel existing weekly reports
        await cancelNotifications(ofType: .weeklyReport)

        let content = UNMutableNotificationContent()
        content.title = "Weekly Site Report"
        content.body = "Check out your weekly site rotation summary!"
        content.sound = .default
        content.userInfo = ["type": NotificationType.weeklyReport.rawValue]

        var components = DateComponents()
        components.weekday = dayOfWeek
        components.hour = hour

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "weekly_report",
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    // MARK: - Cancellation

    /// Cancels all pending notifications
    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    /// Cancels notifications of a specific type
    func cancelNotifications(ofType type: NotificationType) async {
        let requests = await notificationCenter.pendingNotificationRequests()
        let idsToRemove = requests.filter { request in
            guard let userInfo = request.content.userInfo["type"] as? String else { return false }
            return userInfo == type.rawValue
        }.map { $0.identifier }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: idsToRemove)
    }

    /// Cancels a specific notification by identifier
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Pending Notifications

    /// Gets all pending notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
}

// MARK: - Notification Error

enum NotificationError: LocalizedError {
    case notAuthorized
    case scheduleFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Notification permission not granted"
        case .scheduleFailed(let message):
            return "Failed to schedule notification: \(message)"
        }
    }
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
    @State private var notificationManager = SmartNotificationManager.shared

    @AppStorage("notifications_siteChange") private var siteChangeEnabled = true
    @AppStorage("notifications_streakReminder") private var streakReminderEnabled = true
    @AppStorage("notifications_dailyReminder") private var dailyReminderEnabled = false
    @AppStorage("notifications_dailyTime") private var dailyReminderTime = 540 // 9:00 AM in minutes
    @AppStorage("notifications_weeklyReport") private var weeklyReportEnabled = false
    @AppStorage("notifications_weeklyDay") private var weeklyReportDay = 1 // Sunday

    @State private var selectedTime = Date()
    @State private var isRequestingPermission = false

    var body: some View {
        List {
            // Authorization Section
            Section {
                HStack {
                    Image(systemName: notificationManager.isAuthorized ? "bell.fill" : "bell.slash.fill")
                        .foregroundColor(notificationManager.isAuthorized ? .green : .red)

                    VStack(alignment: .leading) {
                        Text("Notifications")
                        Text(notificationManager.isAuthorized ? "Enabled" : "Disabled")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if !notificationManager.isAuthorized {
                        Button("Enable") {
                            Task {
                                isRequestingPermission = true
                                await notificationManager.requestAuthorization()
                                isRequestingPermission = false
                            }
                        }
                        .disabled(isRequestingPermission)
                    }
                }
            }

            if notificationManager.isAuthorized {
                // Site Change Notifications
                Section {
                    Toggle("Site change reminders", isOn: $siteChangeEnabled)
                    Toggle("Streak reminders", isOn: $streakReminderEnabled)
                } header: {
                    Text("Smart Notifications")
                } footer: {
                    Text("Get notified when it's time to change your pump site or when your streak is at risk.")
                }

                // Daily Reminder
                Section {
                    Toggle("Daily reminder", isOn: $dailyReminderEnabled)

                    if dailyReminderEnabled {
                        DatePicker(
                            "Reminder time",
                            selection: $selectedTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: selectedTime) { _, newValue in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                            dailyReminderTime = (components.hour ?? 9) * 60 + (components.minute ?? 0)
                            scheduleDaily()
                        }
                    }
                } header: {
                    Text("Daily Reminder")
                }

                // Weekly Report
                Section {
                    Toggle("Weekly report", isOn: $weeklyReportEnabled)

                    if weeklyReportEnabled {
                        Picker("Day of week", selection: $weeklyReportDay) {
                            Text("Sunday").tag(1)
                            Text("Monday").tag(2)
                            Text("Tuesday").tag(3)
                            Text("Wednesday").tag(4)
                            Text("Thursday").tag(5)
                            Text("Friday").tag(6)
                            Text("Saturday").tag(7)
                        }
                    }
                } header: {
                    Text("Weekly Report")
                }
            }
        }
        .navigationTitle("Notifications")
        .onAppear {
            // Set selected time from stored value
            let hour = dailyReminderTime / 60
            let minute = dailyReminderTime % 60
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            if let date = Calendar.current.date(from: components) {
                selectedTime = date
            }
        }
    }

    private func scheduleDaily() {
        guard dailyReminderEnabled else { return }
        let hour = dailyReminderTime / 60
        let minute = dailyReminderTime % 60
        Task {
            try? await notificationManager.scheduleDailyReminder(hour: hour, minute: minute)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
