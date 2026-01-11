//
//  PlacementViewModel.swift
//  OmniSiteTracker
//
//  ViewModel managing placement data, history, and site recommendations.
//  Optimized for fast startup and minimal recomputation.
//

import Foundation
import SwiftData
import SwiftUI

/// Represents a site recommendation with explanation
struct SiteRecommendation: Equatable {
    let location: BodyLocation
    let daysSinceLastUse: Int?
    let reason: String

    var explanation: String {
        if let days = daysSinceLastUse {
            if days == 0 {
                return "Used today"
            } else if days == 1 {
                return "Not used in 1 day"
            } else {
                return "Not used in \(days) days"
            }
        } else {
            return "Never used before"
        }
    }
}

/// Main ViewModel for placement tracking and recommendations
/// Uses @Observable for SwiftUI integration with cached computations for performance
@Observable
final class PlacementViewModel {
    /// Minimum days between using the same site
    static let minimumRestDays: Int = 3

    private var modelContext: ModelContext?

    /// All placement logs, sorted by date (most recent first)
    private(set) var placements: [PlacementLog] = []

    /// Cached map of location to last used date - updated when placements change
    private var _lastUsedDates: [BodyLocation: Date] = [:]

    /// Cached recommendation - updated when placements change
    private(set) var _cachedRecommendation: SiteRecommendation?

    var lastUsedDates: [BodyLocation: Date] { _lastUsedDates }

    var recommendedSite: SiteRecommendation? {
        _cachedRecommendation
    }

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchPlacements()
    }

    func fetchPlacements() {
        guard let modelContext else { return }

        let descriptor = FetchDescriptor<PlacementLog>(
            sortBy: [SortDescriptor(\.placedAt, order: .reverse)]
        )

        do {
            placements = try modelContext.fetch(descriptor)
            updateCaches()
        } catch {
            placements = []
            updateCaches()
        }
    }

    /// Updates cached computed values after placements change
    private func updateCaches() {
        // Update lastUsedDates cache
        var dates: [BodyLocation: Date] = [:]
        for placement in placements {
            if dates[placement.location] == nil {
                dates[placement.location] = placement.placedAt
            }
        }
        _lastUsedDates = dates

        // Compute recommendation eagerly (avoids mutation during property access)
        _cachedRecommendation = computeRecommendation()
    }

    func logPlacement(at location: BodyLocation, note: String? = nil) {
        guard let modelContext else { return }

        let newPlacement = PlacementLog(
            location: location,
            placedAt: .now,
            note: note?.isEmpty == true ? nil : note
        )

        modelContext.insert(newPlacement)

        do {
            try modelContext.save()
            fetchPlacements()
        } catch {
            // Silent fail - data will be available next launch
        }
    }

    func deletePlacement(_ placement: PlacementLog) {
        guard let modelContext else { return }

        modelContext.delete(placement)

        do {
            try modelContext.save()
            fetchPlacements()
        } catch {
            // Silent fail
        }
    }

    func updatePlacement(_ placement: PlacementLog, location: BodyLocation, date: Date, note: String?) {
        placement.location = location
        placement.placedAt = date
        placement.note = note

        guard let modelContext else { return }

        do {
            try modelContext.save()
            fetchPlacements()
        } catch {
            // Silent fail
        }
    }

    func daysSinceLastUse(for location: BodyLocation) -> Int? {
        guard let lastDate = _lastUsedDates[location] else {
            return nil
        }
        return Calendar.current.dateComponents([.day], from: lastDate, to: .now).day
    }

    func isLocationRested(_ location: BodyLocation) -> Bool {
        guard let days = daysSinceLastUse(for: location) else {
            return true
        }
        return days >= Self.minimumRestDays
    }

    private func computeRecommendation() -> SiteRecommendation? {
        if placements.isEmpty {
            return SiteRecommendation(
                location: .abdomenRight,
                daysSinceLastUse: nil,
                reason: "Great starting location for your first placement"
            )
        }

        var candidates: [(location: BodyLocation, days: Int?)] = []

        for location in BodyLocation.allCases {
            let days = daysSinceLastUse(for: location)
            candidates.append((location, days))
        }

        let sortedCandidates = candidates.sorted { a, b in
            switch (a.days, b.days) {
            case (nil, nil):
                return false
            case (nil, _):
                return true
            case (_, nil):
                return false
            case let (daysA?, daysB?):
                return daysA > daysB
            }
        }

        let eligibleCandidates = sortedCandidates.filter { candidate in
            guard let days = candidate.days else { return true }
            return days >= Self.minimumRestDays
        }

        if let best = eligibleCandidates.first {
            let reason = best.days == nil
                ? "This site hasn't been used yet"
                : "Longest rest period among available sites"
            return SiteRecommendation(
                location: best.location,
                daysSinceLastUse: best.days,
                reason: reason
            )
        }

        if let fallback = sortedCandidates.first {
            return SiteRecommendation(
                location: fallback.location,
                daysSinceLastUse: fallback.days,
                reason: "All sites used recently - this one has the longest rest"
            )
        }

        return nil
    }

    func placements(for location: BodyLocation) -> [PlacementLog] {
        placements.filter { $0.location == location }
    }

    var mostRecentPlacement: PlacementLog? {
        placements.first
    }

    var placementsByDay: [(date: Date, placements: [PlacementLog])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: placements) { placement in
            calendar.startOfDay(for: placement.placedAt)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, placements: $0.value) }
    }
}

