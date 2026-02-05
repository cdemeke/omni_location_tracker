//
//  AchievementManager.swift
//  OmniSiteTracker
//
//  Manages achievement checking, awarding, and tracking.
//  Evaluates user actions and awards achievements when criteria are met.
//

import Foundation
import SwiftData

/// Manages achievement evaluation and awarding
@MainActor
@Observable
final class AchievementManager {
    // MARK: - Singleton

    static let shared = AchievementManager()

    // MARK: - Properties

    /// Recently earned achievements for showing celebration
    var recentlyEarned: [AchievementType] = []

    /// Whether to show celebration modal
    var showingCelebration = false

    // MARK: - Initialization

    private init() {}

    // MARK: - Achievement Checking

    /// Checks all achievements and awards any newly earned ones
    /// - Parameters:
    ///   - placements: All placement logs
    ///   - context: The SwiftData model context
    func checkAllAchievements(placements: [PlacementLog], context: ModelContext) {
        let earnedTypes = getEarnedAchievementTypes(context: context)
        var newlyEarned: [AchievementType] = []

        for type in AchievementType.allCases {
            // Skip if already earned
            guard !earnedTypes.contains(type) else { continue }

            // Check if achievement is now earned
            if isAchievementEarned(type, placements: placements, context: context) {
                awardAchievement(type, context: context)
                newlyEarned.append(type)
            }
        }

        // Show celebration if any new achievements
        if !newlyEarned.isEmpty {
            recentlyEarned = newlyEarned
            showingCelebration = true
        }
    }

    /// Checks if a specific achievement type has been earned
    private func isAchievementEarned(_ type: AchievementType, placements: [PlacementLog], context: ModelContext) -> Bool {
        switch type {
        case .firstPlacement:
            return !placements.isEmpty

        case .rotationRookie:
            return countUniqueSitesUsed(placements: placements) >= 5

        case .rotationPro:
            return placements.count >= 20 && hasGoodRotation(placements: placements, requiredCount: 20)

        case .rotationMaster:
            return placements.count >= 50 && hasGoodRotation(placements: placements, requiredCount: 50)

        case .perfectRotation:
            return hasConsecutiveUniqueSites(placements: placements, count: 10)

        case .streakStarter:
            return currentStreak(placements: placements) >= 7

        case .streakBuilder:
            return currentStreak(placements: placements) >= 14

        case .streakChampion:
            return currentStreak(placements: placements) >= 30

        case .streakLegend:
            return currentStreak(placements: placements) >= 90

        case .consistentLogger:
            return hasMonthOfConsistentLogging(placements: placements)

        case .restRespector:
            return hasAlwaysRespectedRest(placements: placements, minimumCount: 10, context: context)

        case .allSitesExplorer:
            return hasUsedAllDefaultSites(placements: placements)

        case .centurion:
            return placements.count >= 100

        case .dedication:
            return hasUsedAppForYear(placements: placements)
        }
    }

    // MARK: - Achievement Helpers

    private func countUniqueSitesUsed(placements: [PlacementLog]) -> Int {
        var sites: Set<String> = []
        for placement in placements {
            if let rawValue = placement.locationRawValue {
                sites.insert(rawValue)
            }
            if let customId = placement.customSiteId {
                sites.insert(customId.uuidString)
            }
        }
        return sites.count
    }

    private func hasGoodRotation(placements: [PlacementLog], requiredCount: Int) -> Bool {
        // Consider it "good rotation" if no consecutive placements at the same site
        let sortedPlacements = placements.sorted { $0.placedAt < $1.placedAt }
        var goodCount = 0
        var lastSite: String?

        for placement in sortedPlacements {
            let currentSite = placement.locationRawValue ?? placement.customSiteId?.uuidString
            if currentSite != lastSite {
                goodCount += 1
            }
            lastSite = currentSite

            if goodCount >= requiredCount {
                return true
            }
        }

        return goodCount >= requiredCount
    }

    private func hasConsecutiveUniqueSites(placements: [PlacementLog], count: Int) -> Bool {
        let sortedPlacements = placements.sorted { $0.placedAt < $1.placedAt }
        var usedSites: Set<String> = []
        var consecutiveUnique = 0

        for placement in sortedPlacements {
            let site = placement.locationRawValue ?? placement.customSiteId?.uuidString ?? ""

            if usedSites.contains(site) {
                // Reset
                usedSites.removeAll()
                consecutiveUnique = 0
            }

            usedSites.insert(site)
            consecutiveUnique += 1

            if consecutiveUnique >= count {
                return true
            }
        }

        return false
    }

    private func currentStreak(placements: [PlacementLog]) -> Int {
        guard !placements.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedPlacements = placements.sorted { $0.placedAt > $1.placedAt }

        // Check if we have a placement today or yesterday (streak is still active)
        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        guard let mostRecent = sortedPlacements.first else { return 0 }
        let mostRecentDay = calendar.startOfDay(for: mostRecent.placedAt)

        guard mostRecentDay >= yesterday else { return 0 }

        // Count consecutive days with placements
        var streak = 0
        var checkDate = mostRecentDay
        var placementDates: Set<Date> = []

        for placement in sortedPlacements {
            placementDates.insert(calendar.startOfDay(for: placement.placedAt))
        }

        while placementDates.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        return streak
    }

