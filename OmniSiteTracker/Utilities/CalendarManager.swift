//
//  CalendarManager.swift
//  OmniSiteTracker
//
//  Manages integration with iOS Calendar (EventKit).
//  Creates calendar events for placements and reminders.
//

import Foundation
import EventKit
import SwiftUI

/// Manages calendar integration using EventKit
@MainActor
@Observable
final class CalendarManager {
    // MARK: - Singleton

    static let shared = CalendarManager()

    // MARK: - Properties

    private let eventStore = EKEventStore()

    /// Calendar authorization status
    private(set) var authorizationStatus: EKAuthorizationStatus = .notDetermined

    /// Whether calendar access is authorized
    var isAuthorized: Bool {
        authorizationStatus == .fullAccess || authorizationStatus == .authorized
    }

    /// The app's dedicated calendar
    private(set) var omniSiteCalendar: EKCalendar?

    /// Calendar name
    private let calendarName = "OmniSite Tracker"

    // MARK: - Initialization

    private init() {
        updateAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Requests calendar access
    func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                updateAuthorizationStatus()
                if granted {
                    setupCalendar()
                }
                return granted
            } catch {
                print("Calendar access error: \(error)")
                return false
            }
        } else {
            do {
                let granted = try await eventStore.requestAccess(to: .event)
                updateAuthorizationStatus()
                if granted {
                    setupCalendar()
                }
                return granted
            } catch {
                print("Calendar access error: \(error)")
                return false
            }
        }
    }

    private func updateAuthorizationStatus() {
        if #available(iOS 17.0, *) {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        } else {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        }
    }

    // MARK: - Calendar Setup

    /// Sets up or finds the OmniSite calendar
    private func setupCalendar() {
        // Check if calendar already exists
        let calendars = eventStore.calendars(for: .event)
        if let existing = calendars.first(where: { $0.title == calendarName }) {
            omniSiteCalendar = existing
            return
        }

        // Create new calendar
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = calendarName
        newCalendar.cgColor = UIColor.systemBlue.cgColor

        // Find the local source
        if let source = eventStore.sources.first(where: { $0.sourceType == .local }) {
            newCalendar.source = source
        } else if let source = eventStore.sources.first(where: { $0.sourceType == .calDAV }) {
            newCalendar.source = source
        } else if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
            newCalendar.source = defaultCalendar.source
        }

        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            omniSiteCalendar = newCalendar
        } catch {
            print("Failed to create calendar: \(error)")
        }
    }

    // MARK: - Event Management

    /// Creates a calendar event for a placement
    @discardableResult
    func createPlacementEvent(
        site: String,
        date: Date,
        notes: String? = nil
    ) async throws -> String {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }

        guard let calendar = omniSiteCalendar else {
            setupCalendar()
            guard let calendar = omniSiteCalendar else {
                throw CalendarError.calendarNotFound
            }
            return try await createEvent(site: site, date: date, notes: notes, calendar: calendar)
        }

        return try await createEvent(site: site, date: date, notes: notes, calendar: calendar)
    }

    private func createEvent(
        site: String,
        date: Date,
        notes: String?,
        calendar: EKCalendar
    ) async throws -> String {
        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = "Pump Site: \(site)"
        event.startDate = date
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: date) ?? date
        event.isAllDay = false

        var noteText = "Logged via OmniSite Tracker"
        if let notes = notes, !notes.isEmpty {
            noteText += "\n\nNotes: \(notes)"
        }
        event.notes = noteText

        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            throw CalendarError.saveFailed(error.localizedDescription)
        }
    }

    /// Creates a reminder event for next placement
    @discardableResult
    func createReminderEvent(
        nextSite: String,
        reminderDate: Date
    ) async throws -> String {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }

        guard let calendar = omniSiteCalendar else {
            throw CalendarError.calendarNotFound
        }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = "Time to change pump site"
        event.startDate = reminderDate
        event.endDate = Calendar.current.date(byAdding: .minute, value: 30, to: reminderDate) ?? reminderDate

        event.notes = "Recommended site: \(nextSite)\n\nOpen OmniSite Tracker to log your placement."

        // Add alert
        event.addAlarm(EKAlarm(relativeOffset: 0))
        event.addAlarm(EKAlarm(relativeOffset: -3600)) // 1 hour before

        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            throw CalendarError.saveFailed(error.localizedDescription)
        }
    }

    /// Removes an event by identifier
    func removeEvent(identifier: String) throws {
        guard let event = eventStore.event(withIdentifier: identifier) else {
            return
        }

        try eventStore.remove(event, span: .thisEvent)
    }

    /// Gets all OmniSite events in a date range
    func getEvents(from startDate: Date, to endDate: Date) -> [EKEvent] {
        guard isAuthorized, let calendar = omniSiteCalendar else {
            return []
        }

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: [calendar]
        )

        return eventStore.events(matching: predicate)
    }
}

