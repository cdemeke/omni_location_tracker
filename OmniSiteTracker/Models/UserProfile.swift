//
//  UserProfile.swift
//  OmniSiteTracker
//
//  Model for supporting multiple user profiles.
//  Enables families with multiple diabetics to track separately.
//

import Foundation
import SwiftData
import SwiftUI

/// Represents a user profile for multi-user support
@Model
final class UserProfile {
    /// Unique identifier for this profile
    var id: UUID

    /// Display name for the profile
    var name: String

    /// Color theme for the profile (stored as hex string)
    var colorHex: String

    /// Optional avatar image name or SF Symbol
    var avatarName: String

    /// Whether this is the currently active profile
    var isActive: Bool

    /// When the profile was created
    var createdAt: Date

    /// Unique minimum rest days setting for this profile
    var minimumRestDays: Int

    init(
        name: String,
        colorHex: String = "#E88C73",
        avatarName: String = "person.fill",
        minimumRestDays: Int = 18
    ) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.avatarName = avatarName
        self.isActive = false
        self.createdAt = .now
        self.minimumRestDays = minimumRestDays
    }

    /// Default profile ID for legacy data migration
    static var defaultProfileId: UUID {
        // Use a consistent UUID for the default profile
        UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    }
}

// MARK: - Color Helpers

extension UserProfile {
    /// Profile color as SwiftUI Color
    var color: Color {
        Color(hex: colorHex) ?? .appAccent
    }

    /// Available profile colors
    static let availableColors: [(name: String, hex: String)] = [
        ("Coral", "#E88C73"),
        ("Ocean", "#5B8FB9"),
        ("Forest", "#6B9B6B"),
        ("Lavender", "#9B89B3"),
        ("Sunset", "#E6A86B"),
        ("Berry", "#B56B8B"),
        ("Teal", "#5B9B9B"),
        ("Amber", "#C49B5B")
    ]

    /// Available avatar options
    static let availableAvatars: [String] = [
        "person.fill",
        "person.circle.fill",
        "face.smiling.fill",
        "star.fill",
        "heart.fill",
        "leaf.fill",
        "moon.fill",
        "sun.max.fill"
    ]
}

// MARK: - Profile Management

extension UserProfile {
    /// Gets or creates the default profile
    /// - Parameter context: The SwiftData model context
    /// - Returns: The default profile
    static func getOrCreateDefault(context: ModelContext) -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.id == UserProfile.defaultProfileId }
        )

        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        // Create default profile
        let defaultProfile = UserProfile(name: "Default")
        defaultProfile.id = defaultProfileId
        defaultProfile.isActive = true
        context.insert(defaultProfile)
        try? context.save()

        return defaultProfile
    }

    /// Gets the currently active profile
    /// - Parameter context: The SwiftData model context
    /// - Returns: The active profile, or default if none is active
    static func getActive(context: ModelContext) -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.isActive == true }
        )

        if let active = try? context.fetch(descriptor).first {
            return active
        }

        return getOrCreateDefault(context: context)
    }

    /// Gets all profiles sorted by creation date
    /// - Parameter context: The SwiftData model context
    /// - Returns: Array of all profiles
    static func getAll(context: ModelContext) -> [UserProfile] {
        let descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Sets this profile as the active profile
    /// - Parameter context: The SwiftData model context
    func setAsActive(context: ModelContext) {
        // Deactivate all other profiles
        let descriptor = FetchDescriptor<UserProfile>()
        if let allProfiles = try? context.fetch(descriptor) {
            for profile in allProfiles {
                profile.isActive = false
            }
        }

        // Activate this profile
        self.isActive = true
        try? context.save()
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6 else { return nil }

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}
