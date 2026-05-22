//
//  AchievementsView.swift
//  OmniSiteTracker
//
//  Displays user achievements and progress.
//  Gamifies pump site rotation with badges and rewards.
//

import SwiftUI
import SwiftData

/// Main achievements view showing earned and locked achievements
struct AchievementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlacementLog.placedAt, order: .reverse) private var placements: [PlacementLog]
    @Query(sort: \Achievement.earnedAt, order: .reverse) private var achievements: [Achievement]

    @State private var achievementManager = AchievementManager.shared
    @State private var selectedAchievement: AchievementType?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Stats header
                statsHeader

                // Current streak
                streakCard

                // Earned achievements
                if !earnedTypes.isEmpty {
                    earnedSection
                }

                // Locked achievements
                if !lockedTypes.isEmpty {
                    lockedSection
                }
            }
            .padding()
        }
        .background(Color.appBackground)
        .navigationTitle("Achievements")
        .sheet(item: $selectedAchievement) { type in
            AchievementDetailSheet(type: type, isEarned: earnedTypes.contains(type), placements: placements, context: modelContext)
                .presentationDetents([.medium])
        }
    }

    private var earnedTypes: Set<AchievementType> {
        Set(achievements.compactMap { $0.type })
    }

    private var lockedTypes: [AchievementType] {
        AchievementType.allCases.filter { !earnedTypes.contains($0) }
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "Points",
                value: "\(achievementManager.getTotalPoints(context: modelContext))",
                icon: "star.fill",
                color: .appSecondary
            )

            StatCard(
                title: "Earned",
                value: "\(achievements.count)/\(AchievementType.allCases.count)",
                icon: "trophy.fill",
                color: .appAccent
            )
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        let streak = calculateCurrentStreak()

        return VStack(spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundStyle(.linearGradient(
                        colors: [.orange, .red],
                        startPoint: .top,
                        endPoint: .bottom
                    ))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Streak")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)

                    Text("\(streak) day\(streak == 1 ? "" : "s")")
                        .font(.title2.bold())
                        .foregroundColor(.textPrimary)
                }

                Spacer()

                // Next streak milestone
                if let nextMilestone = nextStreakMilestone(current: streak) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Next at")
                            .font(.caption)
                            .foregroundColor(.textSecondary)

                        Text("\(nextMilestone) days")
                            .font(.subheadline.bold())
                            .foregroundColor(.appAccent)
                    }
                }
            }

            // Progress to next streak
            if let next = nextStreakMilestone(current: streak) {
                ProgressView(value: Double(streak), total: Double(next))
                    .tint(.orange)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private func calculateCurrentStreak() -> Int {
        guard !placements.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedPlacements = placements.sorted { $0.placedAt > $1.placedAt }

        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        guard let mostRecent = sortedPlacements.first else { return 0 }
        let mostRecentDay = calendar.startOfDay(for: mostRecent.placedAt)

        guard mostRecentDay >= yesterday else { return 0 }

        var streak = 0
        var checkDate = mostRecentDay
        var placementDates: Set<Date> = []

        for placement in sortedPlacements {
            placementDates.insert(calendar.startOfDay(for: placement.placedAt))
        }

        while placementDates.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        return streak
    }

    private func nextStreakMilestone(current: Int) -> Int? {
        let milestones = [7, 14, 30, 90]
        return milestones.first { $0 > current }
    }

    // MARK: - Earned Section

    private var earnedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Earned")
                .font(.headline)
                .foregroundColor(.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(AchievementType.allCases.filter { earnedTypes.contains($0) }) { type in
                    AchievementBadge(type: type, isEarned: true, progress: 1.0)
                        .onTapGesture {
                            selectedAchievement = type
                        }
                }
            }
        }
    }

    // MARK: - Locked Section

    private var lockedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Locked")
                .font(.headline)
                .foregroundColor(.textSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(lockedTypes) { type in
                    let progress = achievementManager.getProgress(for: type, placements: placements, context: modelContext)
                    AchievementBadge(type: type, isEarned: false, progress: progress)
                        .onTapGesture {
                            selectedAchievement = type
                        }
                }
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title.bold())
                .foregroundColor(.textPrimary)

            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Achievement Badge

