//
//  PlacementConfirmationSheet.swift
//  OmniSiteTracker
//
//  Confirmation sheet for logging a new pump placement.
//  Optimized for quick 2-tap logging workflow.
//

import SwiftUI
import UIKit

/// Sheet presented when user selects a placement location
struct PlacementConfirmationSheet: View {
    let location: BodyLocation
    let viewModel: PlacementViewModel
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var note: String = ""
    @State private var showingNote = false
    @State private var showingPhotoOptions = false
    @State private var selectedPhoto: UIImage?
    @FocusState private var isNoteFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            // Header
            headerView

            // Location info
            locationInfoCard

            // Optional note
            noteSection

            // Photo documentation
            photoSection

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

    private var locationInfoCard: some View {
        VStack(spacing: 16) {
            // Location icon and name
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundColor(.appAccent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(location.displayName)
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Text(viewModel.statusDescription(for: location))
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }

                Spacer()
            }

            // Last used info
            if let days = viewModel.daysSinceLastUse(for: location) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.textMuted)
                    Text("Last used: \(days == 0 ? "Today" : "\(days) day\(days == 1 ? "" : "s") ago")")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    Spacer()
                }
            } else {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.appHighlight)
                    Text("First time using this site!")
                        .font(.subheadline)
                        .foregroundColor(.appHighlight)
                    Spacer()
                }
            }

            // Warning if recently used
            if let days = viewModel.daysSinceLastUse(for: location),
               days < viewModel.minimumRestDays {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.appWarning)
                        .padding(.top, 2)
                    Text("This site was used recently. Consider choosing another location for better rotation.")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(Color.appWarning.opacity(0.1))
                .cornerRadius(10)
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

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingPhotoOptions.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: showingPhotoOptions ? "minus.circle" : "camera")
                        .foregroundColor(.appAccent)
                    Text("Add photo (optional)")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    Spacer()

                    if selectedPhoto != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.appSuccess)
                    }
                }
            }
            .buttonStyle(.plain)

            if showingPhotoOptions {
                PhotoPickerView(selectedImage: $selectedPhoto)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Primary confirm button - large tap target
            Button {
                viewModel.logPlacement(at: location, note: showingNote ? note : nil, photo: selectedPhoto)
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
    PlacementConfirmationSheet(
        location: .abdomenRight,
        viewModel: PlacementViewModel(),
        onConfirm: {},
        onCancel: {}
    )
}
