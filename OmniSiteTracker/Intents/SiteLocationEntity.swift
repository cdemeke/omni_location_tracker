//
//  SiteLocationEntity.swift
//  OmniSiteTracker
//
//  App Entity representing a body site location for use with App Intents.
//  Enables Siri to understand and suggest pump placement sites.
//

import AppIntents
import SwiftData

/// Entity representing a body site location for Siri
struct SiteLocationEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Site Location"

    static var defaultQuery = SiteLocationQuery()

    var id: String
    var name: String
    var iconName: String
    var isCustomSite: Bool

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: isCustomSite ? "Custom Site" : "Default Site",
            image: .init(systemName: iconName)
        )
    }

    init(id: String, name: String, iconName: String, isCustomSite: Bool = false) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.isCustomSite = isCustomSite
    }

    /// Create from a BodyLocation enum
    init(from location: BodyLocation) {
        self.id = location.rawValue
        self.name = location.displayName
        self.iconName = location.iconName
        self.isCustomSite = false
    }

    /// Create from a CustomSite model
    init(from customSite: CustomSite) {
        self.id = customSite.id.uuidString
        self.name = customSite.name
        self.iconName = customSite.iconName
        self.isCustomSite = true
    }
}

/// Query for fetching available site locations
struct SiteLocationQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [SiteLocationEntity] {
        var results: [SiteLocationEntity] = []

        // Check default locations
        for id in identifiers {
            if let location = BodyLocation(rawValue: id) {
                results.append(SiteLocationEntity(from: location))
            }
        }

        // Check custom sites if we have a container
        if let container = try? ModelContainer(for: CustomSite.self, DisabledDefaultSite.self) {
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<CustomSite>()

            if let customSites = try? context.fetch(descriptor) {
                for site in customSites {
                    if identifiers.contains(site.id.uuidString) {
                        results.append(SiteLocationEntity(from: site))
                    }
                }
            }
        }

        return results
    }

    func suggestedEntities() async throws -> [SiteLocationEntity] {
        var results: [SiteLocationEntity] = []

        // Get enabled default locations
        if let container = try? ModelContainer(for: DisabledDefaultSite.self, CustomSite.self) {
            let context = ModelContext(container)
            let disabledDescriptor = FetchDescriptor<DisabledDefaultSite>()
            let disabledSites = (try? context.fetch(disabledDescriptor)) ?? []
            let disabledRawValues = Set(disabledSites.compactMap { $0.locationRawValue })

            // Add enabled default locations
            for location in BodyLocation.allCases {
                if !disabledRawValues.contains(location.rawValue) {
                    results.append(SiteLocationEntity(from: location))
                }
            }

            // Add enabled custom sites
            let customDescriptor = FetchDescriptor<CustomSite>(
                predicate: #Predicate { $0.isEnabled }
            )
            if let customSites = try? context.fetch(customDescriptor) {
                for site in customSites {
                    results.append(SiteLocationEntity(from: site))
                }
            }
        } else {
            // Fallback to all default locations
            results = BodyLocation.allCases.map { SiteLocationEntity(from: $0) }
        }

        return results
    }

    func defaultResult() async -> SiteLocationEntity? {
        // Return the recommended site as default
        if let container = try? ModelContainer(for: PlacementLog.self, DisabledDefaultSite.self, CustomSite.self) {
            let context = ModelContext(container)

            // Get disabled sites
            let disabledDescriptor = FetchDescriptor<DisabledDefaultSite>()
            let disabledSites = (try? context.fetch(disabledDescriptor)) ?? []
            let disabledRawValues = Set(disabledSites.compactMap { $0.locationRawValue })

            // Get placements
            let placementDescriptor = FetchDescriptor<PlacementLog>(
                sortBy: [SortDescriptor(\.placedAt, order: .reverse)]
            )
            let placements = (try? context.fetch(placementDescriptor)) ?? []

            // Find location with oldest last use
            var locationLastUsed: [String: Date] = [:]
            for placement in placements {
                if let rawValue = placement.locationRawValue {
                    if locationLastUsed[rawValue] == nil {
                        locationLastUsed[rawValue] = placement.placedAt
                    }
                }
            }

            // Find best recommendation among enabled sites
            var bestLocation: BodyLocation?
            var oldestUse: Date = .distantFuture

            for location in BodyLocation.allCases {
                guard !disabledRawValues.contains(location.rawValue) else { continue }

                if let lastUsed = locationLastUsed[location.rawValue] {
                    if lastUsed < oldestUse {
                        oldestUse = lastUsed
                        bestLocation = location
                    }
                } else {
                    // Never used - best choice
                    bestLocation = location
                    break
                }
            }

            if let location = bestLocation {
                return SiteLocationEntity(from: location)
            }
        }

        return SiteLocationEntity(from: BodyLocation.abdomenLeft)
    }
}