// MARK: - Calendar Errors

enum CalendarError: LocalizedError {
    case notAuthorized
    case calendarNotFound
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Calendar access not authorized"
        case .calendarNotFound:
            return "OmniSite calendar not found"
        case .saveFailed(let message):
            return "Failed to save event: \(message)"
        }
    }
}

// MARK: - Calendar View

struct CalendarIntegrationView: View {
    @State private var calendarManager = CalendarManager.shared
    @State private var isRequestingAccess = false
    @State private var showingEvents = false

    var body: some View {
        List {
            Section {
                // Authorization status
                HStack {
                    Image(systemName: calendarManager.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(calendarManager.isAuthorized ? .green : .red)

                    VStack(alignment: .leading) {
                        Text("Calendar Access")
                            .font(.body)
                        Text(calendarManager.isAuthorized ? "Authorized" : "Not Authorized")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if !calendarManager.isAuthorized {
                        Button("Enable") {
                            Task {
                                isRequestingAccess = true
                                _ = await calendarManager.requestAccess()
                                isRequestingAccess = false
                            }
                        }
                        .disabled(isRequestingAccess)
                    }
                }
            } header: {
                Text("Calendar Integration")
            } footer: {
                Text("Allow calendar access to add placement events and reminders to your calendar.")
            }

            if calendarManager.isAuthorized {
                Section {
                    Button(action: { showingEvents = true }) {
                        HStack {
                            Image(systemName: "calendar")
                            Text("View Calendar Events")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Events")
                }
            }
        }
        .sheet(isPresented: $showingEvents) {
            CalendarEventsView()
        }
    }
}

// MARK: - Calendar Events View

struct CalendarEventsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var calendarManager = CalendarManager.shared
    @State private var events: [EKEvent] = []

    var body: some View {
        NavigationStack {
            List {
                if events.isEmpty {
                    Text("No upcoming events")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(events, id: \.eventIdentifier) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title)
                                .font(.headline)

                            Text(event.startDate, style: .date)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(event.startDate, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Calendar Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadEvents()
            }
        }
    }

    private func loadEvents() {
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: now) ?? now
        events = calendarManager.getEvents(from: now, to: endDate)
    }
}

// MARK: - Settings Section

struct CalendarSettingsSection: View {
    @AppStorage("calendar_autoAddEvents") private var autoAddEvents = false
    @AppStorage("calendar_addReminders") private var addReminders = true
    @AppStorage("calendar_reminderHours") private var reminderHours = 72

    @State private var calendarManager = CalendarManager.shared

    var body: some View {
        Section {
            if calendarManager.isAuthorized {
                Toggle("Add placements to calendar", isOn: $autoAddEvents)

                Toggle("Add change reminders", isOn: $addReminders)

                if addReminders {
                    Picker("Reminder before change", selection: $reminderHours) {
                        Text("24 hours").tag(24)
                        Text("48 hours").tag(48)
                        Text("72 hours").tag(72)
                    }
                }
            } else {
                Button(action: {
                    Task {
                        await calendarManager.requestAccess()
                    }
                }) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Enable Calendar Integration")
                    }
                }
            }
        } header: {
            Text("Calendar")
        } footer: {
            Text("Automatically add pump site changes to your calendar and set reminders.")
        }
    }
}

// MARK: - Preview

#Preview {
    CalendarIntegrationView()
}
