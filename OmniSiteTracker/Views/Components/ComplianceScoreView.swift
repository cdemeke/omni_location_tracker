//
//  ComplianceScoreView.swift
//  OmniSiteTracker
//
//  Displays the rotation compliance score in a circular progress indicator
//  with color coding based on score level.
//

import SwiftUI

struct ComplianceScoreView: View {
    let rotationScore: RotationScore

    var body: some View {
        VStack(spacing: 20) {
            // Circular score gauge
            ScoreGauge(score: rotationScore.score)

            // Score breakdown
            HStack(spacing: 24) {
                ScoreComponent(
                    title: "Distribution",
                    score: rotationScore.distributionScore,
                    maxScore: 50
                )

                ScoreComponent(
                    title: "Rest Compliance",
                    score: rotationScore.restComplianceScore,
                    maxScore: 50
                )
            }

            // Explanation text
            Text(rotationScore.explanation)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .neumorphicCard()
    }
}

// MARK: - Circular Score Gauge

private struct ScoreGauge: View {
    let score: Int

    private let lineWidth: CGFloat = 12

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.appBackgroundSecondary, lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(
                    scoreColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: score)

            // Score label
            VStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor)

                Text("out of 100")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(width: 160, height: 160)
    }

    /// Color based on score: red (<50), orange (50-75), green (>75)
    private var scoreColor: Color {
        if score < 50 {
            return Color(red: 0.85, green: 0.35, blue: 0.35) // Red
        } else if score <= 75 {
            return .appWarning // Orange
        } else {
            return .appSuccess // Green
        }
    }
}

// MARK: - Score Component

private struct ScoreComponent: View {
    let title: String
    let score: Int
    let maxScore: Int

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)

            HStack(spacing: 4) {
                Text("\(score)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)

                Text("/\(maxScore)")
                    .font(.caption)
                    .foregroundColor(.textMuted)
            }

            // Mini progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.appBackgroundSecondary)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * CGFloat(score) / CGFloat(maxScore), height: 6)
                }
            }
            .frame(height: 6)
            .frame(width: 80)
        }
    }

    private var progressColor: Color {
        let percentage = Double(score) / Double(maxScore) * 100
        if percentage < 50 {
            return Color(red: 0.85, green: 0.35, blue: 0.35) // Red
        } else if percentage <= 75 {
            return .appWarning // Orange
        } else {
            return .appSuccess // Green
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleScore = RotationScore(
        score: 72,
        distributionScore: 35,
        restComplianceScore: 37,
        explanation: "Good rotation pattern! You're using most sites evenly. Consider varying your rest days slightly for optimal compliance."
    )

    return ScrollView {
        ComplianceScoreView(rotationScore: sampleScore)
            .padding()
    }
    .background(WarmGradientBackground())
}
