//
//  DesignSystem.swift
//  OmniSiteTracker
//
//  Clean, modern design system with subtle depth effects.
//  Optimized for performance with simplified shadows.
//

import SwiftUI

// MARK: - Color Palette

extension Color {
    /// Primary background color
    static let appBackground = Color(red: 0.95, green: 0.95, blue: 0.97)

    /// Secondary background for cards
    static let cardBackground = Color(red: 0.98, green: 0.98, blue: 0.99)

    /// Primary accent color - calming teal
    static let appAccent = Color(red: 0.35, green: 0.65, blue: 0.75)

    /// Secondary accent - soft sage
    static let appSecondary = Color(red: 0.55, green: 0.75, blue: 0.65)

    /// Highlight for recommendations
    static let appHighlight = Color(red: 0.45, green: 0.75, blue: 0.70)

    /// Warning - soft amber
    static let appWarning = Color(red: 0.95, green: 0.75, blue: 0.45)

    /// Success - soft green
    static let appSuccess = Color(red: 0.45, green: 0.78, blue: 0.50)

    /// Primary text
    static let textPrimary = Color(red: 0.15, green: 0.20, blue: 0.25)

    /// Secondary text
    static let textSecondary = Color(red: 0.40, green: 0.45, blue: 0.50)

    /// Muted text
    static let textMuted = Color(red: 0.55, green: 0.60, blue: 0.65)

    /// Shadow colors
    static let neumorphicLight = Color.white
    static let neumorphicDark = Color(red: 0.80, green: 0.82, blue: 0.85)

    /// Body diagram colors
    static let bodyFill = Color(red: 0.88, green: 0.89, blue: 0.92)
    static let bodyStroke = Color(red: 0.70, green: 0.72, blue: 0.76)
}

// MARK: - Simplified Card Style

struct NeumorphicCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.cardBackground)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Button Styles

struct NeumorphicButtonStyle: ButtonStyle {
    var accentColor: Color = .appAccent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(configuration.isPressed ? accentColor.opacity(0.85) : accentColor)
            .foregroundColor(.white)
            .font(.headline)
            .cornerRadius(16)
            .shadow(color: accentColor.opacity(configuration.isPressed ? 0 : 0.35), radius: 6, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct NeumorphicSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.cardBackground)
            .foregroundColor(.textPrimary)
            .font(.subheadline.weight(.medium))
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func neumorphicCard() -> some View {
        modifier(NeumorphicCardStyle())
    }
}

// MARK: - Reusable Components

struct SectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color)
            .cornerRadius(8)
    }
}
