//
//  RecommendationCard.swift
//  OmniSiteTracker
//
//  Displays the recommended next placement site with clear visual emphasis.
//

import SwiftUI

/// Local help button for RecommendationCard
private struct RecommendationHelpButton: View {
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

/// Card displaying the recommended next placement location
struct RecommendationCard: View {
    let recommendation: SiteRecommendation?
    let onTap: (BodyLocation) -> Void
    var onHelpTapped: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.appHighlight)
                    .font(.title3)

                Text("Recommended Next Site")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                if let onHelpTapped {
                    RecommendationHelpButton(onTap: onHelpTapped)
                }
            }

            if let recommendation = recommendation {
                // Recommendation content
                Button {
                    onTap(recommendation.location)
                } label: {
                    HStack(spacing: 16) {
                        // Location indicator
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.appHighlight, Color.appAccent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .shadow(color: Color.appHighlight.opacity(0.4), radius: 8, x: 0, y: 4)

                            Image(systemName: "mappin.and.ellipse")
                                .font(.title2)
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(recommendation.location.displayName)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)

                            Text(recommendation.explanation)
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)

                            Text(recommendation.reason)
                                .font(.caption)
                                .foregroundColor(.textMuted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.subheadline)
                            .foregroundColor(.textMuted)
                    }
                    .padding(16)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.appHighlight.opacity(0.08),
                                Color.appAccent.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.appHighlight.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            } else {
                // No recommendation available
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.appSuccess)
                    Text("All sites are well rotated!")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appSuccess.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .neumorphicCard()
    }
}

/// Compact recommendation indicator for the body diagram view
struct CompactRecommendationBadge: View {
    let recommendation: SiteRecommendation?

    var body: some View {
        if let recommendation = recommendation {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption)
                Text("Try: \(recommendation.location.shortName)")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [Color.appHighlight, Color.appAccent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(color: Color.appHighlight.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        RecommendationCard(
            recommendation: SiteRecommendation(
                location: .leftArm,
                daysSinceLastUse: 12,
                reason: "Longest rest period among available sites"
            ),
            onTap: { _ in }
        )

        RecommendationCard(
            recommendation: nil,
            onTap: { _ in }
        )
    }
    .padding()
    .background(Color.appBackground)
}
