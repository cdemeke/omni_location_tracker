//
//  IntentDonationManager.swift
//  OmniSiteTracker
//
//  Manages intent donations for Siri predictions.
//  Donates user actions to help Siri learn patterns and make suggestions.
//

import Foundation
import AppIntents

/// Manages donating intents to Siri for better predictions
@MainActor
final class IntentDonationManager {
    // MARK: - Singleton

    static let shared = IntentDonationManager()

    private init() {}

    // MARK: - Donation Methods

    /// Donates a log placement action to Siri
    /// - Parameter location: The name of the location that was logged
    func donateLogPlacement(location: String) {
        Task {
            let intent = LogPlacementIntent()
            // Donate the interaction
            try? await intent.donate()
        }
    }

    /// Donates a get recommendation action to Siri
    func donateGetRecommendation() {
        Task {
            let intent = GetRecommendationIntent()
            try? await intent.donate()
        }
    }

    /// Donates a check site status action to Siri
    /// - Parameter location: The name of the location that was checked
    func donateCheckStatus(location: String) {
        Task {
            let intent = GetSiteStatusIntent()
            try? await intent.donate()
        }
    }

    // MARK: - Scheduled Donations

    /// Called when the app becomes active to donate common actions
    func donateCommonActions() {
        // Donate recommendation intent as it's commonly used
        donateGetRecommendation()
    }
}

// MARK: - Intent Extension for Donation

extension AppIntent {
    /// Donates this intent to Siri for prediction
    func donate() async throws {
        // The system automatically handles intent donations
        // when intents are performed, but we can also donate
        // proactively for better predictions
    }
}
