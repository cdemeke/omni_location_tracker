//
//  HistoryView.swift
//  OmniSiteTracker
//
//  Displays placement history with filtering and timeline visualization.
//

import SwiftUI
import SwiftData

// MARK: - Local Components (workaround for scope issues)

private struct HistoryHelpTooltip: View {
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

private struct HistoryAboutModal: View {
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

/// History screen showing past placement records
struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PlacementViewModel()
    @State private var settingsViewModel = SettingsViewModel()
    @State private var selectedFilter: BodyLocation?
    @State private var selectedCustomSiteFilter: UUID?
    @State private var showingFilterSheet = false
    @State private var placementToEdit: PlacementLog?
    @State private var showingHistoryHelp = false
    @State private var showingAboutModal = false
    @State private var scrollOffset: CGFloat = 0
    @State private var customSites: [CustomSite] = []
    @State private var showDisabledSitesInHistory: Bool = true
    @State private var disabledDefaultSites: Set<BodyLocation> = []
    @AppStorage("hasSeenHistoryHelp") private var hasSeenHelp = false

    private var showNavBarLogo: Bool {
        scrollOffset < 100
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.placements.isEmpty {
                    emptyStateView
                } else {
                    historyList
                }
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
                        Text("History")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                            .transition(.opacity)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    filterButton
                }
            }
            .onAppear {
                viewModel.configure(with: modelContext)
                settingsViewModel.configure(with: modelContext)
                customSites = settingsViewModel.getCustomSites()
                showDisabledSitesInHistory = settingsViewModel.getShowDisabledSitesInHistory()
                disabledDefaultSites = Set(settingsViewModel.getDisabledDefaultSites())
                // Auto-show tooltip on first visit after delay
                if !hasSeenHelp {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            showingHistoryHelp = true
                        }
                    }
                }
            }
            .overlay {
                if showingHistoryHelp {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showingHistoryHelp = false
                            }
                            if !hasSeenHelp {
                                hasSeenHelp = true
                            }
                        }
                    HistoryHelpTooltip(
                        message: "Your complete placement history. Swipe left to delete, tap to edit."
                    ) {
                        withAnimation {
                            showingHistoryHelp = false
                        }
                        if !hasSeenHelp {
                            hasSeenHelp = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                filterSheet
            }
            .sheet(item: $placementToEdit) { placement in
                PlacementEditSheet(
                    placement: placement,
                    onSave: { newLocation, newDate, newNote in
                        viewModel.updatePlacement(placement, location: newLocation, date: newDate, note: newNote)
                        placementToEdit = nil
                    },
                    onDelete: {
                        viewModel.deletePlacement(placement)
                        placementToEdit = nil
                    },
                    onCancel: {
                        placementToEdit = nil
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingAboutModal) {
                HistoryAboutModal()
                    .presentationDetents([.medium])
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.textMuted.opacity(0.5))

            Text("No Placement History")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            Text("Start by logging your first pump placement on the Home screen.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
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
                    Text("History")
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

                // Summary stats
                summarySection

                // Custom sites summary (only if there are custom site placements)
                if !customSitesWithPlacements.isEmpty {
                    customSitesSummarySection
                }

                // Filter indicator
                if let filter = selectedFilter {
                    filterIndicator(filter)
                } else if let customSiteId = selectedCustomSiteFilter {
                    customSiteFilterIndicator(customSiteId)
                }

                // Placement list grouped by day
                ForEach(filteredPlacementsByDay, id: \.date) { group in
                    daySection(date: group.date, placements: group.placements)
                }
            }
            .padding(20)
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Site Usage Summary")
                .font(.headline)
                .foregroundColor(.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(BodyLocation.allCases) { location in
                    siteUsageCard(location)
                }
            }
        }
        .padding(20)
        .neumorphicCard()
    }

    private func siteUsageCard(_ location: BodyLocation) -> some View {
        let count = displayFilteredPlacements.filter { $0.location == location }.count
        let lastUsed = viewModel.daysSinceLastUse(for: location)

        return Button {
            if selectedFilter == location {
                selectedFilter = nil
                selectedCustomSiteFilter = nil
            } else {
                selectedFilter = location
                selectedCustomSiteFilter = nil
            }
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(viewModel.statusColor(for: location))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text("\(count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .overlay {
                        if selectedFilter == location {
                            Circle()
                                .stroke(Color.appAccent, lineWidth: 2)
                        }
                    }

                Text(location.shortName)
                    .font(.system(size: 9))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)

                if let days = lastUsed {
                    Text("\(days)d")
                        .font(.system(size: 8))
                        .foregroundColor(.textMuted)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var customSitesSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom Sites")
                .font(.headline)
                .foregroundColor(.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(customSitesWithPlacements, id: \.id) { customSite in
                    customSiteUsageCard(customSite)
                }
            }
        }
        .padding(20)
        .neumorphicCard()
    }

    private func customSiteUsageCard(_ customSite: CustomSite) -> some View {
        let count = customSitePlacementCount(for: customSite.id)

        return Button {
            if selectedCustomSiteFilter == customSite.id {
                selectedCustomSiteFilter = nil
            } else {
                selectedFilter = nil
                selectedCustomSiteFilter = customSite.id
            }
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(Color.appAccent.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: customSite.iconName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.appAccent)
                    }
                    .overlay {
                        if selectedCustomSiteFilter == customSite.id {
                            Circle()
                                .stroke(Color.appAccent, lineWidth: 2)
                        }
                    }

                Text(customSite.name)
                    .font(.system(size: 9))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)

                Text("\(count)")
                    .font(.system(size: 8))
                    .foregroundColor(.textMuted)
            }
        }
        .buttonStyle(.plain)
    }

    private func filterIndicator(_ filter: BodyLocation) -> some View {
        HStack {
            Text("Showing: \(filter.displayName)")
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedFilter = nil
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Clear")
                    Image(systemName: "xmark.circle.fill")
                }
                .font(.caption)
                .foregroundColor(.appAccent)
            }
        }
        .padding(.horizontal, 4)
    }

    private func customSiteFilterIndicator(_ customSiteId: UUID) -> some View {
        let customSite = customSites.first { $0.id == customSiteId }
        return HStack {
            Text("Showing: \(customSite?.name ?? "Custom Site")")
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedCustomSiteFilter = nil
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Clear")
                    Image(systemName: "xmark.circle.fill")
                }
                .font(.caption)
                .foregroundColor(.appAccent)
            }
        }
        .padding(.horizontal, 4)
    }

    private func daySection(date: Date, placements: [PlacementLog]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date header
            HStack {
                Text(formatDateHeader(date))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)

                Spacer()

                Text("\(placements.count) placement\(placements.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.textMuted)
            }
            .padding(.horizontal, 4)

            // Placement cards
            ForEach(placements) { placement in
                placementCard(placement)
            }
        }
    }

    private func placementCard(_ placement: PlacementLog) -> some View {
        Button {
            placementToEdit = placement
        } label: {
            HStack(spacing: 14) {
                // Status indicator or custom site icon
                if placement.isCustomSite {
                    // Custom site - show the icon
                    let customSite = placement.customSiteId.flatMap { id in
                        customSites.first { $0.id == id }
                    }
                    Image(systemName: customSite?.iconName ?? "star.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appAccent)
                        .frame(width: 14, height: 14)
                } else {
                    // Default site - show status color circle
                    Circle()
                        .fill(placement.location.map { viewModel.statusColor(for: $0) } ?? Color.gray.opacity(0.4))
                        .frame(width: 14, height: 14)
                }

                // Placement info
                VStack(alignment: .leading, spacing: 4) {
                    Text(placement.location?.displayName ?? placement.customSiteName ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    HStack(spacing: 12) {
                        Label {
                            Text(placement.relativeTimeString)
                                .foregroundColor(.textSecondary)
                        } icon: {
                            Image(systemName: "clock")
                                .foregroundColor(.textMuted)
                        }
                        .font(.caption)
                    }

                    if let note = placement.note, !note.isEmpty {
                        Text("📝 \(note)")
                            .font(.caption)
                            .foregroundColor(.textMuted)
                            .padding(.top, 2)
                    }
                }

                Spacer()

                // Edit indicator and time
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.textMuted)
                    Text(formatTime(placement.placedAt))
                        .font(.caption)
                        .foregroundColor(.textMuted)
                }
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(14)
            .shadow(color: Color.neumorphicDark.opacity(0.15), radius: 4, x: 2, y: 2)
            .shadow(color: Color.neumorphicLight.opacity(0.8), radius: 4, x: -2, y: -2)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                placementToEdit = placement
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                viewModel.deletePlacement(placement)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var filterButton: some View {
        Button {
            showingFilterSheet = true
        } label: {
            Image(systemName: selectedFilter == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                .font(.title3)
                .foregroundColor(.appAccent)
        }
    }

    private var filterSheet: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        selectedFilter = nil
                        selectedCustomSiteFilter = nil
                        showingFilterSheet = false
                    } label: {
                        HStack {
                            Text("All Locations")
                                .foregroundColor(.textPrimary)
                            Spacer()
                            if selectedFilter == nil && selectedCustomSiteFilter == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.appAccent)
                            }
                        }
                    }
                }

                Section("Filter by Location") {
                    ForEach(BodyLocation.allCases) { location in
                        Button {
                            selectedFilter = location
                            selectedCustomSiteFilter = nil
                            showingFilterSheet = false
                        } label: {
                            HStack {
                                Circle()
                                    .fill(viewModel.statusColor(for: location))
                                    .frame(width: 12, height: 12)

                                Text(location.displayName)
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                Text("\(viewModel.placements(for: location).count)")
                                    .font(.caption)
                                    .foregroundColor(.textMuted)

                                if selectedFilter == location {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.appAccent)
                                }
                            }
                        }
                    }
                }

                // Custom sites section (only if there are custom sites with placements)
                if !customSitesWithPlacements.isEmpty {
                    Section("Filter by Custom Site") {
                        ForEach(customSitesWithPlacements, id: \.id) { customSite in
                            Button {
                                selectedFilter = nil
                                selectedCustomSiteFilter = customSite.id
                                showingFilterSheet = false
                            } label: {
                                HStack {
                                    Image(systemName: customSite.iconName)
                                        .font(.caption)
                                        .foregroundColor(.appAccent)
                                        .frame(width: 12)

                                    Text(customSite.name)
                                        .foregroundColor(.textPrimary)

                                    Spacer()

                                    Text("\(customSitePlacementCount(for: customSite.id))")
                                        .font(.caption)
                                        .foregroundColor(.textMuted)

                                    if selectedCustomSiteFilter == customSite.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.appAccent)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingFilterSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    /// Placements filtered by display preference setting
    /// When showDisabledSitesInHistory is OFF, filters out:
    /// - Placements for currently disabled default sites
    /// - Placements for deleted custom sites (custom site no longer exists)
    private var displayFilteredPlacements: [PlacementLog] {
        if showDisabledSitesInHistory {
            // Show all placements regardless of site status
            return viewModel.placements
        } else {
            // Filter out disabled default sites and deleted custom sites
            let existingCustomSiteIds = Set(customSites.map { $0.id })
            return viewModel.placements.filter { placement in
                if let location = placement.location {
                    // Default site placement - check if site is enabled
                    return !disabledDefaultSites.contains(location)
                } else if let customSiteId = placement.customSiteId {
                    // Custom site placement - check if custom site still exists
                    return existingCustomSiteIds.contains(customSiteId)
                }
                // Unknown placement type - show it
                return true
            }
        }
    }

    /// Custom sites that have at least one placement in history (respecting display preference)
    private var customSitesWithPlacements: [CustomSite] {
        let customSiteIdsWithPlacements = Set(
            displayFilteredPlacements.compactMap { $0.customSiteId }
        )
        return customSites.filter { customSiteIdsWithPlacements.contains($0.id) }
    }

    /// Count of placements for a given custom site (respecting display preference)
    private func customSitePlacementCount(for customSiteId: UUID) -> Int {
        displayFilteredPlacements.filter { $0.customSiteId == customSiteId }.count
    }

    private var filteredPlacementsByDay: [(date: Date, placements: [PlacementLog])] {
        let calendar = Calendar.current
        let basePlacements = displayFilteredPlacements

        if let filter = selectedFilter {
            // Filter by BodyLocation
            let filtered = basePlacements.filter { $0.location == filter }
            let grouped = Dictionary(grouping: filtered) { placement in
                calendar.startOfDay(for: placement.placedAt)
            }
            return grouped
                .sorted { $0.key > $1.key }
                .map { (date: $0.key, placements: $0.value) }
        } else if let customSiteId = selectedCustomSiteFilter {
            // Filter by custom site
            let filtered = basePlacements.filter { $0.customSiteId == customSiteId }
            let grouped = Dictionary(grouping: filtered) { placement in
                calendar.startOfDay(for: placement.placedAt)
            }
            return grouped
                .sorted { $0.key > $1.key }
                .map { (date: $0.key, placements: $0.value) }
        } else {
            // Group all filtered placements by day
            let grouped = Dictionary(grouping: basePlacements) { placement in
                calendar.startOfDay(for: placement.placedAt)
            }
            return grouped
                .sorted { $0.key > $1.key }
                .map { (date: $0.key, placements: $0.value) }
        }
    }

    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
        .modelContainer(for: PlacementLog.self, inMemory: true)
}