// MARK: - Heatmap Data Generation

extension PlacementViewModel {
    /// Generates heatmap data for all body locations within the specified date range.
    /// - Parameters:
    ///   - from: Start date of the range (inclusive)
    ///   - to: End date of the range (inclusive)
    /// - Returns: Array of HeatmapData for all 8 body locations
    func generateHeatmapData(from startDate: Date, to endDate: Date) -> [HeatmapData] {
        // Filter placements to only include those within date range
        let filteredPlacements = placements.filter { placement in
            placement.placedAt >= startDate && placement.placedAt <= endDate
        }

        // Count placements per location
        var countsByLocation: [BodyLocation: Int] = [:]
        var lastUsedByLocation: [BodyLocation: Date] = [:]

        for placement in filteredPlacements {
            countsByLocation[placement.location, default: 0] += 1

            // Track last used date (most recent first due to sorting)
            if lastUsedByLocation[placement.location] == nil {
                lastUsedByLocation[placement.location] = placement.placedAt
            } else if let existing = lastUsedByLocation[placement.location],
                      placement.placedAt > existing {
                lastUsedByLocation[placement.location] = placement.placedAt
            }
        }

        // Calculate max count for intensity calculation
        let maxCount = countsByLocation.values.max() ?? 0
        let totalPlacements = filteredPlacements.count

        // Generate HeatmapData for all 8 locations
        return BodyLocation.allCases.map { location in
            let usageCount = countsByLocation[location] ?? 0
            let intensity: Double = maxCount > 0 ? Double(usageCount) / Double(maxCount) : 0
            let percentageOfTotal: Double = totalPlacements > 0
                ? (Double(usageCount) / Double(totalPlacements)) * 100
                : 0

            return HeatmapData(
                location: location,
                usageCount: usageCount,
                intensity: intensity,
                lastUsed: lastUsedByLocation[location],
                percentageOfTotal: percentageOfTotal
            )
        }
    }
}

// MARK: - Rotation Score Calculation

extension PlacementViewModel {
    /// Calculates a rotation compliance score measuring how well the user rotates placement sites.
    /// - Parameters:
    ///   - from: Start date of the range (inclusive)
    ///   - to: End date of the range (inclusive)
    /// - Returns: RotationScore with distribution and rest compliance components
    func calculateRotationScore(from startDate: Date, to endDate: Date) -> RotationScore {
        // Filter placements to only include those within date range
        let filteredPlacements = placements.filter { placement in
            placement.placedAt >= startDate && placement.placedAt <= endDate
        }

        // Return score of 0 if fewer than 5 placements
        guard filteredPlacements.count >= 5 else {
            return RotationScore(
                score: 0,
                distributionScore: 0,
                restComplianceScore: 0,
                explanation: "Not enough data. Log at least 5 placements to see your rotation score."
            )
        }

        // Calculate distribution score (0-50)
        // Measures how evenly placements are distributed across all 8 locations
        let distributionScore = calculateDistributionScore(from: filteredPlacements)

        // Calculate rest compliance score (0-50)
        // Measures adherence to 3-day rest period between same-site uses
        let restComplianceScore = calculateRestComplianceScore(from: filteredPlacements)

        let totalScore = distributionScore + restComplianceScore

        // Generate explanation
        let explanation = generateScoreExplanation(
            totalScore: totalScore,
            distributionScore: distributionScore,
            restComplianceScore: restComplianceScore,
            placementCount: filteredPlacements.count
        )

        return RotationScore(
            score: totalScore,
            distributionScore: distributionScore,
            restComplianceScore: restComplianceScore,
            explanation: explanation
        )
    }

