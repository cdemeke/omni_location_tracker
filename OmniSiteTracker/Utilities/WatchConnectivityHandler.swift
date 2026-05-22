//
//  WatchConnectivityHandler.swift
//  OmniSiteTracker
//
//  Handles communication between iPhone and Apple Watch.
//  Sends updates and receives placement logs from watch.
//

import Foundation
import WatchConnectivity
import SwiftData

/// Handles Watch Connectivity on the iOS side
@MainActor
@Observable
final class WatchConnectivityHandler: NSObject {
    // MARK: - Singleton

    static let shared = WatchConnectivityHandler()

    // MARK: - Properties

    private(set) var isWatchAppInstalled: Bool = false
    private(set) var isReachable: Bool = false
    private(set) var isPaired: Bool = false

    private var session: WCSession?
    private var modelContext: ModelContext?

    // MARK: - Initialization

    private override init() {
        super.init()
        setupWatchConnectivity()
    }

    // MARK: - Setup

    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else { return }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    /// Sets the model context for data operations
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Public Methods

    /// Sends updated data to the Apple Watch
    func sendUpdateToWatch(recommendedSite: String, daysSinceRecommended: Int?, recentPlacements: [PlacementLog]) {
        guard let session = session,
              session.activationState == .activated,
              session.isWatchAppInstalled else {
            return
        }

        var context: [String: Any] = [
            "recommendedSite": recommendedSite,
            "recentPlacements": recentPlacements.prefix(5).map { placement in
                [
                    "site": placement.locationRawValue ?? placement.customSiteName ?? "Unknown",
                    "date": placement.placedAt
                ]
            }
        ]

        if let days = daysSinceRecommended {
            context["daysSinceRecommended"] = days
        }

        do {
            try session.updateApplicationContext(context)
        } catch {
            print("Failed to send context to watch: \(error)")
        }
    }

    /// Sends a message directly to the watch (if reachable)
    func sendMessage(_ message: [String: Any], completion: ((Bool) -> Void)? = nil) {
        guard let session = session, session.isReachable else {
            completion?(false)
            return
        }

        session.sendMessage(message, replyHandler: { _ in
            completion?(true)
        }) { error in
            print("Failed to send message: \(error)")
            completion?(false)
        }
    }

    // MARK: - Private Methods

    private func handlePlacementRequest(site: String, date: Date) -> Bool {
        guard let modelContext = modelContext else { return false }

        // Find matching BodyLocation
        guard let location = BodyLocation(rawValue: site) else {
            // Try to find a custom site
            let descriptor = FetchDescriptor<CustomSite>(
                predicate: #Predicate { $0.name == site }
            )

            do {
                let customSites = try modelContext.fetch(descriptor)
                if let customSite = customSites.first {
                    let placement = PlacementLog(customSite: customSite, placedAt: date)
                    modelContext.insert(placement)
                    try modelContext.save()
                    return true
                }
            } catch {
                print("Failed to find custom site: \(error)")
            }
            return false
        }

        // Create placement for standard location
        let placement = PlacementLog(location: location, placedAt: date)
        modelContext.insert(placement)

        do {
            try modelContext.save()
            return true
        } catch {
            print("Failed to save placement: \(error)")
            return false
        }
    }

    private func getRecommendationData() -> [String: Any] {
        guard let modelContext = modelContext else {
            return ["recommendedSite": "Abdomen Left"]
        }

        // Get recommendation logic (simplified)
        let descriptor = FetchDescriptor<PlacementLog>(
            sortBy: [SortDescriptor(\.placedAt, order: .reverse)]
        )

        do {
            let placements = try modelContext.fetch(descriptor)

            // Simple rotation: find least recently used site
            var siteLastUsed: [String: Date] = [:]
            for placement in placements {
                let site = placement.locationRawValue ?? placement.customSiteName ?? "Unknown"
                if siteLastUsed[site] == nil {
                    siteLastUsed[site] = placement.placedAt
                }
            }

            let allSites = BodyLocation.allCases.map { $0.rawValue }
            var recommendedSite = "Abdomen Left"
            var daysSinceRecommended: Int?

            // Find site not used or used longest ago
            for site in allSites {
                if siteLastUsed[site] == nil {
                    recommendedSite = site
                    daysSinceRecommended = nil
                    break
                }
            }

            if let lastUsed = siteLastUsed[recommendedSite] {
                daysSinceRecommended = Calendar.current.dateComponents(
                    [.day],
                    from: lastUsed,
                    to: .now
                ).day
            }

            var result: [String: Any] = [
                "recommendedSite": recommendedSite,
                "recentPlacements": placements.prefix(5).map { placement in
                    [
                        "site": placement.locationRawValue ?? placement.customSiteName ?? "Unknown",
                        "date": placement.placedAt
                    ]
                }
            ]

            if let days = daysSinceRecommended {
                result["daysSinceRecommended"] = days
            }

            return result
        } catch {
            return ["recommendedSite": "Abdomen Left"]
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityHandler: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isReachable = session.isReachable

            if activationState == .activated {
                // Send initial data to watch
                let data = self.getRecommendationData()
                self.sendMessage(data)
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate session
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            guard let action = message["action"] as? String else {
                replyHandler(["success": false])
                return
            }

            switch action {
            case "logPlacement":
                guard let site = message["site"] as? String,
                      let date = message["date"] as? Date else {
                    replyHandler(["success": false])
                    return
                }

                let success = self.handlePlacementRequest(site: site, date: date)
                var response = self.getRecommendationData()
                response["success"] = success
                replyHandler(response)

            case "requestUpdate":
                let data = self.getRecommendationData()
                replyHandler(data)

            default:
                replyHandler(["success": false])
            }
        }
    }
}

// MARK: - Watch Complication Data

struct WatchComplicationData {
    let siteName: String
    let daysSinceUse: Int?
    let status: SiteStatus

    enum SiteStatus {
        case ready
        case resting
        case neverUsed
    }
}
