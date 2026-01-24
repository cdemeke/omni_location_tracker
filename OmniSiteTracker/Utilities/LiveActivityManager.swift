//
//  LiveActivityManager.swift
//  OmniSiteTracker
//
//  Manages Live Activities for Dynamic Island and Lock Screen.
//  Shows current site status and time until next change.
//

import Foundation
import ActivityKit
import SwiftUI

// MARK: - Live Activity Attributes

/// Attributes for the site tracking Live Activity
struct SiteTrackingAttributes: ActivityAttributes {
    /// Content state that can change during the activity
    public struct ContentState: Codable, Hashable {
        var currentSite: String
        var placedAt: Date
        var hoursUntilChange: Int
        var isTimeToChange: Bool
        var recommendedNextSite: String
    }

    /// Static attributes that don't change
    var siteName: String
    var siteType: String // "default" or "custom"
}

// MARK: - Live Activity Manager

/// Manages Live Activities for the app
@MainActor
@Observable
final class LiveActivityManager {
    // MARK: - Singleton

    static let shared = LiveActivityManager()

    // MARK: - Properties

    /// Current active Live Activity
    private var currentActivity: Activity<SiteTrackingAttributes>?

    /// Whether Live Activities are supported
    var areActivitiesSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// Whether there's an active Live Activity
    var hasActiveActivity: Bool {
        currentActivity != nil
    }

    // MARK: - Initialization

    private init() {
        // Clean up any stale activities on launch
        Task {
            await cleanupStaleActivities()
        }
    }

    // MARK: - Public Methods

    /// Starts a new Live Activity for a placement
    func startActivity(
        currentSite: String,
        siteType: String,
        placedAt: Date,
        hoursUntilChange: Int,
        recommendedNextSite: String
    ) async throws {
        guard areActivitiesSupported else {
            throw LiveActivityError.notSupported
        }

        // End any existing activity first
        await endActivity()

        let attributes = SiteTrackingAttributes(
            siteName: currentSite,
            siteType: siteType
        )

        let initialState = SiteTrackingAttributes.ContentState(
            currentSite: currentSite,
            placedAt: placedAt,
            hoursUntilChange: hoursUntilChange,
            isTimeToChange: false,
            recommendedNextSite: recommendedNextSite
        )

        let content = ActivityContent(
            state: initialState,
            staleDate: Calendar.current.date(byAdding: .hour, value: hoursUntilChange, to: .now)
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            throw LiveActivityError.startFailed(error.localizedDescription)
        }
    }

    /// Updates the current Live Activity
    func updateActivity(
        hoursUntilChange: Int,
        isTimeToChange: Bool,
        recommendedNextSite: String
    ) async {
        guard let activity = currentActivity else { return }

        let updatedState = SiteTrackingAttributes.ContentState(
            currentSite: activity.attributes.siteName,
            placedAt: activity.content.state.placedAt,
            hoursUntilChange: hoursUntilChange,
            isTimeToChange: isTimeToChange,
            recommendedNextSite: recommendedNextSite
        )

        let content = ActivityContent(
            state: updatedState,
            staleDate: isTimeToChange ? nil : Calendar.current.date(byAdding: .hour, value: hoursUntilChange, to: .now)
        )

        await activity.update(content)
    }

    /// Ends the current Live Activity
    func endActivity(dismissalPolicy: ActivityUIDismissalPolicy = .default) async {
        guard let activity = currentActivity else { return }

        let finalState = activity.content.state

        await activity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: dismissalPolicy
        )

        currentActivity = nil
    }

    // MARK: - Private Methods

    private func cleanupStaleActivities() async {
        for activity in Activity<SiteTrackingAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}

// MARK: - Errors

enum LiveActivityError: LocalizedError {
    case notSupported
    case startFailed(String)

    var errorDescription: String? {
        switch self {
        case .notSupported:
            return "Live Activities are not supported on this device"
        case .startFailed(let message):
            return "Failed to start Live Activity: \(message)"
        }
    }
}

// MARK: - Live Activity Views (for Widget Extension)

struct SiteTrackingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SiteTrackingAttributes.self) { context in
            // Lock Screen / Banner view
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Site")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(context.state.currentSite)
                            .font(.headline)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Time Left")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(context.state.hoursUntilChange)h")
                            .font(.headline)
                            .foregroundColor(context.state.isTimeToChange ? .red : .primary)
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    // Empty center
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "arrow.right")
                        Text("Next: \(context.state.recommendedNextSite)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            } compactLeading: {
                // Compact leading
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(context.state.isTimeToChange ? .red : .blue)
            } compactTrailing: {
                // Compact trailing
                Text("\(context.state.hoursUntilChange)h")
                    .font(.caption)
                    .foregroundColor(context.state.isTimeToChange ? .red : .secondary)
            } minimal: {
                // Minimal view
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(context.state.isTimeToChange ? .red : .blue)
            }
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenView: View {
    let context: ActivityViewContext<SiteTrackingAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Left side - Current site
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(context.state.isTimeToChange ? .red : .blue)
                    Text("Current Site")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(context.state.currentSite)
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Spacer()

            // Center - Time indicator
            VStack(spacing: 4) {
                if context.state.isTimeToChange {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                    Text("Time to change!")
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Text("\(context.state.hoursUntilChange)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("hours left")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Right side - Next recommendation
            VStack(alignment: .trailing, spacing: 4) {
                Text("Next Site")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(context.state.recommendedNextSite)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
}

// MARK: - Live Activity Settings View

struct LiveActivitySettingsView: View {
    @State private var liveActivityManager = LiveActivityManager.shared

    @AppStorage("liveActivity_autoStart") private var autoStartEnabled = true
    @AppStorage("liveActivity_changeThreshold") private var changeThresholdHours = 72

    var body: some View {
        List {
            // Status section
            Section {
                HStack {
                    Image(systemName: liveActivityManager.areActivitiesSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(liveActivityManager.areActivitiesSupported ? .green : .red)

                    VStack(alignment: .leading) {
                        Text("Live Activities")
                        Text(liveActivityManager.areActivitiesSupported ? "Supported" : "Not Supported")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if liveActivityManager.hasActiveActivity {
                    Button(role: .destructive) {
                        Task {
                            await liveActivityManager.endActivity()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "stop.circle")
                            Text("Stop Live Activity")
                        }
                    }
                }
            } header: {
                Text("Status")
            }

            // Settings section
            if liveActivityManager.areActivitiesSupported {
                Section {
                    Toggle("Auto-start on placement", isOn: $autoStartEnabled)

                    Stepper(
                        "Change threshold: \(changeThresholdHours) hours",
                        value: $changeThresholdHours,
                        in: 24...168,
                        step: 12
                    )
                } header: {
                    Text("Settings")
                } footer: {
                    Text("Live Activities will show on your Lock Screen and Dynamic Island to help you track your current pump site.")
                }
            }

            // Info section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "rectangle.badge.checkmark", text: "Shows on Lock Screen")
                    FeatureRow(icon: "iphone.gen3", text: "Dynamic Island support")
                    FeatureRow(icon: "clock", text: "Countdown to next change")
                    FeatureRow(icon: "mappin", text: "Shows next recommended site")
                }
                .padding(.vertical, 8)
            } header: {
                Text("Features")
            }
        }
        .navigationTitle("Live Activities")
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(text)
                .font(.body)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LiveActivitySettingsView()
    }
}
