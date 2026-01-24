//
//  HealthKitManager.swift
//  OmniSiteTracker
//
//  Manages HealthKit integration for blood glucose data correlation.
//  Correlates glucose readings with pump site placements to help identify
//  sites that may perform better for insulin absorption.
//

import Foundation
import HealthKit
import SwiftData

/// Manages HealthKit authorization and blood glucose data queries.
/// Thread-safe singleton for coordinating glucose data correlation.
@MainActor
@Observable
final class HealthKitManager {
    // MARK: - Singleton

    static let shared = HealthKitManager()

    // MARK: - Properties

    private let healthStore = HKHealthStore()

    /// Whether HealthKit is available on this device
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Current authorization status for blood glucose
    var authorizationStatus: HKAuthorizationStatus {
        guard let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) else {
            return .notDetermined
        }
        return healthStore.authorizationStatus(for: glucoseType)
    }

    /// Whether we have authorization to read glucose data
    var isAuthorized: Bool {
        authorizationStatus == .sharingAuthorized
    }

    /// Whether authorization has been requested but denied
    var isDenied: Bool {
        authorizationStatus == .sharingDenied
    }

    /// Loading state for UI feedback
    var isLoading = false

    /// Error message for UI display
    var errorMessage: String?

    // MARK: - Initialization

    private init() {}

    // MARK: - Authorization

    /// Requests authorization to read blood glucose data from HealthKit
    /// - Returns: Whether authorization was granted
    func requestAuthorization() async -> Bool {
        guard isHealthKitAvailable else {
            errorMessage = "HealthKit is not available on this device"
            return false
        }

        guard let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) else {
            errorMessage = "Blood glucose type not available"
            return false
        }

        let typesToRead: Set<HKSampleType> = [glucoseType]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Failed to authorize HealthKit: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Glucose Data Queries

    /// Fetches blood glucose readings for a specific date range
    /// - Parameters:
    ///   - startDate: The start of the date range
    ///   - endDate: The end of the date range
    /// - Returns: Array of glucose readings with timestamps and values in mg/dL
    func fetchGlucoseReadings(from startDate: Date, to endDate: Date) async -> [GlucoseReading] {
        guard isHealthKitAvailable else { return [] }

        guard let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: glucoseType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    Task { @MainActor in
                        self.errorMessage = error.localizedDescription
                    }
                    continuation.resume(returning: [])
                    return
                }

                let readings = (samples as? [HKQuantitySample])?.map { sample in
                    let mgPerDL = sample.quantity.doubleValue(for: HKUnit(from: "mg/dL"))
                    return GlucoseReading(
                        timestamp: sample.startDate,
                        value: mgPerDL,
                        source: sample.sourceRevision.source.name
                    )
                } ?? []

                continuation.resume(returning: readings)
            }

            healthStore.execute(query)
        }
    }

    /// Calculates glucose statistics for a specific period around a placement
    /// - Parameters:
    ///   - placementDate: The date of the pump placement
    ///   - hoursBeforeAfter: Number of hours to analyze before and after placement
    /// - Returns: Glucose correlation data for the placement
    func calculateGlucoseCorrelation(
        for placementDate: Date,
        hoursBeforeAfter: Int = 24
    ) async -> GlucoseCorrelation {
        let calendar = Calendar.current

        // Define time windows
        let beforeStart = calendar.date(byAdding: .hour, value: -hoursBeforeAfter, to: placementDate)!
        let afterEnd = calendar.date(byAdding: .hour, value: hoursBeforeAfter, to: placementDate)!

        // Fetch readings for both periods
        let beforeReadings = await fetchGlucoseReadings(from: beforeStart, to: placementDate)
        let afterReadings = await fetchGlucoseReadings(from: placementDate, to: afterEnd)

        // Calculate averages
        let avgBefore = beforeReadings.isEmpty ? nil : beforeReadings.map(\.value).reduce(0, +) / Double(beforeReadings.count)
        let avgAfter = afterReadings.isEmpty ? nil : afterReadings.map(\.value).reduce(0, +) / Double(afterReadings.count)

        // Calculate time in range (70-180 mg/dL is typical target range)
        let tirBefore = calculateTimeInRange(readings: beforeReadings)
        let tirAfter = calculateTimeInRange(readings: afterReadings)

        // Calculate variability (coefficient of variation)
        let cvBefore = calculateCoefficientOfVariation(readings: beforeReadings)
        let cvAfter = calculateCoefficientOfVariation(readings: afterReadings)

        return GlucoseCorrelation(
            placementDate: placementDate,
            averageBefore: avgBefore,
            averageAfter: avgAfter,
            readingsCountBefore: beforeReadings.count,
            readingsCountAfter: afterReadings.count,
            timeInRangeBefore: tirBefore,
            timeInRangeAfter: tirAfter,
            variabilityBefore: cvBefore,
            variabilityAfter: cvAfter,
            calculatedAt: Date.now
        )
    }

    /// Calculates time in range (70-180 mg/dL) as a percentage
    private func calculateTimeInRange(readings: [GlucoseReading]) -> Double? {
        guard !readings.isEmpty else { return nil }

        let inRangeCount = readings.filter { $0.value >= 70 && $0.value <= 180 }.count
        return Double(inRangeCount) / Double(readings.count) * 100
    }

    /// Calculates coefficient of variation for glucose readings
    private func calculateCoefficientOfVariation(readings: [GlucoseReading]) -> Double? {
        guard readings.count >= 2 else { return nil }

        let values = readings.map(\.value)
        let mean = values.reduce(0, +) / Double(values.count)
        guard mean > 0 else { return nil }

        let squaredDiffs = values.map { pow($0 - mean, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(values.count)
        let stdDev = sqrt(variance)

        return (stdDev / mean) * 100
    }

    // MARK: - Batch Correlation Update

    /// Updates glucose correlations for multiple placements
    /// - Parameters:
    ///   - placements: The placements to update
    ///   - context: The SwiftData model context
    func updateCorrelations(for placements: [PlacementLog], context: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        for placement in placements {
            let correlation = await calculateGlucoseCorrelation(for: placement.placedAt)

            placement.avgGlucoseBefore = correlation.averageBefore
            placement.avgGlucoseAfter = correlation.averageAfter
            placement.glucoseReadingsCountBefore = correlation.readingsCountBefore
            placement.glucoseReadingsCountAfter = correlation.readingsCountAfter
            placement.glucoseCorrelationCalculatedAt = correlation.calculatedAt
        }

        try? context.save()
    }

    // MARK: - Site Performance Analysis

    /// Analyzes glucose performance by body location
    /// - Parameter placements: Placements with glucose correlations
    /// - Returns: Performance metrics grouped by location
    func analyzePerformanceByLocation(placements: [PlacementLog]) -> [LocationGlucosePerformance] {
        // Group placements by location
        var locationData: [String: [PlacementLog]] = [:]

        for placement in placements where placement.avgGlucoseAfter != nil {
            let locationKey = placement.locationRawValue ?? placement.customSiteName ?? "Unknown"
            locationData[locationKey, default: []].append(placement)
        }

        // Calculate performance metrics for each location
        return locationData.compactMap { locationKey, locationPlacements in
            let avgGlucoseValues = locationPlacements.compactMap(\.avgGlucoseAfter)
            guard !avgGlucoseValues.isEmpty else { return nil }

            let overallAverage = avgGlucoseValues.reduce(0, +) / Double(avgGlucoseValues.count)

            // Calculate improvement (lower glucose after vs before)
            let improvements = locationPlacements.compactMap { placement -> Double? in
                guard let before = placement.avgGlucoseBefore,
                      let after = placement.avgGlucoseAfter else { return nil }
                return before - after  // Positive means improvement (glucose went down)
            }

            let avgImprovement = improvements.isEmpty ? nil :
                improvements.reduce(0, +) / Double(improvements.count)

            return LocationGlucosePerformance(
                locationName: locationKey,
                isCustomSite: BodyLocation(rawValue: locationKey) == nil,
                placementCount: locationPlacements.count,
                averageGlucose: overallAverage,
                averageImprovement: avgImprovement
            )
        }.sorted { ($0.averageImprovement ?? 0) > ($1.averageImprovement ?? 0) }
    }
}

// MARK: - Supporting Types

/// A single blood glucose reading from HealthKit
struct GlucoseReading: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double  // mg/dL
    let source: String

    /// Returns the glucose value category
    var category: GlucoseCategory {
        switch value {
        case ..<70: return .low
        case 70..<180: return .inRange
        default: return .high
        }
    }
}

