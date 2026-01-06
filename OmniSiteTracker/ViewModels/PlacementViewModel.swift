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
    private var _cachedRecommendation: SiteRecommendation?
    private var _recommendationComputed = false

    var lastUsedDates: [BodyLocation: Date] { _lastUsedDates }

    var recommendedSite: SiteRecommendation? {
        if !_recommendationComputed {
            _cachedRecommendation = computeRecommendation()
            _recommendationComputed = true
        }
        return _cachedRecommendation
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

        // Invalidate recommendation cache
        _recommendationComputed = false
        _cachedRecommendation = nil
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
