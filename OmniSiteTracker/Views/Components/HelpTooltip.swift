//
//  HelpTooltip.swift
//  OmniSiteTracker
//
//  A reusable tooltip component for displaying contextual help messages.
//

import SwiftUI

/// A reusable tooltip component for contextual help throughout the app
struct HelpTooltip: View {
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

// MARK: - About Modal

/// Modal displaying the story and purpose behind OmniSite
struct AboutModal: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingMedicalInfo = false

    var body: some View {
        VStack(spacing: 20) {
            // App icon
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

            // App name
            Text("OmniSite")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            // Message
            Text("This app was developed by a father caring for his child with Type 1 Diabetes.\n\nIt's intended to help you track and rotate pump placement locations based on general medical guidelines.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // Medical disclaimer and link
            VStack(spacing: 8) {
                Text("This app does not provide medical advice.")
                    .font(.caption)
                    .foregroundColor(.textMuted)
                    .multilineTextAlignment(.center)

                Button {
                    showingMedicalInfo = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text("View Medical Information & Sources")
                            .font(.caption)
                            .underline()
                    }
                    .foregroundColor(.appAccent)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.textSecondary.opacity(0.1))
            .cornerRadius(8)

            // Love message
            VStack(spacing: 8) {
                Text("Made with love.")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)

                Text("Love you, Theo.")
                    .font(.headline)
                    .foregroundColor(.appAccent)
            }

            Spacer()

            // Dismiss button
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
        .padding(24)
        .background(Color.appBackground)
        .sheet(isPresented: $showingMedicalInfo) {
            MedicalInformationView()
        }
    }
}

// MARK: - Preview

#Preview("HelpTooltip") {
    ZStack {
        Color.appBackground
            .ignoresSafeArea()

        HelpTooltip(message: "This suggests the best site based on your rotation history") {
            print("Dismissed")
        }
        .padding()
    }
}

#Preview("AboutModal") {
    AboutModal()
}
