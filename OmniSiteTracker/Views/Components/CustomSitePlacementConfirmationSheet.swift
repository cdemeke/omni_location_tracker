//
//  CustomSitePlacementConfirmationSheet.swift
//  OmniSiteTracker
//
//  Confirmation sheet for logging a new pump placement at a custom site.
//  Mirrors the PlacementConfirmationSheet flow for default body locations.
//

import SwiftUI

/// Sheet presented when user selects a custom site for placement
struct CustomSitePlacementConfirmationSheet: View {
    let customSite: CustomSite
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var note: String = ""
    @State private var showingNote = false
    @FocusState private var isNoteFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            // Header
            headerView

            // Custom site info
            customSiteInfoCard

            // Optional note
            noteSection

            // Action buttons
            actionButtons
        }
        .padding(24)
        .background(Color.appBackground)
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.textMuted.opacity(0.5))
                .frame(width: 40, height: 4)

            Text("Confirm Placement")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
        }
    }

    private var customSiteInfoCard: some View {
        VStack(spacing: 16) {
            // Custom site icon and name
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: customSite.iconName)
                        .font(.title)
                        .foregroundColor(.appAccent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(customSite.name)
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Text("Custom Site")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }

                Spacer()
            }

            // First use indicator for custom sites
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.appHighlight)
                Text("Custom site placement")
                    .font(.subheadline)
                    .foregroundColor(.appHighlight)
                Spacer()
            }
        }
        .padding(20)
        .neumorphicCard()
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingNote.toggle()
                    if showingNote {
                        isNoteFocused = true
                    }
                }
            } label: {
                HStack {
                    Image(systemName: showingNote ? "minus.circle" : "plus.circle")
                        .foregroundColor(.appAccent)
                    Text("Add a note (optional)")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if showingNote {
                TextField("e.g., Site felt tender", text: $note)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.neumorphicDark.opacity(0.2), lineWidth: 1)
                    )
                    .focused($isNoteFocused)
                    .submitLabel(.done)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Primary confirm button - large tap target
            Button {
                // Note: Actual logging of custom site placements requires US-019 to update PlacementLog
                // For now, we complete the confirmation flow but the placement won't be saved to the database
                onConfirm()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Log Placement")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(NeumorphicButtonStyle())

            // Cancel button
            Button {
                onCancel()
            } label: {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(NeumorphicSecondaryButtonStyle())
        }
    }
}

// MARK: - Preview

#Preview {
    CustomSitePlacementConfirmationSheet(
        customSite: CustomSite(name: "Upper Arm", iconName: "star.fill"),
        onConfirm: {},
        onCancel: {}
    )
}
