//
//  HeatmapModels.swift
//  OmniSiteTracker
//
//  Data models for heatmap visualization and rotation compliance scoring.
//

import Foundation

/// Represents usage density data for a single body location in the heatmap view.
struct HeatmapData: Identifiable {
    /// The body location this data represents
    let location: BodyLocation

    /// Total number of placements at this location within the date range
    let usageCount: Int

    /// Normalized intensity value (0-1) where 1 represents the highest usage location
    let intensity: Double

    /// The most recent placement date at this location, if any
    let lastUsed: Date?

    /// This location's usage as a percentage of total placements (0-100)
    let percentageOfTotal: Double

    var id: String { location.id }
}

/// Represents a rotation compliance score measuring how well the user rotates placement sites.
struct RotationScore {
    /// Overall compliance score (0-100)
    let score: Int

    /// Score component measuring even distribution across locations (0-50)
    let distributionScore: Int

    /// Score component measuring adherence to 3-day rest period between same-site uses (0-50)
    let restComplianceScore: Int

    /// Human-readable explanation of the score
    let explanation: String
}

/// Represents a single data point for trend charts.
struct TrendDataPoint: Identifiable {
    /// The date for this data point (start of the grouping period)
    let date: Date

    /// Number of placements in this time period
    let count: Int

    /// Optional location for location-specific trend data
    let location: BodyLocation?

    var id: String {
        if let location = location {
            return "\(date.timeIntervalSince1970)-\(location.id)"
        }
        return "\(date.timeIntervalSince1970)"
    }

    init(date: Date, count: Int, location: BodyLocation? = nil) {
        self.date = date
        self.count = count
        self.location = location
    }
}
