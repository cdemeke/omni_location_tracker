//
//  DesignSystem.swift
//  OmniSiteTracker
//
//  Modern glassmorphism design with warm earthy tones.
//  Clean, minimal aesthetic with soft gradients and blur effects.
//

import SwiftUI

// MARK: - Color Palette (Warm Earthy Theme)

extension Color {
    /// Primary background - warm cream gradient base
    static let appBackground = Color(red: 0.98, green: 0.96, blue: 0.92)

    /// Secondary background - soft sand
    static let appBackgroundSecondary = Color(red: 0.96, green: 0.93, blue: 0.88)

    /// Card background - warm white with slight transparency for glass effect
    static let cardBackground = Color(red: 1.0, green: 0.99, blue: 0.97)

    /// Glass background for overlays
    static let glassBackground = Color.white.opacity(0.7)

    /// Primary accent - warm terracotta/coral
    static let appAccent = Color(red: 0.85, green: 0.55, blue: 0.45)

    /// Secondary accent - golden amber
    static let appSecondary = Color(red: 0.92, green: 0.75, blue: 0.45)

    /// Highlight - soft gold
    static let appHighlight = Color(red: 0.95, green: 0.82, blue: 0.55)

    /// Warning - warm orange
    static let appWarning = Color(red: 0.95, green: 0.65, blue: 0.35)

    /// Success - sage green
    static let appSuccess = Color(red: 0.55, green: 0.75, blue: 0.55)

    /// Info - soft sky
    static let appInfo = Color(red: 0.55, green: 0.70, blue: 0.85)

    /// Primary text - warm dark brown
    static let textPrimary = Color(red: 0.25, green: 0.22, blue: 0.20)

    /// Secondary text - warm gray
    static let textSecondary = Color(red: 0.45, green: 0.42, blue: 0.40)

    /// Muted text - light warm gray
    static let textMuted = Color(red: 0.60, green: 0.57, blue: 0.55)

    /// Shadow colors
    static let neumorphicLight = Color.white.opacity(0.8)
    static let neumorphicDark = Color(red: 0.85, green: 0.80, blue: 0.75)

    /// Body diagram colors - warm neutral
    static let bodyFill = Color(red: 0.90, green: 0.88, blue: 0.85)
    static let bodyStroke = Color(red: 0.75, green: 0.72, blue: 0.68)

    /// Zone status colors - earthy palette
    static let zoneAvailable = Color(red: 0.75, green: 0.72, blue: 0.68)
    static let zoneRecent = Color(red: 0.92, green: 0.70, blue: 0.45)
    static let zoneRested = Color(red: 0.60, green: 0.78, blue: 0.55)
}

// MARK: - Glassmorphic Card Style

struct GlassCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.5),
                                        Color.white.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Simplified Neumorphic Card (Fallback)

struct NeumorphicCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    var accentColor: Color = .appAccent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [
                        accentColor,
                        accentColor.opacity(0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .font(.headline)
            .cornerRadius(16)
            .shadow(color: accentColor.opacity(configuration.isPressed ? 0.2 : 0.4), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct NeumorphicButtonStyle: ButtonStyle {
    var accentColor: Color = .appAccent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [accentColor, accentColor.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .font(.headline)
            .cornerRadius(16)
            .shadow(color: accentColor.opacity(configuration.isPressed ? 0.15 : 0.35), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct NeumorphicSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.appAccent.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundColor(.textPrimary)
            .font(.subheadline.weight(.medium))
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func neumorphicCard() -> some View {
        modifier(NeumorphicCardStyle())
    }

    func glassCard(cornerRadius: CGFloat = 24) -> some View {
        modifier(GlassCardStyle(cornerRadius: cornerRadius))
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
                .fontWeight(.bold)
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
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }
}

// MARK: - Gradient Background

struct WarmGradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.96, blue: 0.92),
                Color(red: 0.96, green: 0.94, blue: 0.90),
                Color(red: 0.98, green: 0.95, blue: 0.91)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Custom Tab Bar

struct BodyViewTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .medium)
            .foregroundColor(isSelected ? .white : .textSecondary)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(
                        isSelected
                            ? AnyShapeStyle(LinearGradient(
                                colors: [Color.appAccent, Color.appAccent.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            : AnyShapeStyle(Color.clear)
                    )
            )
            .contentShape(Capsule())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    action()
                }
            }
    }
}

struct BodyViewTabs: View {
    @Binding var selection: BodyView

    var body: some View {
        HStack(spacing: 0) {
            BodyViewTabButton(title: "Front", isSelected: selection == .front) {
                selection = .front
            }
            BodyViewTabButton(title: "Back", isSelected: selection == .back) {
                selection = .back
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.appBackgroundSecondary)
        )
    }
}
