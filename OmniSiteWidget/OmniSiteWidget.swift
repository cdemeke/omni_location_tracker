//
//  OmniSiteWidget.swift
//  OmniSiteWidget
//
//  Home screen widgets for OmniSite Tracker.
//  Shows recommended sites and recent placements at a glance.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry

/// Timeline entry for the widget
struct OmniSiteEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let recommendedSite: String?
    let daysSinceLastUse: Int?
    let lastPlacementSite: String?
    let lastPlacementDate: Date?
    let currentStreak: Int
    let siteStatuses: [SiteStatus]
}

/// Status of a single body site
struct SiteStatus: Identifiable {
    let id = UUID()
    let name: String
    let daysSinceUse: Int?
    let isReady: Bool
}

// MARK: - Timeline Provider

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> OmniSiteEntry {
        OmniSiteEntry(
            date: .now,
            configuration: ConfigurationAppIntent(),
            recommendedSite: "Abdomen Right",
            daysSinceLastUse: 20,
            lastPlacementSite: "Left Thigh",
            lastPlacementDate: Calendar.current.date(byAdding: .day, value: -3, to: .now),
            currentStreak: 7,
            siteStatuses: []
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> OmniSiteEntry {
        await getEntry(for: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<OmniSiteEntry> {
        let entry = await getEntry(for: configuration)

        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now

        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func getEntry(for configuration: ConfigurationAppIntent) async -> OmniSiteEntry {
        let dataManager = SharedDataManager.shared

        let recommendation = dataManager.getRecommendation()
        let lastPlacement = dataManager.getLastPlacement()
        let streak = dataManager.getCurrentStreak()
        let statuses = dataManager.getSiteStatuses()

        return OmniSiteEntry(
            date: .now,
            configuration: configuration,
            recommendedSite: recommendation?.siteName,
            daysSinceLastUse: recommendation?.daysSinceUse,
            lastPlacementSite: lastPlacement?.siteName,
            lastPlacementDate: lastPlacement?.date,
            currentStreak: streak,
            siteStatuses: statuses
        )
    }
}

// MARK: - Configuration Intent

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "OmniSite Widget"
    static var description = IntentDescription("Shows pump site recommendations")
}

// MARK: - Widget Views

/// Small widget showing just the recommendation
struct SmallWidgetView: View {
    let entry: OmniSiteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Recommended")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Site name
            if let site = entry.recommendedSite {
                Text(site)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(2)
            } else {
                Text("No data")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            // Days since use
            if let days = entry.daysSinceLastUse {
                Text("\(days) days rest")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Text("Never used")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

/// Medium widget showing recommendation and streak
struct MediumWidgetView: View {
    let entry: OmniSiteEntry

    var body: some View {
        HStack(spacing: 16) {
            // Recommendation section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("Next Site")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let site = entry.recommendedSite {
                    Text(site)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(2)

                    if let days = entry.daysSinceLastUse {
                        Text("\(days)d rest")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                } else {
                    Text("Log first placement")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Divider()

            // Streak section
            VStack(alignment: .center, spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)

                Text("\(entry.currentStreak)")
                    .font(.title)
                    .fontWeight(.bold)

                Text("day streak")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .frame(width: 80)

            // Last placement section
            VStack(alignment: .trailing, spacing: 8) {
                HStack {
                    Text("Last")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                }

                if let site = entry.lastPlacementSite {
                    Text(site)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)

                    if let date = entry.lastPlacementDate {
                        Text(date, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("No placements")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

/// Large widget showing all site statuses
struct LargeWidgetView: View {
    let entry: OmniSiteEntry

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(.blue)
                Text("Site Status")
                    .font(.headline)

                Spacer()

                // Streak badge
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(entry.currentStreak)")
                        .fontWeight(.bold)
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.orange.opacity(0.2))
                .clipShape(Capsule())
            }

            // Recommendation highlight
            if let site = entry.recommendedSite {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("Recommended: \(site)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.yellow.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Site grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(entry.siteStatuses) { status in
                    SiteStatusCell(status: status)
                }
            }

            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

/// Cell for a single site status
struct SiteStatusCell: View {
    let status: SiteStatus

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(status.isReady ? Color.green.opacity(0.3) : Color.orange.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: status.isReady ? "checkmark" : "clock")
                        .font(.caption)
                        .foregroundStyle(status.isReady ? .green : .orange)
                }

            Text(status.name)
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if let days = status.daysSinceUse {
                Text("\(days)d")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

// MARK: - Widget Definition

struct OmniSiteWidget: Widget {
    let kind: String = "OmniSiteWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Pump Site Tracker")
        .description("See your recommended pump site and recent placements.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

/// Main entry view that switches based on widget size
struct WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: OmniSiteEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    OmniSiteWidget()
} timeline: {
    OmniSiteEntry(
        date: .now,
        configuration: ConfigurationAppIntent(),
        recommendedSite: "Abdomen Right",
        daysSinceLastUse: 20,
        lastPlacementSite: "Left Thigh",
        lastPlacementDate: Calendar.current.date(byAdding: .day, value: -3, to: .now),
        currentStreak: 7,
        siteStatuses: []
    )
}

#Preview(as: .systemMedium) {
    OmniSiteWidget()
} timeline: {
    OmniSiteEntry(
        date: .now,
        configuration: ConfigurationAppIntent(),
        recommendedSite: "Abdomen Right",
        daysSinceLastUse: 20,
        lastPlacementSite: "Left Thigh",
        lastPlacementDate: Calendar.current.date(byAdding: .day, value: -3, to: .now),
        currentStreak: 7,
        siteStatuses: []
    )
}
