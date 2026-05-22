//
//  LogPlacementIntent.swift
//  OmniSiteTracker
//
//  App Intent for logging pump site placements via Siri.
//  Enables hands-free placement logging with voice commands.
//

import AppIntents
import SwiftData

/// App Intent for logging a new pump site placement via Siri
struct LogPlacementIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Pump Site"
    static var description = IntentDescription("Log a new insulin pump site placement")

    /// The body location for the placement
    @Parameter(title: "Location")
    var location: SiteLocationEntity?

    /// Optional note for the placement
    @Parameter(title: "Note", default: nil)
    var note: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Log placement at \(\.$location)") {
            \.$note
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Get or prompt for location
        let selectedLocation: SiteLocationEntity
        if let location = self.location {
            selectedLocation = location
        } else {
            selectedLocation = try await $location.requestValue("Where did you place the pump?")
        }

        // Access SwiftData container
        guard let container = try? ModelContainer(for: PlacementLog.self, CustomSite.self) else {
            return .result(dialog: "Sorry, I couldn't access the app data.")
        }

        let context = ModelContext(container)

        // Create the placement log
        if let bodyLocation = BodyLocation(rawValue: selectedLocation.id) {
            let placement = PlacementLog(location: bodyLocation, placedAt: .now, note: note)
            context.insert(placement)
        } else {
            // Try to find custom site
            let customSiteDescriptor = FetchDescriptor<CustomSite>(
                predicate: #Predicate { $0.name == selectedLocation.name }
            )
            if let customSite = try? context.fetch(customSiteDescriptor).first {
                let placement = PlacementLog(customSite: customSite, placedAt: .now, note: note)
                context.insert(placement)
            } else {
                return .result(dialog: "Sorry, I couldn't find that site location.")
            }
        }

        try? context.save()

        // Donate this interaction for future predictions
        IntentDonationManager.shared.donateLogPlacement(location: selectedLocation.name)

        let message = note != nil
            ? "Logged placement at \(selectedLocation.name) with note: \(note!)"
            : "Logged placement at \(selectedLocation.name)"

        return .result(dialog: "\(message)") {
            PlacementConfirmationSnippet(location: selectedLocation.name, note: note)
        }
    }
}

/// A simple snippet view shown after logging a placement
struct PlacementConfirmationSnippet: View {
    let location: String
    let note: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Placement Logged")
                    .font(.headline)
            }

            Text(location)
                .font(.title2)
                .fontWeight(.semibold)

            if let note = note, !note.isEmpty {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("Just now")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

import SwiftUI
