//
//  ComplicationViews.swift
//  OmniSiteWatch
//
//  Watch face complications for OmniSite Tracker.
//  Shows current recommendation and site status.
//

import SwiftUI
import WidgetKit

// MARK: - Complication Entry

struct SiteComplicationEntry: TimelineEntry {
    let date: Date
    let recommendedSite: String
    let daysSinceUse: Int?
    let isReady: Bool
}

// MARK: - Complication Provider

struct SiteComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> SiteComplicationEntry {
        SiteComplicationEntry(
            date: .now,
            recommendedSite: "Abdomen Left",
            daysSinceUse: 20,
            isReady: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SiteComplicationEntry) -> Void) {
        let entry = SiteComplicationEntry(
            date: .now,
            recommendedSite: "Abdomen Left",
            daysSinceUse: 20,
            isReady: true
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SiteComplicationEntry>) -> Void) {
        // Get data from shared storage or Watch Connectivity
        let entry = SiteComplicationEntry(
            date: .now,
            recommendedSite: UserDefaults.standard.string(forKey: "watch_recommendedSite") ?? "Abdomen Left",
            daysSinceUse: UserDefaults.standard.integer(forKey: "watch_daysSinceUse"),
            isReady: UserDefaults.standard.bool(forKey: "watch_isReady")
        )

        // Update hourly
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Circular Complication View

struct CircularComplicationView: View {
    let entry: SiteComplicationEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 2) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(entry.isReady ? .green : .orange)

                if let days = entry.daysSinceUse {
                    Text("\(days)d")
                        .font(.system(size: 10, weight: .semibold))
                }
            }
        }
    }
}

// MARK: - Corner Complication View

struct CornerComplicationView: View {
    let entry: SiteComplicationEntry

    var body: some View {
        VStack(alignment: .leading) {
            Text(shortSiteName(entry.recommendedSite))
                .font(.system(size: 14, weight: .semibold))

            if let days = entry.daysSinceUse {
                Text("\(days) days")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .widgetLabel {
            Text(entry.isReady ? "Ready" : "Resting")
        }
    }

    private func shortSiteName(_ name: String) -> String {
        // Abbreviate site names for small display
        let abbreviations: [String: String] = [
            "Abdomen Left": "Abd L",
            "Abdomen Right": "Abd R",
            "Left Thigh": "L Thigh",
            "Right Thigh": "R Thigh",
            "Left Arm": "L Arm",
            "Right Arm": "R Arm",
            "Left Hip": "L Hip",
            "Right Hip": "R Hip"
        ]
        return abbreviations[name] ?? name
    }
}

// MARK: - Rectangular Complication View

struct RectangularComplicationView: View {
    let entry: SiteComplicationEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Next Site")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(entry.recommendedSite)
                    .font(.headline)
                    .lineLimit(1)

                if let days = entry.daysSinceUse {
                    Text("\(days) days since last use")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: entry.isReady ? "checkmark.circle.fill" : "clock.fill")
                .font(.title2)
                .foregroundColor(entry.isReady ? .green : .orange)
        }
    }
}

// MARK: - Inline Complication View

struct InlineComplicationView: View {
    let entry: SiteComplicationEntry

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "mappin.circle.fill")
            Text(entry.recommendedSite)
        }
    }
}

// MARK: - Widget Configuration

struct OmniSiteComplication: Widget {
    let kind: String = "OmniSiteComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SiteComplicationProvider()) { entry in
            ComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Site Tracker")
        .description("Shows your recommended pump site.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Complication Entry View

struct ComplicationEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: SiteComplicationEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularComplicationView(entry: entry)
        case .accessoryCorner:
            CornerComplicationView(entry: entry)
        case .accessoryRectangular:
            RectangularComplicationView(entry: entry)
        case .accessoryInline:
            InlineComplicationView(entry: entry)
        default:
            CircularComplicationView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .accessoryCircular) {
    OmniSiteComplication()
} timeline: {
    SiteComplicationEntry(date: .now, recommendedSite: "Abdomen Left", daysSinceUse: 20, isReady: true)
    SiteComplicationEntry(date: .now, recommendedSite: "Right Thigh", daysSinceUse: 5, isReady: false)
}
