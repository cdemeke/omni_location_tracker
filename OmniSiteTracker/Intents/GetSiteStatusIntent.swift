//
//  GetSiteStatusIntent.swift
//  OmniSiteTracker
//
//  App Intent for checking the status of a specific pump site via Siri.
//  Tells the user how long since a site was used and if it's ready.
//

import AppIntents
import SwiftData
import SwiftUI

/// App Intent for checking site status via Siri
struct GetSiteStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Site Status"
    static var description = IntentDescription("Check when a pump site was last used and if it's ready")

    /// The site location to check
    @Parameter(title: "Location")
    var location: SiteLocationEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Check status of \(\.$location)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Get or prompt for location
        let selectedLocation: SiteLocationEntity
        if let location = self.location {
            selectedLocation = location
        } else {
            selectedLocation = try await $location.requestValue("Which site do you want to check?")
        }

        guard let container = try? ModelContainer(for: PlacementLog.self, UserSettings.self) else {
            return .result(dialog: "Sorry, I couldn't access the app data.")
        }

        let context = ModelContext(container)

        // Get user settings
        let settings = UserSettings.getOrCreate(context: context)
        let restDays = settings.minimumRestDays

        // Find the most recent placement for this location
        let locationRawValue = selectedLocation.id
        let placementDescriptor = FetchDescriptor<PlacementLog>(
            predicate: #Predicate { $0.locationRawValue == locationRawValue },
            sortBy: [SortDescriptor(\.placedAt, order: .reverse)]
        )

        if let placement = try? context.fetch(placementDescriptor).first {
            let calendar = Calendar.current
            let daysSince = calendar.dateComponents([.day], from: placement.placedAt, to: .now).day ?? 0
            let isReady = daysSince >= restDays
            let daysRemaining = max(0, restDays - daysSince)

            let statusMessage: String
            if isReady {
                statusMessage = "\(selectedLocation.name) is ready! It's been \(daysSince) days since last use."
            } else {
                statusMessage = "\(selectedLocation.name) needs \(daysRemaining) more day\(daysRemaining == 1 ? "" : "s") of rest. Last used \(daysSince) days ago."
            }

            return .result(dialog: statusMessage) {
                SiteStatusSnippet(
                    location: selectedLocation.name,
                    daysSinceLastUse: daysSince,
                    isReady: isReady,
                    daysRemaining: daysRemaining,
                    restDays: restDays,
                    lastUsedDate: placement.placedAt
                )
            }
        } else {
            return .result(dialog: "\(selectedLocation.name) has never been used. It's ready for your next placement!") {
                SiteStatusSnippet(
                    location: selectedLocation.name,
                    daysSinceLastUse: nil,
                    isReady: true,
                    daysRemaining: 0,
                    restDays: restDays,
                    lastUsedDate: nil
                )
            }
        }
    }
}

/// Snippet view showing site status
struct SiteStatusSnippet: View {
    let location: String
    let daysSinceLastUse: Int?
    let isReady: Bool
    let daysRemaining: Int
    let restDays: Int
    let lastUsedDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: isReady ? "checkmark.circle.fill" : "clock.fill")
                    .foregroundStyle(isReady ? .green : .orange)
                Text(isReady ? "Ready" : "Resting")
                    .font(.headline)
                    .foregroundStyle(isReady ? .green : .orange)
            }

            // Location name
            Text(location)
                .font(.title)
                .fontWeight(.bold)

            // Status details
            if let days = daysSinceLastUse {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(days) days since last use")
                        .font(.subheadline)

                    if !isReady {
                        Text("\(daysRemaining) more day\(daysRemaining == 1 ? "" : "s") until ready")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)

                            Rectangle()
                                .fill(isReady ? Color.green : Color.orange)
                                .frame(width: min(CGFloat(days) / CGFloat(restDays) * geometry.size.width, geometry.size.width), height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow)
                    Text("Never used - ready for first placement!")
                        .font(.subheadline)
                }
            }

            // Last used date
            if let date = lastUsedDate {
                Text("Last used: \(date.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