    /// Calculates distribution score based on how evenly placements are spread across locations.
    /// Perfect distribution = 50 points, all in one location = ~6 points
    private func calculateDistributionScore(from placements: [PlacementLog]) -> Int {
        let totalLocations = BodyLocation.allCases.count // 8
        var countsByLocation: [BodyLocation: Int] = [:]

        for placement in placements {
            countsByLocation[placement.location, default: 0] += 1
        }

        let totalPlacements = placements.count
        let idealCountPerLocation = Double(totalPlacements) / Double(totalLocations)

        // Calculate variance from ideal distribution
        // Using coefficient of variation approach
        var sumOfSquaredDifferences: Double = 0

        for location in BodyLocation.allCases {
            let actualCount = Double(countsByLocation[location] ?? 0)
            let difference = actualCount - idealCountPerLocation
            sumOfSquaredDifferences += difference * difference
        }

        // Calculate normalized score
        // Perfect distribution has variance 0, worst case is all in one location
        let maxPossibleVariance = Double(totalPlacements * totalPlacements) * Double(totalLocations - 1) / Double(totalLocations)
        let normalizedVariance = maxPossibleVariance > 0 ? sumOfSquaredDifferences / maxPossibleVariance : 0

        // Convert to score: 0 variance = 50 points, max variance = 0 points
        let score = Int(round(50.0 * (1.0 - normalizedVariance)))
        return max(0, min(50, score))
    }

    /// Calculates rest compliance score based on adherence to 3-day rest between same-site uses.
    /// Each violation reduces the score proportionally.
    private func calculateRestComplianceScore(from placements: [PlacementLog]) -> Int {
        // Group placements by location and sort by date
        var placementsByLocation: [BodyLocation: [PlacementLog]] = [:]

        for placement in placements {
            placementsByLocation[placement.location, default: []].append(placement)
        }

        // Sort each location's placements by date
        for location in placementsByLocation.keys {
            placementsByLocation[location]?.sort { $0.placedAt < $1.placedAt }
        }

        var violations = 0
        var totalChecks = 0

        // Check each consecutive pair of same-site placements
        for (_, locationPlacements) in placementsByLocation {
            for i in 1..<locationPlacements.count {
                let previousPlacement = locationPlacements[i - 1]
                let currentPlacement = locationPlacements[i]

                let daysBetween = Calendar.current.dateComponents(
                    [.day],
                    from: previousPlacement.placedAt,
                    to: currentPlacement.placedAt
                ).day ?? 0

                totalChecks += 1

                if daysBetween < Self.minimumRestDays {
                    violations += 1
                }
            }
        }

        // If no consecutive same-site uses, perfect score
        guard totalChecks > 0 else {
            return 50
        }

        // Calculate compliance percentage and convert to score
        let complianceRate = 1.0 - (Double(violations) / Double(totalChecks))
        return Int(round(50.0 * complianceRate))
    }

    /// Generates a human-readable explanation for the rotation score.
    private func generateScoreExplanation(
        totalScore: Int,
        distributionScore: Int,
        restComplianceScore: Int,
        placementCount: Int
    ) -> String {
        var parts: [String] = []

        // Overall assessment
        if totalScore >= 80 {
            parts.append("Excellent rotation habits!")
        } else if totalScore >= 60 {
            parts.append("Good rotation practices.")
        } else if totalScore >= 40 {
            parts.append("Room for improvement.")
        } else {
            parts.append("Rotation needs attention.")
        }

        // Distribution feedback
        if distributionScore >= 40 {
            parts.append("Sites are well distributed.")
        } else if distributionScore >= 25 {
            parts.append("Try using more locations.")
        } else {
            parts.append("Relying too heavily on few sites.")
        }

        // Rest compliance feedback
        if restComplianceScore >= 40 {
            parts.append("Good rest periods maintained.")
        } else if restComplianceScore >= 25 {
            parts.append("Some sites need longer rest.")
        } else {
            parts.append("Allow 3+ days between same-site uses.")
        }

        return parts.joined(separator: " ")
    }
}

// MARK: - Placement Trend Data

/// Grouping period for trend data
enum DateGrouping {
    case day
    case week
}

