//
//  DesignSystem.swift
//  OmniSiteTracker
//
//  Modern glassmorphism design with warm earthy tones.
//  Clean, minimal aesthetic with soft gradients and blur effects.
//  Supports both light and dark modes with adaptive colors.
//

import SwiftUI
import UIKit

// MARK: - App Color Scheme

/// User preference for app appearance
enum AppColorScheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var description: String {
        switch self {
        case .system:
            return "Follows your device settings"
        case .light:
            return "Always use light appearance"
        case .dark:
            return "Always use dark appearance"
        }
    }
}

// MARK: - Adaptive Color Palette (Warm Earthy Theme)

extension Color {
    // MARK: - Background Colors

    /// Primary background - warm cream (light) / dark warm gray (dark)
    static let appBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.11, blue: 0.10, alpha: 1.0)
            : UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0)
    })

    /// Secondary background - soft sand (light) / darker gray (dark)
    static let appBackgroundSecondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.09, blue: 0.08, alpha: 1.0)
            : UIColor(red: 0.96, green: 0.93, blue: 0.88, alpha: 1.0)
    })

    /// Card background - warm white (light) / dark elevated surface (dark)
    static let cardBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.17, blue: 0.16, alpha: 1.0)
            : UIColor(red: 1.0, green: 0.99, blue: 0.97, alpha: 1.0)
    })

    /// Glass background for overlays
    static let glassBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.15, alpha: 0.5)
            : UIColor(white: 1.0, alpha: 0.7)
    })

    // MARK: - Accent Colors

    /// Primary accent - warm terracotta/coral (slightly brighter in dark mode)
    static let appAccent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.90, green: 0.60, blue: 0.50, alpha: 1.0)
            : UIColor(red: 0.85, green: 0.55, blue: 0.45, alpha: 1.0)
    })

    /// Secondary accent - golden amber
    static let appSecondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.78, blue: 0.50, alpha: 1.0)
            : UIColor(red: 0.92, green: 0.75, blue: 0.45, alpha: 1.0)
    })

    /// Highlight - soft gold
    static let appHighlight = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.97, green: 0.84, blue: 0.58, alpha: 1.0)
            : UIColor(red: 0.95, green: 0.82, blue: 0.55, alpha: 1.0)
    })

    /// Warning - warm orange
    static let appWarning = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.97, green: 0.68, blue: 0.40, alpha: 1.0)
            : UIColor(red: 0.95, green: 0.65, blue: 0.35, alpha: 1.0)
    })

    /// Success - sage green
    static let appSuccess = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.58, green: 0.78, blue: 0.58, alpha: 1.0)
            : UIColor(red: 0.55, green: 0.75, blue: 0.55, alpha: 1.0)
    })

    /// Info - soft sky
    static let appInfo = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.58, green: 0.73, blue: 0.88, alpha: 1.0)
            : UIColor(red: 0.55, green: 0.70, blue: 0.85, alpha: 1.0)
    })

    // MARK: - Text Colors

    /// Primary text - warm dark brown (light) / light cream (dark)
    static let textPrimary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1.0)
            : UIColor(red: 0.25, green: 0.22, blue: 0.20, alpha: 1.0)
    })

    /// Secondary text - warm gray
    static let textSecondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.75, green: 0.72, blue: 0.70, alpha: 1.0)
            : UIColor(red: 0.45, green: 0.42, blue: 0.40, alpha: 1.0)
    })

    /// Muted text - light warm gray
    static let textMuted = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.55, green: 0.52, blue: 0.50, alpha: 1.0)
            : UIColor(red: 0.60, green: 0.57, blue: 0.55, alpha: 1.0)
    })

    // MARK: - Shadow/Effect Colors

    /// Neumorphic light shadow
    static let neumorphicLight = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.1)
            : UIColor(white: 1.0, alpha: 0.8)
    })

    /// Neumorphic dark shadow
    static let neumorphicDark = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.0, alpha: 0.4)
            : UIColor(red: 0.85, green: 0.80, blue: 0.75, alpha: 1.0)
    })

    // MARK: - Body Diagram Colors

    /// Body diagram fill
    static let bodyFill = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.30, green: 0.27, blue: 0.25, alpha: 1.0)
            : UIColor(red: 0.90, green: 0.88, blue: 0.85, alpha: 1.0)
    })

    /// Body diagram stroke
    static let bodyStroke = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.45, green: 0.42, blue: 0.40, alpha: 1.0)
            : UIColor(red: 0.75, green: 0.72, blue: 0.68, alpha: 1.0)
    })

    // MARK: - Zone Status Colors

    /// Zone available color
    static let zoneAvailable = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.50, green: 0.48, blue: 0.45, alpha: 1.0)
            : UIColor(red: 0.75, green: 0.72, blue: 0.68, alpha: 1.0)
    })

    /// Zone recently used color
    static let zoneRecent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.73, blue: 0.50, alpha: 1.0)
            : UIColor(red: 0.92, green: 0.70, blue: 0.45, alpha: 1.0)
    })

    /// Zone well-rested color
    static let zoneRested = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.63, green: 0.80, blue: 0.58, alpha: 1.0)
            : UIColor(red: 0.60, green: 0.78, blue: 0.55, alpha: 1.0)
    })
}

// MARK: - Glassmorphic Card Style

struct GlassCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 24
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: colorScheme == .dark
                                        ? [Color.white.opacity(0.1), Color.white.opacity(0.05)]
                                        : [Color.white.opacity(0.5), Color.white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: colorScheme == .dark
                                        ? [Color.white.opacity(0.2), Color.white.opacity(0.05)]
                                        : [Color.white.opacity(0.6), Color.white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: colorScheme == .dark
                    ? Color.black.opacity(0.3)
                    : Color.black.opacity(0.08),
                    radius: 16, x: 0, y: 8)
    }
}

// MARK: - Simplified Neumorphic Card (Fallback)

struct NeumorphicCardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cardBackground)
                    .shadow(color: colorScheme == .dark
                            ? Color.black.opacity(0.3)
                            : Color.black.opacity(0.06),
                            radius: 10, x: 0, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(colorScheme == .dark
                                    ? Color.white.opacity(0.1)
                                    : Color.white.opacity(0.5),
                                    lineWidth: 1)
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
    @Environment(\.colorScheme) private var colorScheme

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
            .shadow(color: colorScheme == .dark
                    ? Color.black.opacity(0.2)
                    : Color.black.opacity(0.04),
                    radius: 4, x: 0, y: 2)
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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.11, blue: 0.10),
                        Color(red: 0.10, green: 0.09, blue: 0.08),
                        Color(red: 0.11, green: 0.10, blue: 0.09)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            } else {
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
    }
}

// MARK: - Custom Tab Bar

struct BodyViewTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

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
    @Environment(\.colorScheme) private var colorScheme

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
                .fill(colorScheme == .dark
                      ? Color(red: 0.15, green: 0.14, blue: 0.13)
                      : Color.appBackgroundSecondary)
        )
    }
}
