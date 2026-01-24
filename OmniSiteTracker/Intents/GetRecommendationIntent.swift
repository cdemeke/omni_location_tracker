//
//  GetRecommendationIntent.swift
//  OmniSiteTracker
//
//  App Intent for getting the recommended pump site via Siri.
//  Analyzes placement history to suggest the best site for the next placement.
//

import AppIntents
import SwiftData

/// App Intent for getting a site recommendation via Siri
struct GetRecommendationIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Site Recommendation"
    static var description = IntentDescription("Get a recommendation for your next insulin pump site")

    static var parameterSummary: some ParameterSummary {
        Summary("Get recommended pump site")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let container = try? ModelContainer(for: PlacementLog.self, DisabledDefaultSite.self, CustomSite.self, UserSettings.self) else {
            return .result(dialog: "Sorry, I couldn't access the app data.")
        }

        let context = ModelContext(container)

        // Get user settings for rest days
        let settings = UserSettings.getOrCreate(context: context)
        let restDays = settings.minimumRestDays

        // Get disabled sites
        let disabledDescriptor = FetchDescriptor<DisabledDefaultSite>()
        let disabledSites = (try? context.fetch(disabledDescriptor)) ?? []
        let disabledRawValues = Set(disabledSites.compactMap { $0.locationRawValue })

        // Get all placements sorted by date
        let placementDescriptor = FetchDescriptor<PlacementLog>(
            sortBy: [SortDescriptor(\.placedAt, order: .reverse)]
        )
        let placements = (try? context.fetch(placementDescriptor)) ?? []

        // Calculate days since each location was used
        var locationInfo: [String: (lastUsed: Date, daysSince: Int)] = [:]
        let calendar = Calendar.current

        for placement in placements {
            if let rawValue = placement.locationRawValue {
                if locationInfo[rawValue] == nil {
                    let daysSince = calendar.dateComponents([.day], from: placement.placedAt, to: .now).day ?? 0
                    locationInfo[rawValue] = (lastUsed: placement.placedAt, daysSince: daysSince)
                }
            }
        }

        // Find the best recommendation
        var bestLocation: BodyLocation?
        var bestDaysSince = -1
        var neverUsedLocations: [BodyLocation] = []

        for location in BodyLocation.allCases {
            guard !disabledRawValues.contains(location.rawValue) else { continue }

            if let info = locationInfo[location.rawValue] {
                if info.daysSince > bestDaysSince {
                    bestDaysSince = info.daysSince
                    bestLocation = location
                }
            } else {
                // Never used - add to list
                neverUsedLocations.append(location)
            }
        }

        // Prefer never-used locations
        if let neverUsed = neverUsedLocations.first {
            return .result(dialog: "I recommend \(neverUsed.displayName). This site has never been used!") {
                RecommendationSnippet(
                    location: neverUsed.displayName,
                    daysSinceLastUse: nil,
                    isReady: true,
                    restDays: restDays
                )
            }
        }

        // Otherwise use the location with most rest
        if let location = bestLocation {
            let isReady = bestDaysSince >= restDays
            let statusMessage = isReady
                ? "It's been \(bestDaysSince) days since last use and it's ready."
                : "It's been \(bestDaysSince) days. Recommended rest is \(restDays) days."

            return .result(dialog: "I recommend \(location.displayName). \(statusMessage)") {
                RecommendationSnippet(
                    location: location.displayName,
                    daysSinceLastUse: bestDaysSince,
                    isReady: isReady,
                    restDays: restDays
                )
            }
        }

        return .result(dialog: "No sites available. Please check your settings.")
    }
}

/// Snippet view showing the recommendation
struct RecommendationSnippet: View {
    let location: String
    let daysSinceLastUse: Int?
    let isReady: Bool
    let restDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Recommended Site")
                    .font(.headline)
            }

            Text(location)
                .font(.title)
                .fontWeight(.bold)

            if let days = daysSinceLastUse {
                HStack(spacing: 4) {
                    Image(systemName: isReady ? "checkmark.circle.fill" : "clock.fill")
                        .foregroundStyle(isReady ? .green : .orange)
                    Text("\(days) days since last use")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow)
                    Text("Never used before!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

import SwiftUI
