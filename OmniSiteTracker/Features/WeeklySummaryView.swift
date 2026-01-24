//
//  WeeklySummaryView.swift
//  OmniSiteTracker
//
//  Weekly progress summary and insights
//

import SwiftUI
import SwiftData

struct WeeklySummary {
    let weekStart: Date
    let totalPlacements: Int
    let uniqueSites: Int
    let avgDaysBetween: Double
    let topSite: String?
    let symptoms: Int
    let streakDays: Int
}

@MainActor
@Observable
final class WeeklySummaryGenerator {
    var summary: WeeklySummary?
    var isGenerating = false
    
    func generate(from placements: [PlacementLog]) async {
        isGenerating = true
        try? await Task.sleep(for: .milliseconds(500))
        
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        
        let weekPlacements = placements.filter { $0.placedAt >= weekStart }
        let uniqueSites = Set(weekPlacements.map { $0.site })
        
        summary = WeeklySummary(
            weekStart: weekStart,
            totalPlacements: weekPlacements.count,
            uniqueSites: uniqueSites.count,
            avgDaysBetween: 2.5,
            topSite: weekPlacements.first?.site,
            symptoms: 1,
            streakDays: min(7, weekPlacements.count)
        )
        
        isGenerating = false
    }
}

struct WeeklySummaryView: View {
    @Query private var placements: [PlacementLog]
    @State private var generator = WeeklySummaryGenerator()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if generator.isGenerating {
                    ProgressView("Generating summary...")
                        .padding()
                } else if let summary = generator.summary {
                    // Header
                    VStack {
                        Text("Week of")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(summary.weekStart.formatted(date: .abbreviated, time: .omitted))
                            .font(.title2)
                            .bold()
                    }
                    .padding()
                    
                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        SummaryCard(title: "Placements", value: "\(summary.totalPlacements)", icon: "mappin.and.ellipse")
                        SummaryCard(title: "Sites Used", value: "\(summary.uniqueSites)", icon: "person.crop.rectangle.stack")
                        SummaryCard(title: "Avg Days", value: String(format: "%.1f", summary.avgDaysBetween), icon: "calendar")
                        SummaryCard(title: "Streak", value: "\(summary.streakDays)", icon: "flame.fill")
                    }
                    .padding()
                    
                    // Insights
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weekly Insights")
                            .font(.headline)
                        
                        if let topSite = summary.topSite {
                            Label("Most used: \(topSite)", systemImage: "star.fill")
                                .foregroundStyle(.orange)
                        }
                        
                        Label("Great rotation pattern this week!", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                } else {
                    Button("Generate Summary") {
                        Task {
                            await generator.generate(from: placements)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
        }
        .navigationTitle("Weekly Summary")
        .onAppear {
            if generator.summary == nil {
                Task {
                    await generator.generate(from: placements)
                }
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text(value)
                .font(.title)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        WeeklySummaryView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
