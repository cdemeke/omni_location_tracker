//
//  OmniSiteShortcuts.swift
//  OmniSiteTracker
//
//  Provides App Shortcuts for the Shortcuts app and Siri.
//  Defines the shortcuts that appear in the Shortcuts app.
//

import AppIntents

/// Provides pre-configured shortcuts for the Shortcuts app
struct OmniSiteShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogPlacementIntent(),
            phrases: [
                "Log pump site in \(.applicationName)",
                "Log \(.applicationName) placement",
                "Record pump site with \(.applicationName)",
                "Log my \(.applicationName)",
                "New pump site in \(.applicationName)"
            ],
            shortTitle: "Log Pump Site",
            systemImageName: "cross.fill"
        )

        AppShortcut(
            intent: GetRecommendationIntent(),
            phrases: [
                "Where should I put my pump with \(.applicationName)",
                "Get pump site recommendation from \(.applicationName)",
                "Recommend pump site with \(.applicationName)",
                "Best pump site from \(.applicationName)",
                "Which site is ready in \(.applicationName)"
            ],
            shortTitle: "Get Recommendation",
            systemImageName: "star.fill"
        )

        AppShortcut(
            intent: GetSiteStatusIntent(),
            phrases: [
                "Check pump site status in \(.applicationName)",
                "Is my pump site ready in \(.applicationName)",
                "When was pump site last used in \(.applicationName)",
                "Pump site status from \(.applicationName)"
            ],
            shortTitle: "Check Site Status",
            systemImageName: "clock.fill"
        )
    }
}
