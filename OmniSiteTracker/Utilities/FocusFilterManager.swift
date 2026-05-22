//
//  FocusFilterManager.swift
//  OmniSiteTracker
//
//  Integrates with iOS Focus modes to customize app behavior.
//  Filter notifications and profiles based on active Focus.
//

import Foundation
import AppIntents
import SwiftUI

// MARK: - Focus Filter Intent

/// App Intent for configuring Focus filters
@available(iOS 16.0, *)
struct OmniSiteFocusFilter: SetFocusFilterIntent {
    static var title: LocalizedStringResource = "OmniSite Focus Filter"
    static var description: IntentDescription? = IntentDescription("Configure OmniSite Tracker for this Focus mode")

    /// Display representation
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "OmniSite Settings",
            subtitle: notificationsEnabled ? "Notifications On" : "Notifications Off"
        )
    }

    // MARK: - Parameters

    @Parameter(title: "Enable Notifications", default: true)
    var notificationsEnabled: Bool

    @Parameter(title: "Show Reminders", default: true)
    var showReminders: Bool

    @Parameter(title: "Active Profile")
    var activeProfileName: String?

    @Parameter(title: "Quiet Hours Start")
    var quietHoursStart: Int?

    @Parameter(title: "Quiet Hours End")
    var quietHoursEnd: Int?

    // MARK: - Perform

    func perform() async throws -> some IntentResult {
        // Store Focus settings
        await FocusFilterSettings.shared.update(
            notificationsEnabled: notificationsEnabled,
            showReminders: showReminders,
            activeProfileName: activeProfileName,
            quietHoursStart: quietHoursStart,
            quietHoursEnd: quietHoursEnd
        )

        return .result()
    }
}

// MARK: - Focus Filter Settings

/// Stores current Focus filter settings
@MainActor
@Observable
final class FocusFilterSettings {
    static let shared = FocusFilterSettings()

    private(set) var notificationsEnabled: Bool = true
    private(set) var showReminders: Bool = true
    private(set) var activeProfileName: String?
    private(set) var quietHoursStart: Int?
    private(set) var quietHoursEnd: Int?

    private init() {
        // Load from UserDefaults
        let defaults = UserDefaults.standard
        notificationsEnabled = defaults.bool(forKey: "focus_notificationsEnabled")
        if !defaults.bool(forKey: "focus_initialized") {
            notificationsEnabled = true
            defaults.set(true, forKey: "focus_initialized")
        }
        showReminders = defaults.bool(forKey: "focus_showReminders")
        activeProfileName = defaults.string(forKey: "focus_activeProfile")
        quietHoursStart = defaults.object(forKey: "focus_quietStart") as? Int
        quietHoursEnd = defaults.object(forKey: "focus_quietEnd") as? Int
    }

    func update(
        notificationsEnabled: Bool,
        showReminders: Bool,
        activeProfileName: String?,
        quietHoursStart: Int?,
        quietHoursEnd: Int?
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.showReminders = showReminders
        self.activeProfileName = activeProfileName
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd

        // Persist to UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(notificationsEnabled, forKey: "focus_notificationsEnabled")
        defaults.set(showReminders, forKey: "focus_showReminders")
        defaults.set(activeProfileName, forKey: "focus_activeProfile")
        defaults.set(quietHoursStart, forKey: "focus_quietStart")
        defaults.set(quietHoursEnd, forKey: "focus_quietEnd")
    }

    /// Whether notifications should be delivered now based on Focus settings
    var shouldDeliverNotifications: Bool {
        guard notificationsEnabled else { return false }

        // Check quiet hours
        if let start = quietHoursStart, let end = quietHoursEnd {
            let currentHour = Calendar.current.component(.hour, from: .now)

            if start < end {
                // Normal range (e.g., 22 to 7)
                if currentHour >= start || currentHour < end {
                    return false
                }
            } else {
                // Overnight range (e.g., 22 to 7)
                if currentHour >= start || currentHour < end {
                    return false
                }
            }
        }

        return true
    }
}

// MARK: - Focus Settings View

struct FocusSettingsView: View {
    @State private var focusSettings = FocusFilterSettings.shared

    @State private var notificationsEnabled = true
    @State private var showReminders = true
    @State private var quietHoursEnabled = false
    @State private var quietStart = 22
    @State private var quietEnd = 7

    var body: some View {
        List {
            // Current Focus section
            Section {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.purple)

                    VStack(alignment: .leading) {
                        Text("Focus Filters")
                            .font(.body)
                        Text("Configure how OmniSite works with Focus modes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } footer: {
                Text("Focus filters let you customize notifications and app behavior when a Focus mode is active.")
            }

            // Notification settings
            Section {
                Toggle("Allow Notifications", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { _, newValue in
                        updateSettings()
                    }

                Toggle("Show Reminders", isOn: $showReminders)
                    .disabled(!notificationsEnabled)
                    .onChange(of: showReminders) { _, newValue in
                        updateSettings()
                    }
            } header: {
                Text("Notifications")
            }

            // Quiet hours
            Section {
                Toggle("Quiet Hours", isOn: $quietHoursEnabled)
                    .onChange(of: quietHoursEnabled) { _, newValue in
                        updateSettings()
                    }

                if quietHoursEnabled {
                    Picker("Start", selection: $quietStart) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .onChange(of: quietStart) { _, _ in updateSettings() }

                    Picker("End", selection: $quietEnd) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .onChange(of: quietEnd) { _, _ in updateSettings() }
                }
            } header: {
                Text("Quiet Hours")
            } footer: {
                Text("Notifications will be silenced during quiet hours.")
            }

            // Focus mode instructions
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "gear")
                            .font(.title2)
                            .foregroundColor(.gray)

                        Text("To set up Focus filters:")
                            .font(.headline)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        InstructionItem(number: 1, text: "Open Settings app")
                        InstructionItem(number: 2, text: "Go to Focus")
                        InstructionItem(number: 3, text: "Select a Focus mode")
                        InstructionItem(number: 4, text: "Tap 'Add Filter'")
                        InstructionItem(number: 5, text: "Choose OmniSite Tracker")
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Setup Instructions")
            }
        }
        .navigationTitle("Focus Filters")
        .onAppear {
            loadCurrentSettings()
        }
    }

    private func loadCurrentSettings() {
        notificationsEnabled = focusSettings.notificationsEnabled
        showReminders = focusSettings.showReminders
        quietHoursEnabled = focusSettings.quietHoursStart != nil
        quietStart = focusSettings.quietHoursStart ?? 22
        quietEnd = focusSettings.quietHoursEnd ?? 7
    }

    private func updateSettings() {
        Task { @MainActor in
            focusSettings.update(
                notificationsEnabled: notificationsEnabled,
                showReminders: showReminders,
                activeProfileName: nil,
                quietHoursStart: quietHoursEnabled ? quietStart : nil,
                quietHoursEnd: quietHoursEnabled ? quietEnd : nil
            )
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }
}

// MARK: - Instruction Item

private struct InstructionItem: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.purple)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FocusSettingsView()
    }
}