    private func hasMonthOfConsistentLogging(placements: [PlacementLog]) -> Bool {
        // For simplicity, check if there's a 30-day period with at least one placement per week
        // This is more forgiving than requiring daily logging
        guard placements.count >= 4 else { return false }

        let calendar = Calendar.current
        let sortedPlacements = placements.sorted { $0.placedAt < $1.placedAt }

        guard let firstDate = sortedPlacements.first?.placedAt,
              let lastDate = sortedPlacements.last?.placedAt else { return false }

        let daysBetween = calendar.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0
        return daysBetween >= 30
    }

    private func hasAlwaysRespectedRest(placements: [PlacementLog], minimumCount: Int, context: ModelContext) -> Bool {
        guard placements.count >= minimumCount else { return false }

        // Get minimum rest days from settings
        let settings = UserSettings.getOrCreate(context: context)
        let minRestDays = settings.minimumRestDays

        let calendar = Calendar.current
        var placementsByLocation: [String: [Date]] = [:]

        for placement in placements {
            let site = placement.locationRawValue ?? placement.customSiteId?.uuidString ?? ""
            placementsByLocation[site, default: []].append(placement.placedAt)
        }

        // Check each location for rest violations
        for (_, dates) in placementsByLocation {
            let sortedDates = dates.sorted()
            for i in 1..<sortedDates.count {
                let daysBetween = calendar.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0
                if daysBetween < minRestDays {
                    return false
                }
            }
        }

        return true
    }

    private func hasUsedAllDefaultSites(placements: [PlacementLog]) -> Bool {
        var usedLocations: Set<String> = []
        for placement in placements {
            if let rawValue = placement.locationRawValue {
                usedLocations.insert(rawValue)
            }
        }
        return usedLocations.count >= BodyLocation.allCases.count
    }

    private func hasUsedAppForYear(placements: [PlacementLog]) -> Bool {
        guard let firstPlacement = placements.min(by: { $0.placedAt < $1.placedAt }) else {
            return false
        }

        let calendar = Calendar.current
        let yearAgo = calendar.date(byAdding: .year, value: -1, to: .now)!
        return firstPlacement.placedAt <= yearAgo
    }

    // MARK: - Achievement Awarding

    private func awardAchievement(_ type: AchievementType, context: ModelContext) {
        let achievement = Achievement(type: type)
        context.insert(achievement)
        try? context.save()
    }

    // MARK: - Query Methods

    /// Gets all earned achievement types
    func getEarnedAchievementTypes(context: ModelContext) -> Set<AchievementType> {
        let descriptor = FetchDescriptor<Achievement>()
        let achievements = (try? context.fetch(descriptor)) ?? []
        return Set(achievements.compactMap { $0.type })
    }

    /// Gets all earned achievements
    func getEarnedAchievements(context: ModelContext) -> [Achievement] {
        let descriptor = FetchDescriptor<Achievement>(
            sortBy: [SortDescriptor(\.earnedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Calculates total points earned
    func getTotalPoints(context: ModelContext) -> Int {
        let earnedTypes = getEarnedAchievementTypes(context: context)
        return earnedTypes.reduce(0) { $0 + $1.points }
    }

    /// Gets progress toward unearned achievements
    func getProgress(for type: AchievementType, placements: [PlacementLog], context: ModelContext) -> Double {
        switch type {
        case .firstPlacement:
            return placements.isEmpty ? 0 : 1

        case .rotationRookie:
            return min(1.0, Double(countUniqueSitesUsed(placements: placements)) / 5.0)

        case .rotationPro:
            return min(1.0, Double(placements.count) / 20.0)

        case .rotationMaster:
            return min(1.0, Double(placements.count) / 50.0)

        case .centurion:
            return min(1.0, Double(placements.count) / 100.0)

        case .streakStarter:
            return min(1.0, Double(currentStreak(placements: placements)) / 7.0)

        case .streakBuilder:
            return min(1.0, Double(currentStreak(placements: placements)) / 14.0)

        case .streakChampion:
            return min(1.0, Double(currentStreak(placements: placements)) / 30.0)

        case .streakLegend:
            return min(1.0, Double(currentStreak(placements: placements)) / 90.0)

        case .allSitesExplorer:
            var usedLocations: Set<String> = []
            for placement in placements {
                if let rawValue = placement.locationRawValue {
                    usedLocations.insert(rawValue)
                }
            }
            return Double(usedLocations.count) / Double(BodyLocation.allCases.count)

        default:
            return 0
        }
    }

    /// Dismisses the celebration modal
    func dismissCelebration() {
        showingCelebration = false
        recentlyEarned = []
    }
}