struct AchievementBadge: View {
    let type: AchievementType
    let isEarned: Bool
    let progress: Double

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle with tier color
                Circle()
                    .fill(isEarned ? tierColor.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 64, height: 64)

                // Progress ring for locked achievements
                if !isEarned && progress > 0 {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(tierColor.opacity(0.5), lineWidth: 3)
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                }

                // Icon
                Image(systemName: type.iconName)
                    .font(.title2)
                    .foregroundStyle(isEarned ? tierGradient : grayGradient)
            }

            Text(type.title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(isEarned ? .textPrimary : .textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .opacity(isEarned ? 1 : 0.6)
    }

    private var tierColor: Color {
        switch type.tier {
        case .bronze: return .orange
        case .silver: return .gray
        case .gold: return .yellow
        case .platinum: return .cyan
        }
    }

    private var tierGradient: LinearGradient {
        switch type.tier {
        case .bronze:
            return LinearGradient(colors: [.orange, .brown], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .silver:
            return LinearGradient(colors: [.gray, .white], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gold:
            return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .platinum:
            return LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var grayGradient: LinearGradient {
        LinearGradient(colors: [.gray, .gray.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Achievement Detail Sheet

struct AchievementDetailSheet: View {
    let type: AchievementType
    let isEarned: Bool
    let placements: [PlacementLog]
    let context: ModelContext

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Badge
            ZStack {
                Circle()
                    .fill(isEarned ? tierColor.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: type.iconName)
                    .font(.system(size: 40))
                    .foregroundStyle(isEarned ? tierGradient : grayGradient)
            }

            // Title and description
            VStack(spacing: 8) {
                Text(type.title)
                    .font(.title2.bold())
                    .foregroundColor(.textPrimary)

                Text(type.description)
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Points
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.appSecondary)
                Text("\(type.points) points")
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.cardBackground)
            .clipShape(Capsule())

            // Progress for locked achievements
            if !isEarned {
                let progress = AchievementManager.shared.getProgress(for: type, placements: placements, context: context)
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .tint(tierColor)

                    Text("\(Int(progress * 100))% complete")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal)
            }

            Spacer()

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var tierColor: Color {
        switch type.tier {
        case .bronze: return .orange
        case .silver: return .gray
        case .gold: return .yellow
        case .platinum: return .cyan
        }
    }

    private var tierGradient: LinearGradient {
        switch type.tier {
        case .bronze:
            return LinearGradient(colors: [.orange, .brown], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .silver:
            return LinearGradient(colors: [.gray, .white], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gold:
            return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .platinum:
            return LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var grayGradient: LinearGradient {
        LinearGradient(colors: [.gray, .gray.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Achievement Celebration Modal

struct AchievementCelebrationModal: View {
    let achievements: [AchievementType]
    let onDismiss: () -> Void

    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Celebration icon
            Image(systemName: "party.popper.fill")
                .font(.system(size: 60))
                .foregroundStyle(.linearGradient(
                    colors: [.yellow, .orange, .pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .scaleEffect(showConfetti ? 1.0 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showConfetti)

            Text("Achievement Unlocked!")
                .font(.title.bold())
                .foregroundColor(.textPrimary)

            // Show earned achievements
            VStack(spacing: 16) {
                ForEach(achievements) { type in
                    HStack(spacing: 12) {
                        Image(systemName: type.iconName)
                            .font(.title2)
                            .foregroundColor(.appAccent)

                        VStack(alignment: .leading) {
                            Text(type.title)
                                .font(.headline)
                                .foregroundColor(.textPrimary)

                            Text("+\(type.points) points")
                                .font(.caption)
                                .foregroundColor(.appSecondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)

            Spacer()

            Button("Awesome!") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.appAccent)
        }
        .padding()
        .onAppear {
            showConfetti = true
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AchievementsView()
    }
    .modelContainer(for: [PlacementLog.self, Achievement.self], inMemory: true)
}
