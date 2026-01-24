//
//  GlucoseCorrelationView.swift
//  OmniSiteTracker
//
//  Displays glucose correlation data for pump site placements.
//  Shows how blood glucose levels compare before and after site changes.
//

import SwiftUI
import SwiftData

/// View showing glucose correlation insights for placements
struct GlucoseCorrelationView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlacementLog.placedAt, order: .reverse) private var placements: [PlacementLog]

    @State private var healthKitManager = HealthKitManager.shared
    @State private var locationPerformance: [LocationGlucosePerformance] = []
    @State private var isRefreshing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Authorization Section
                if !healthKitManager.isAuthorized {
                    authorizationCard
                } else {
                    // Performance Overview
                    performanceOverviewCard

                    // Location Performance List
                    if !locationPerformance.isEmpty {
                        locationPerformanceSection
                    }

                    // Recent Placements with Glucose Data
                    recentPlacementsSection
                }
            }
            .padding()
        }
        .background(Color.appBackground)
        .navigationTitle("Glucose Insights")
        .toolbar {
            if healthKitManager.isAuthorized {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await refreshData() }
                    } label: {
                        if isRefreshing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isRefreshing)
                }
            }
        }
        .task {
            if healthKitManager.isAuthorized {
                await refreshData()
            }
        }
    }

    // MARK: - Authorization Card

    private var authorizationCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 60))
                .foregroundStyle(.linearGradient(
                    colors: [.appAccent, .appSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("Connect HealthKit")
                .font(.title2.bold())
                .foregroundColor(.textPrimary)

            Text("Link your blood glucose data to see how different pump sites affect your glucose levels.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            if healthKitManager.isDenied {
                Text("HealthKit access was denied. Please enable it in Settings > Privacy > Health.")
                    .font(.caption)
                    .foregroundColor(.appWarning)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    _ = await healthKitManager.requestAuthorization()
                }
            } label: {
                Label("Enable HealthKit", systemImage: "heart.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(healthKitManager.isDenied)
        }
        .padding(24)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }

    // MARK: - Performance Overview

    private var performanceOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.appAccent)
                Text("Performance Overview")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
            }

            if let bestSite = locationPerformance.first {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Best Performing Site")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        Text(bestSite.locationName)
                            .font(.title3.bold())
                            .foregroundColor(.textPrimary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Avg. Improvement")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        if let improvement = bestSite.averageImprovement {
                            HStack(spacing: 4) {
                                Image(systemName: improvement > 0 ? "arrow.down" : "arrow.up")
                                Text("\(abs(Int(improvement))) mg/dL")
                            }
                            .font(.title3.bold())
                            .foregroundColor(improvement > 0 ? .appSuccess : .appWarning)
                        } else {
                            Text("—")
                                .font(.title3)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
            } else {
                Text("Not enough data yet. Keep logging placements to see insights!")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - Location Performance Section

    private var locationPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Site Performance Ranking")
                .font(.headline)
                .foregroundColor(.textPrimary)
                .padding(.horizontal)

            ForEach(locationPerformance) { performance in
                LocationPerformanceRow(performance: performance)
            }
        }
    }

    // MARK: - Recent Placements Section

    private var recentPlacementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Placements")
                .font(.headline)
                .foregroundColor(.textPrimary)
                .padding(.horizontal)

            let placementsWithGlucose = placements.filter(\.hasGlucoseCorrelation).prefix(10)

            if placementsWithGlucose.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title)
                        .foregroundColor(.textSecondary)
                    Text("Glucose data will appear here after your next placement")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(Array(placementsWithGlucose)) { placement in
                    PlacementGlucoseRow(placement: placement)
                }
            }
        }
    }

    // MARK: - Data Refresh

    private func refreshData() async {
        isRefreshing = true
        defer { isRefreshing = false }

        // Update correlations for recent placements without data
        let placementsNeedingUpdate = placements.filter { !$0.hasGlucoseCorrelation }.prefix(20)
        await healthKitManager.updateCorrelations(
            for: Array(placementsNeedingUpdate),
            context: modelContext
        )

        // Recalculate location performance
        locationPerformance = healthKitManager.analyzePerformanceByLocation(placements: placements)
    }
}

// MARK: - Location Performance Row

struct LocationPerformanceRow: View {
    let performance: LocationGlucosePerformance

    var body: some View {
        HStack(spacing: 12) {
            // Performance icon
            Image(systemName: performance.performanceRating.iconName)
                .font(.title2)
                .foregroundColor(ratingColor)
                .frame(width: 40)

            // Location info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(performance.locationName)
                        .font(.subheadline.bold())
                        .foregroundColor(.textPrimary)

                    if performance.isCustomSite {
                        Text("Custom")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appInfo)
                            .clipShape(Capsule())
                    }
                }

                Text("\(performance.placementCount) placement\(performance.placementCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            // Average glucose
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(performance.averageGlucose)) mg/dL")
                    .font(.subheadline.bold())
                    .foregroundColor(.textPrimary)

                if let improvement = performance.averageImprovement {
                    HStack(spacing: 2) {
                        Image(systemName: improvement > 0 ? "arrow.down" : "arrow.up")
                            .font(.caption2)
                        Text("\(abs(Int(improvement)))")
                            .font(.caption)
                    }
                    .foregroundColor(improvement > 0 ? .appSuccess : .appWarning)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var ratingColor: Color {
        switch performance.performanceRating {
        case .excellent: return .appSuccess
        case .good: return .appInfo
        case .neutral: return .textSecondary
        case .poor: return .appWarning
        case .veryPoor: return .appAccent
        }
    }
}

// MARK: - Placement Glucose Row

struct PlacementGlucoseRow: View {
    let placement: PlacementLog

    var body: some View {
        HStack(spacing: 12) {
            // Location indicator
            Circle()
                .fill(Color.appAccent.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "cross.fill")
                        .font(.caption)
                        .foregroundColor(.appAccent)
                }

            // Placement info
            VStack(alignment: .leading, spacing: 2) {
                Text(placement.locationRawValue ?? placement.customSiteName ?? "Unknown")
                    .font(.subheadline.bold())
                    .foregroundColor(.textPrimary)

                Text(placement.formattedDate)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            // Before/After comparison
            VStack(alignment: .trailing, spacing: 4) {
                if let before = placement.avgGlucoseBefore,
                   let after = placement.avgGlucoseAfter {
                    HStack(spacing: 8) {
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("Before")
                                .font(.caption2)
                                .foregroundColor(.textSecondary)
                            Text("\(Int(before))")
                                .font(.caption.bold())
                                .foregroundColor(.textPrimary)
                        }

                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)

                        VStack(alignment: .trailing, spacing: 0) {
                            Text("After")
                                .font(.caption2)
                                .foregroundColor(.textSecondary)
                            Text("\(Int(after))")
                                .font(.caption.bold())
                                .foregroundColor(after < before ? .appSuccess : .appWarning)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GlucoseCorrelationView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
