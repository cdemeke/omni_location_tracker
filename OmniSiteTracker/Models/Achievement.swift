//
//  Achievement.swift
//  OmniSiteTracker
//
//  Model for gamification achievements.
//  Rewards users for maintaining good pump site rotation habits.
//

import Foundation
import SwiftData

/// Represents an achievement that has been earned by the user
@Model
final class Achievement {
    /// Unique identifier for this achievement instance
    var id: UUID

    /// The type of achievement earned
    var typeRawValue: String

    /// When the achievement was earned
    var earnedAt: Date

    /// Optional additional data (e.g., streak count when earned)
    var metadata: String?

    /// Computed property to get the strongly-typed achievement type
    var type: AchievementType? {
        AchievementType(rawValue: typeRawValue)
    }

    init(type: AchievementType, metadata: String? = nil) {
        self.id = UUID()
        self.typeRawValue = type.rawValue
        self.earnedAt = .now
        self.metadata = metadata
    }
}

/// Types of achievements that can be earned
enum AchievementType: String, CaseIterable, Identifiable {
    // MARK: - Rotation Achievements
    case firstPlacement = "first_placement"
    case rotationRookie = "rotation_rookie"           // 5 placements using different sites
    case rotationPro = "rotation_pro"                 // 20 placements with good rotation
    case rotationMaster = "rotation_master"           // 50 placements with good rotation
    case perfectRotation = "perfect_rotation"         // 10 consecutive placements at different sites

    // MARK: - Streak Achievements
    case streakStarter = "streak_starter"             // 7-day logging streak
    case streakBuilder = "streak_builder"             // 14-day logging streak
    case streakChampion = "streak_champion"           // 30-day logging streak
    case streakLegend = "streak_legend"               // 90-day logging streak

    // MARK: - Consistency Achievements
    case consistentLogger = "consistent_logger"       // Logged every placement for a month
    case restRespector = "rest_respector"             // Always waited minimum rest days (10 placements)
    case allSitesExplorer = "all_sites_explorer"      // Used all 9 default body sites

    // MARK: - Milestone Achievements
    case centurion = "centurion"                      // 100 total placements
    case dedication = "dedication"                    // 1 year of using the app

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstPlacement: return "First Steps"
        case .rotationRookie: return "Rotation Rookie"
        case .rotationPro: return "Rotation Pro"
        case .rotationMaster: return "Rotation Master"
        case .perfectRotation: return "Perfect Rotation"
        case .streakStarter: return "Streak Starter"
        case .streakBuilder: return "Streak Builder"
        case .streakChampion: return "Streak Champion"
        case .streakLegend: return "Streak Legend"
        case .consistentLogger: return "Consistent Logger"
        case .restRespector: return "Rest Respector"
        case .allSitesExplorer: return "Site Explorer"
        case .centurion: return "Centurion"
        case .dedication: return "Dedicated"
        }
    }

    var description: String {
        switch self {
        case .firstPlacement:
            return "Log your first pump site placement"
        case .rotationRookie:
            return "Use 5 different body sites"
        case .rotationPro:
            return "Log 20 placements with good rotation"
        case .rotationMaster:
            return "Log 50 placements with good rotation"
        case .perfectRotation:
            return "Use 10 different sites in a row"
        case .streakStarter:
            return "Log placements for 7 days in a row"
        case .streakBuilder:
            return "Log placements for 14 days in a row"
        case .streakChampion:
            return "Log placements for 30 days in a row"
        case .streakLegend:
            return "Log placements for 90 days in a row"
        case .consistentLogger:
            return "Log every placement for a full month"
        case .restRespector:
            return "Always wait the minimum rest days (10+ placements)"
        case .allSitesExplorer:
            return "Try all 9 default body sites"
        case .centurion:
            return "Log 100 pump site placements"
        case .dedication:
            return "Use the app for a full year"
        }
    }

    var iconName: String {
        switch self {
        case .firstPlacement: return "star.fill"
        case .rotationRookie: return "arrow.triangle.2.circlepath"
        case .rotationPro: return "arrow.triangle.2.circlepath.circle"
        case .rotationMaster: return "arrow.triangle.2.circlepath.circle.fill"
        case .perfectRotation: return "crown.fill"
        case .streakStarter: return "flame"
        case .streakBuilder: return "flame.fill"
        case .streakChampion: return "bolt.fill"
        case .streakLegend: return "bolt.circle.fill"
        case .consistentLogger: return "calendar.badge.checkmark"
        case .restRespector: return "clock.badge.checkmark"
        case .allSitesExplorer: return "map.fill"
        case .centurion: return "100.circle.fill"
        case .dedication: return "heart.circle.fill"
        }
    }

    var tier: AchievementTier {
        switch self {
        case .firstPlacement, .rotationRookie, .streakStarter:
            return .bronze
        case .rotationPro, .streakBuilder, .consistentLogger, .restRespector:
            return .silver
        case .rotationMaster, .streakChampion, .allSitesExplorer, .centurion:
            return .gold
        case .perfectRotation, .streakLegend, .dedication:
            return .platinum
        }
    }

    var points: Int {
        tier.points
    }
}

/// Achievement tiers with associated colors and points
enum AchievementTier: String, CaseIterable {
    case bronze
    case silver
    case gold
    case platinum

    var points: Int {
        switch self {
        case .bronze: return 10
        case .silver: return 25
        case .gold: return 50
        case .platinum: return 100
        }
    }

    var colorName: String {
        switch self {
        case .bronze: return "bronze"
        case .silver: return "silver"
        case .gold: return "gold"
        case .platinum: return "platinum"
        }
    }
}