/// Category for glucose values
enum GlucoseCategory {
    case low, inRange, high

    var color: String {
        switch self {
        case .low: return "appWarning"
        case .inRange: return "appSuccess"
        case .high: return "appAccent"
        }
    }
}

/// Glucose correlation data for a single placement
struct GlucoseCorrelation {
    let placementDate: Date
    let averageBefore: Double?
    let averageAfter: Double?
    let readingsCountBefore: Int
    let readingsCountAfter: Int
    let timeInRangeBefore: Double?
    let timeInRangeAfter: Double?
    let variabilityBefore: Double?
    let variabilityAfter: Double?
    let calculatedAt: Date
}

/// Performance metrics for a specific body location
struct LocationGlucosePerformance: Identifiable {
    var id: String { locationName }
    let locationName: String
    let isCustomSite: Bool
    let placementCount: Int
    let averageGlucose: Double
    let averageImprovement: Double?

    var performanceRating: PerformanceRating {
        guard let improvement = averageImprovement else { return .neutral }
        switch improvement {
        case 10...: return .excellent
        case 5..<10: return .good
        case -5..<5: return .neutral
        case -10..<(-5): return .poor
        default: return .veryPoor
        }
    }
}

/// Rating for site performance based on glucose improvement
enum PerformanceRating: String {
    case excellent = "Excellent"
    case good = "Good"
    case neutral = "Neutral"
    case poor = "Poor"
    case veryPoor = "Very Poor"

    var iconName: String {
        switch self {
        case .excellent: return "star.fill"
        case .good: return "hand.thumbsup.fill"
        case .neutral: return "minus.circle.fill"
        case .poor: return "hand.thumbsdown.fill"
        case .veryPoor: return "exclamationmark.triangle.fill"
        }
    }
}
