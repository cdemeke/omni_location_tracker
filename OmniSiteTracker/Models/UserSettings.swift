//
//  UserSettings.swift
//  OmniSiteTracker
//
//  SwiftData model for persisting user preference settings.
//

import Foundation
import SwiftData

/// Controls how left/right labels are mapped on the front-facing body diagram.
enum DiagramOrientation: String, CaseIterable, Identifiable {
    case patientPerspective = "patient_perspective"
    case mirrorPerspective = "mirror_perspective"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .patientPerspective:
            return "Patient"
        case .mirrorPerspective:
            return "Mirror"
        }
    }

    var description: String {
        switch self {
        case .patientPerspective:
            return "Left and right match the person's body."
        case .mirrorPerspective:
            return "Left and right match the screen."
        }
    }
}

/// Singleton model for storing user preference settings.
/// Uses SwiftData for automatic persistence with local-only storage.
@Model
final class UserSettings {
    /// Minimum number of days a site should rest before being used again
    var minimumRestDays: Int

    /// Whether to show disabled sites in history and patterns views
    var showDisabledSitesInHistory: Bool

    /// Whether the front body diagram should use screen-left/screen-right labels
    var usesMirrorDiagramOrientation: Bool = false

    /// Timestamp when settings were first created
    var createdAt: Date

    /// Timestamp when settings were last modified
    var updatedAt: Date

    /// Initializes user settings with default values
    init(
        minimumRestDays: Int = 18,
        showDisabledSitesInHistory: Bool = true,
        usesMirrorDiagramOrientation: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.minimumRestDays = minimumRestDays
        self.showDisabledSitesInHistory = showDisabledSitesInHistory
        self.usesMirrorDiagramOrientation = usesMirrorDiagramOrientation
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var diagramOrientation: DiagramOrientation {
        get {
            usesMirrorDiagramOrientation ? .mirrorPerspective : .patientPerspective
        }
        set {
            usesMirrorDiagramOrientation = newValue == .mirrorPerspective
        }
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
