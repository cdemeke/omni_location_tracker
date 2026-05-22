//
//  DailyDigestView.swift
//  OmniSiteTracker
//
//  Daily summary notifications and view
//

import SwiftUI
import SwiftData

struct DailyDigest {
    let date: Date
    let placements: Int
    let nextSuggestion: String?
    let streakDays: Int
    let upcomingReminders: Int
    let healthScore: Int
}

@MainActor
@Observable
final class DailyDigestManager {
    var digest: DailyDigest?
    var isLoading = false
    var digestTime = Date()
    var isEnabled = true
    
    func generate(from placements: [PlacementLog]) async {
        isLoading = true
        try? await Task.sleep(for: .milliseconds(500))
        
        let today = Calendar.current.startOfDay(for: Date())
        let todayPlacements = placements.filter { Calendar.current.isDate($0.placedAt, inSameDayAs: today) }
        
        digest = DailyDigest(
            date: Date(),
            placements: todayPlacements.count,
            nextSuggestion: "Right Thigh",
            streakDays: 12,
            upcomingReminders: 2,
            healthScore: 85
        )
        
        isLoading = false
    }
}

struct DailyDigestView: View {
    @Query private var placements: [PlacementLog]
    @State private var manager = DailyDigestManager()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if manager.isLoading {
                    ProgressView()
                        .padding()
                } else if let digest = manager.digest {
                    // Header
                    VStack {
                        Text(digest.date.formatted(date: .complete, time: .omitted))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("Daily Digest")
                            .font(.largeTitle)
                            .bold()
                    }
                    .padding()
                    
                    // Stats Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        DigestCard(title: "Placements Today", value: "\(digest.placements)", icon: "mappin.circle.fill", color: .blue)
                        DigestCard(title: "Current Streak", value: "\(digest.streakDays) days", icon: "flame.fill", color: .orange)
                        DigestCard(title: "Health Score", value: "\(digest.healthScore)%", icon: "heart.fill", color: .red)
                        DigestCard(title: "Reminders", value: "\(digest.upcomingReminders)", icon: "bell.fill", color: .purple)
                    }
                    .padding(.horizontal)
                    
                    // Next Suggestion
                    if let suggestion = digest.nextSuggestion {
                        VStack(spacing: 8) {
                            Text("Suggested Next Site")
                                .font(.headline)
                            Text(suggestion)
                                .font(.title)
                                .bold()
                                .foregroundStyle(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Daily Digest")
        .onAppear {
            Task {
                await manager.generate(from: placements)
            }
        }
    }
}

struct DigestCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
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
        DailyDigestView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
