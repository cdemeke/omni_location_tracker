//
//  HomeView.swift
//  OmniSiteTracker
//
//  Primary screen for logging insulin pump placements.
//  Features interactive body diagram and site recommendations.
//

import SwiftUI
import SwiftData

/// Wrapper to make BodyLocation work with sheet(item:)
struct SelectedLocation: Identifiable {
    let id = UUID()
    let location: BodyLocation
}

/// Main home screen with body diagram and quick logging
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PlacementViewModel()
    @State private var selectedLocation: SelectedLocation?
    @State private var showingSuccessToast = false
    @State private var selectedBodyView: BodyView = .front

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Recommendation card
                    RecommendationCard(
                        recommendation: viewModel.recommendedSite,
                        onTap: { location in
                            selectedLocation = SelectedLocation(location: location)
                        }
                    )

                    // Body diagram section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(
                            "Select Placement Site",
                            subtitle: "Tap a location to log a new placement"
                        )

                        BodyDiagramView(
                            viewModel: viewModel,
                            onLocationSelected: { location in
                                selectedLocation = SelectedLocation(location: location)
                            },
                            selectedView: $selectedBodyView
                        )
                        .frame(height: 350)

                        // Front/Back tabs below diagram
                        HStack {
                            Spacer()
                            BodyViewTabs(selection: $selectedBodyView)
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .neumorphicCard()

                    // Recent placement card
                    if let recent = viewModel.mostRecentPlacement {
                        recentPlacementCard(recent)
                    }

                    // Legend
                    legendCard
                }
                .padding(20)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("OmniSite")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.configure(with: modelContext)
            }
            .sheet(item: $selectedLocation) { selected in
                PlacementConfirmationSheet(
                    location: selected.location,
                    viewModel: viewModel,
                    onConfirm: {
                        selectedLocation = nil
                        showSuccessToast()
                    },
                    onCancel: {
                        selectedLocation = nil
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.appBackground)
            }
            .overlay(alignment: .top) {
                if showingSuccessToast {
                    successToast
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    private func recentPlacementCard(_ placement: PlacementLog) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.appAccent)
                Text("Most Recent")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
                Spacer()
            }

            HStack(spacing: 12) {
                Circle()
                    .fill(viewModel.statusColor(for: placement.location))
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(placement.location.displayName)
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Text(placement.relativeTimeString)
                        .font(.caption)
                        .foregroundColor(.textMuted)
                }

                Spacer()

                Text(placement.formattedDate)
                    .font(.caption)
                    .foregroundColor(.textMuted)
            }

            if let note = placement.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .padding(8)
                    .background(Color.appBackground)
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .neumorphicCard()
    }

    private var legendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Site Status")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textSecondary)

            HStack(spacing: 20) {
                legendItem(color: .gray.opacity(0.4), label: "Available")
                legendItem(color: .orange.opacity(0.7), label: "Recent")
                legendItem(color: .green.opacity(0.6), label: "Rested")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption)
                .foregroundColor(.textMuted)
        }
    }

    private var successToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
            Text("Placement logged!")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.appSuccess)
        .cornerRadius(25)
        .shadow(color: Color.appSuccess.opacity(0.4), radius: 8, x: 0, y: 4)
        .padding(.top, 10)
    }

    private func showSuccessToast() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showingSuccessToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showingSuccessToast = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: PlacementLog.self, inMemory: true)
}