extension PlacementViewModel {
    /// Returns placement counts grouped by time period for charting.
    /// - Parameters:
    ///   - from: Start date of the range (inclusive)
    ///   - to: End date of the range (inclusive)
    ///   - groupBy: Optional grouping period. If nil, auto-selects based on date range.
    /// - Returns: Array of TrendDataPoint sorted by date ascending
    func getPlacementTrend(from startDate: Date, to endDate: Date, groupBy: DateGrouping? = nil) -> [TrendDataPoint] {
        let calendar = Calendar.current

        // Auto-select grouping: day for ranges < 30 days, week for >= 30 days
        let daysBetween = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        let effectiveGrouping = groupBy ?? (daysBetween < 30 ? .day : .week)

        // Filter placements to only include those within date range
        let filteredPlacements = placements.filter { placement in
            placement.placedAt >= startDate && placement.placedAt <= endDate
        }

        // Group placements by the specified time period
        var countsByPeriod: [Date: Int] = [:]

        for placement in filteredPlacements {
            let periodStart: Date
            switch effectiveGrouping {
            case .day:
                periodStart = calendar.startOfDay(for: placement.placedAt)
            case .week:
                // Get the start of the week containing this date
                periodStart = calendar.dateInterval(of: .weekOfYear, for: placement.placedAt)?.start
                    ?? calendar.startOfDay(for: placement.placedAt)
            }
            countsByPeriod[periodStart, default: 0] += 1
        }

        // Generate periods for the entire date range (including zero-count periods)
        var allPeriods: [Date] = []
        var currentDate = effectiveGrouping == .day
            ? calendar.startOfDay(for: startDate)
            : (calendar.dateInterval(of: .weekOfYear, for: startDate)?.start ?? calendar.startOfDay(for: startDate))

        let rangeEnd = effectiveGrouping == .day
            ? calendar.startOfDay(for: endDate)
            : (calendar.dateInterval(of: .weekOfYear, for: endDate)?.start ?? calendar.startOfDay(for: endDate))

        while currentDate <= rangeEnd {
            allPeriods.append(currentDate)
            switch effectiveGrouping {
            case .day:
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            case .week:
                currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
            }
            // Safety check to prevent infinite loop
            if allPeriods.count > 1000 { break }
        }

        // Convert to TrendDataPoint array
        return allPeriods.map { periodDate in
            TrendDataPoint(date: periodDate, count: countsByPeriod[periodDate] ?? 0)
        }
    }

    /// Returns placement trends broken down by location for stacked charts.
    /// - Parameters:
    ///   - from: Start date of the range (inclusive)
    ///   - to: End date of the range (inclusive)
    ///   - groupBy: Grouping period (day or week)
    /// - Returns: Dictionary mapping each BodyLocation to its array of TrendDataPoint
    func getLocationTrend(from startDate: Date, to endDate: Date, groupBy: DateGrouping) -> [BodyLocation: [TrendDataPoint]] {
        let calendar = Calendar.current

        // Filter placements to only include those within date range
        let filteredPlacements = placements.filter { placement in
            placement.placedAt >= startDate && placement.placedAt <= endDate
        }

        // Group placements by location and then by time period
        var countsByLocationAndPeriod: [BodyLocation: [Date: Int]] = [:]

        // Initialize all locations
        for location in BodyLocation.allCases {
            countsByLocationAndPeriod[location] = [:]
        }

        for placement in filteredPlacements {
            let periodStart: Date
            switch groupBy {
            case .day:
                periodStart = calendar.startOfDay(for: placement.placedAt)
            case .week:
                periodStart = calendar.dateInterval(of: .weekOfYear, for: placement.placedAt)?.start
                    ?? calendar.startOfDay(for: placement.placedAt)
            }
            countsByLocationAndPeriod[placement.location, default: [:]][periodStart, default: 0] += 1
        }

        // Generate periods for the entire date range (including zero-count periods)
        var allPeriods: [Date] = []
        var currentDate = groupBy == .day
            ? calendar.startOfDay(for: startDate)
            : (calendar.dateInterval(of: .weekOfYear, for: startDate)?.start ?? calendar.startOfDay(for: startDate))

        let rangeEnd = groupBy == .day
            ? calendar.startOfDay(for: endDate)
            : (calendar.dateInterval(of: .weekOfYear, for: endDate)?.start ?? calendar.startOfDay(for: endDate))

        while currentDate <= rangeEnd {
            allPeriods.append(currentDate)
            switch groupBy {
            case .day:
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            case .week:
                currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
            }
            // Safety check to prevent infinite loop
            if allPeriods.count > 1000 { break }
        }

        // Convert to dictionary of TrendDataPoint arrays
        var result: [BodyLocation: [TrendDataPoint]] = [:]

        for location in BodyLocation.allCases {
            let locationCounts = countsByLocationAndPeriod[location] ?? [:]
            result[location] = allPeriods.map { periodDate in
                TrendDataPoint(
                    date: periodDate,
                    count: locationCounts[periodDate] ?? 0,
                    location: location
                )
            }
        }

        return result
    }
}

// MARK: - Status Helpers

extension PlacementViewModel {
    func statusColor(for location: BodyLocation) -> Color {
        guard let days = daysSinceLastUse(for: location) else {
            return Color.gray.opacity(0.4)
        }

        if days < Self.minimumRestDays {
            return Color.orange.opacity(0.7)
        } else if days < Self.minimumRestDays * 2 {
            return Color.green.opacity(0.55)
        } else {
            return Color.green.opacity(0.7)
        }
    }

    func statusDescription(for location: BodyLocation) -> String {
        guard let days = daysSinceLastUse(for: location) else {
            return "Available"
        }

        if days == 0 {
            return "Used today"
        } else if days == 1 {
            return "Used yesterday"
        } else if days < Self.minimumRestDays {
            return "Rest \(Self.minimumRestDays - days) more days"
        } else {
            return "Ready (\(days)d rest)"
        }
    }
}
