//
//  HomeView.swift
//  OmniSiteTracker
//
//  Primary screen for logging insulin pump placements.
//  Features interactive body diagram and site recommendations.
//

import SwiftUI
import SwiftData

// MARK: - Local Components (workaround for scope issues)

private struct HomeHelpButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 18))
                .foregroundColor(.textMuted)
        }
        .buttonStyle(.plain)
    }
}

private struct HomeHelpTooltip: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(message)
                .font(.subheadline)
                .foregroundColor(.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onDismiss) {
                Text("Got it")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appAccent)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .frame(maxWidth: 280)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 4)
        )
        .transition(.opacity)
    }
}

private struct HomeAboutModal: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

            Text("OmniSite")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text("This app was developed by a father caring for his child with Type 1 Diabetes.\n\nIt's intended to help ensure you're rotating pump placement locations and minimizing the chance of scar tissue developing.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                Text("Made with love.")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)

                Text("Love you, Theo.")
                    .font(.headline)
                    .foregroundColor(.appAccent)
            }
            .padding(.top, 8)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appAccent)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 24)
        .background(Color.appBackground)
    }
}

private struct HomeOnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    var isReviewing: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 24))

            Text("Welcome to OmniSite")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            VStack(spacing: 16) {
                featureRow(icon: "mappin.circle.fill", title: "Track Placements", description: "Log your insulin pump site locations")
                featureRow(icon: "arrow.triangle.2.circlepath", title: "Smart Rotation", description: "Get recommendations for optimal site rotation")
                featureRow(icon: "chart.bar.fill", title: "View Patterns", description: "Analyze your placement history and trends")
            }
            .padding(.horizontal)

            Spacer()

            Button {
                hasCompletedOnboarding = true
                dismiss()
            } label: {
                Text(isReviewing ? "Done" : "Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appAccent)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.appAccent)
                .frame(width: 44, height: 44)
                .background(Color.appAccent.opacity(0.1))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
    }
}

/// Wrapper to make BodyLocation work with sheet(item:)
struct SelectedLocation: Identifiable {
    let id = UUID()
    let location: BodyLocation
}

/// Wrapper to make CustomSite work with sheet(item:)
struct SelectedCustomSite: Identifiable {
    let id: UUID
    let customSite: CustomSite

    init(customSite: CustomSite) {
        self.id = customSite.id
        self.customSite = customSite
    }
}

/// Main home screen with body diagram and quick logging
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PlacementViewModel()
    @State private var settingsViewModel = SettingsViewModel()
    @State private var selectedLocation: SelectedLocation?
    @State private var showingSuccessToast = false
    @State private var selectedBodyView: BodyView = .front
    @State private var showingOnboarding = false
    @State private var showingRecommendationHelp = false
    @State private var showingDiagramHelp = false
    @State private var showingAboutModal = false
    @State private var scrollOffset: CGFloat = 0
    @State private var enabledLocations: Set<BodyLocation> = Set(BodyLocation.allCases)
    @State private var enabledCustomSites: [CustomSite] = []
    @State private var selectedCustomSite: SelectedCustomSite?

    private var showNavBarLogo: Bool {
        scrollOffset < 100
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Custom large title with icon
                    HStack(spacing: 12) {
                        Button {
                            showingAboutModal = true
                        } label: {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        Text("OmniSite")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onChange(of: geo.frame(in: .global).minY) { _, newValue in
                                    scrollOffset = newValue
                                }
                                .onAppear {
                                    scrollOffset = geo.frame(in: .global).minY
                                }
                        }
                    )
                    // Recommendation card with help button
                    RecommendationCard(
                        recommendation: viewModel.recommendedSite,
                        onTap: { location in
                            selectedLocation = SelectedLocation(location: location)
                        },
                        onHelpTapped: {
                            withAnimation {
                                showingRecommendationHelp = true
                            }
                        }
                    )

                    // Body diagram section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                            SectionHeader(
                                "Select Placement Site",
                                subtitle: "Tap a location to log a new placement"
                            )
                            Spacer()
                            HomeHelpButton {
                                withAnimation {
                                    showingDiagramHelp = true
                                }
                            }
                        }

                        BodyDiagramView(
                            viewModel: viewModel,
                            onLocationSelected: { location in
                                selectedLocation = SelectedLocation(location: location)
                            },
                            selectedView: $selectedBodyView,
                            enabledLocations: enabledLocations
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

                    // Custom sites section (only shown if custom sites exist)
                    if !enabledCustomSites.isEmpty {
                        customSitesSection
                    }

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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if showNavBarLogo {
                        Button {
                            showingAboutModal = true
                        } label: {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        }
                        .transition(.opacity)
                    }
                }
                ToolbarItem(placement: .principal) {
                    if showNavBarLogo {
                        Text("OmniSite")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                            .transition(.opacity)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingOnboarding = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.textMuted)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingOnboarding) {
                HomeOnboardingView(
                    hasCompletedOnboarding: .constant(true),
                    isReviewing: true
                )
            }
            .sheet(isPresented: $showingAboutModal) {
                HomeAboutModal()
                    .presentationDetents([.medium])
            }
            .onAppear {
                viewModel.configure(with: modelContext)
                settingsViewModel.configure(with: modelContext)
                loadEnabledLocations()
                loadEnabledCustomSites()
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
            .sheet(item: $selectedCustomSite) { selected in
                CustomSitePlacementConfirmationSheet(
                    customSite: selected.customSite,
                    viewModel: viewModel,
                    onConfirm: {
                        selectedCustomSite = nil
                        showSuccessToast()
                    },
                    onCancel: {
                        selectedCustomSite = nil
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
            .overlay {
                if showingRecommendationHelp {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showingRecommendationHelp = false
                            }
                        }
                    HomeHelpTooltip(
                        message: "This suggests the best site based on your rotation history"
                    ) {
                        withAnimation {
                            showingRecommendationHelp = false
                        }
                    }
                }
            }
            .overlay {
                if showingDiagramHelp {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showingDiagramHelp = false
                            }
                        }
                    HomeHelpTooltip(
                        message: "Tap any zone to log a new placement. Colors show site status."
                    ) {
                        withAnimation {
                            showingDiagramHelp = false
                        }
                    }
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
                    .fill(placement.location.map { viewModel.statusColor(for: $0) } ?? Color.gray.opacity(0.4))
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(placement.location?.displayName ?? placement.customSiteName ?? "Unknown")
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

    /// Loads enabled body locations from settings
    private func loadEnabledLocations() {
        let disabledLocations = settingsViewModel.getDisabledDefaultSites()
        let allLocations = Set(BodyLocation.allCases)
        enabledLocations = allLocations.subtracting(Set(disabledLocations))
    }

    /// Loads enabled custom sites from settings
    private func loadEnabledCustomSites() {
        enabledCustomSites = settingsViewModel.getCustomSites().filter { $0.isEnabled }
    }

    /// Custom sites section displayed below body diagram
    private var customSitesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                "Custom Sites",
                subtitle: "Tap to log a placement"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(enabledCustomSites, id: \.id) { customSite in
                        customSiteButton(for: customSite)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(20)
        .neumorphicCard()
    }

    /// Button for a custom site in the horizontal scroll
    private func customSiteButton(for customSite: CustomSite) -> some View {
        Button {
            selectedCustomSite = SelectedCustomSite(customSite: customSite)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.15))
                        .frame(width: 52, height: 52)

                    Image(systemName: customSite.iconName)
                        .font(.title2)
                        .foregroundColor(.appAccent)
                }

                Text(customSite.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
            }
            .frame(width: 80)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: PlacementLog.self, inMemory: true)
}
