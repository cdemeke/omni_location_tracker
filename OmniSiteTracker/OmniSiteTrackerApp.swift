//
//  OmniSiteTrackerApp.swift
//  OmniSiteTracker
//
//  A SwiftUI app for tracking and rotating insulin pump placement sites.
//  Designed for Type 1 Diabetes patients and caregivers.
//

import SwiftUI
import SwiftData

/// Main entry point for the OmniSite Tracker application.
/// Configures SwiftData persistence and establishes the root view hierarchy.
@main
struct OmniSiteTrackerApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            // Configure SwiftData with explicit schema and local-only storage
            let schema = Schema([PlacementLog.self, UserSettings.self, CustomSite.self])
            let config = ModelConfiguration(
                "OmniSiteTracker",
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Fallback to default container if custom config fails
            // This should rarely happen in production
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
