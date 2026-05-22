//
//  StreakTrackingView.swift
//  OmniSiteTracker
//
//  Track consecutive logging streaks
//

import SwiftUI
import SwiftData

@MainActor
@Observable
final class StreakTracker {
    var currentStreak = 0
    var longestStreak = 0
    var totalDaysLogged = 0
    var lastLogDate: Date?
    
    func calculate(from placements: [PlacementLog]) {
        guard !placements.isEmpty else { return }
        
        let calendar = Calendar.current
        let sortedDates = Set(placements.map { calendar.startOfDay(for: $0.placedAt) }).sorted()
        
        totalDaysLogged = sortedDates.count
        lastLogDate = sortedDates.last
        
        var streak = 1
        var maxStreak = 1
        
        for i in 1..<sortedDates.count {
            let diff = calendar.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0
            if diff == 1 {
                streak += 1
                maxStreak = max(maxStreak, streak)
            } else {
                streak = 1
            }
        }
        
        longestStreak = maxStreak
        
        // Check if streak is current
        if let last = sortedDates.last {
            let daysSinceLast = calendar.dateComponents([.day], from: last, to: Date()).day ?? 0
            currentStreak = daysSinceLast <= 1 ? streak : 0
        }
    }
}

struct StreakTrackingView: View {
    @Query private var placements: [PlacementLog]
    @State private var tracker = StreakTracker()
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 24) {
                    // Current streak
                    VStack {
                        Text("\(tracker.currentStreak)")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundStyle(.orange)
                        Text("Day Streak")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Flame animation
                    if tracker.currentStreak > 0 {
                        HStack {
                            ForEach(0..<min(tracker.currentStreak, 7), id: \.self) { _ in
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(.orange.gradient)
                            }
                        }
                        .font(.title)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
            
            Section("Statistics") {
                LabeledContent("Longest Streak", value: "\(tracker.longestStreak) days")
                LabeledContent("Total Days Logged", value: "\(tracker.totalDaysLogged)")
                if let last = tracker.lastLogDate {
                    LabeledContent("Last Log", value: last.formatted(date: .abbreviated, time: .omitted))
                }
            }
            
            Section("Milestones") {
                MilestoneRow(days: 7, achieved: tracker.longestStreak >= 7, icon: "star")
                MilestoneRow(days: 30, achieved: tracker.longestStreak >= 30, icon: "star.fill")
                MilestoneRow(days: 100, achieved: tracker.longestStreak >= 100, icon: "crown")
                MilestoneRow(days: 365, achieved: tracker.longestStreak >= 365, icon: "crown.fill")
            }
        }
        .navigationTitle("Streaks")
        .onAppear {
            tracker.calculate(from: placements)
        }
    }
}

struct MilestoneRow: View {
    let days: Int
    let achieved: Bool
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(achieved ? .yellow : .secondary)
            Text("\(days) Day Streak")
            Spacer()
            if achieved {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        StreakTrackingView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
