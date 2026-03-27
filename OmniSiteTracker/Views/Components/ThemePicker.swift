//
//  ThemePicker.swift
//  OmniSiteTracker
//
//  Visual theme selector with preview icons for each appearance option.
//  Features animated selection and clear visual feedback.
//

import SwiftUI

/// Visual theme picker with preview icons
struct ThemePicker: View {
    @Bindable var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance")
                .font(.headline)
                .foregroundColor(.textPrimary)

            HStack(spacing: 12) {
                ForEach(AppColorScheme.allCases) { scheme in
                    ThemeOptionCard(
                        scheme: scheme,
                        isSelected: themeManager.selectedScheme == scheme,
                        onSelect: {
                            themeManager.setTheme(scheme)
                        }
                    )
                }
            }

            // Description text
            Text(themeManager.selectedScheme.description)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .neumorphicCard()
    }
}

/// Individual theme option card with icon preview
struct ThemeOptionCard: View {
    let scheme: AppColorScheme
    let isSelected: Bool
    let onSelect: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Preview icon showing the theme
                ThemePreviewIcon(scheme: scheme)
                    .frame(width: 64, height: 64)

                // Theme name
                Text(scheme.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .appAccent : .textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.appAccent.opacity(0.1) : Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.appAccent : Color.textSecondary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

/// Preview icon showing a mini device representation of the theme
struct ThemePreviewIcon: View {
    let scheme: AppColorScheme

    var body: some View {
        ZStack {
            // Device frame
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.textSecondary.opacity(0.3))

            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
                .padding(3)

            // Content representation
            VStack(spacing: 4) {
                // Header bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor)
                    .frame(height: 8)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)

                Spacer()

                // Content blocks
                VStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(cardColor)
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(cardColor)
                        .frame(height: 10)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }

            // System mode indicator (half and half)
            if scheme == .system {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: geometry.size.width / 2)

                        Rectangle()
                            .fill(Color.black.opacity(0.4))
                            .frame(width: geometry.size.width / 2)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(3)
            }

            // Icon overlay
            Image(systemName: scheme.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(6)
                .background(
                    Circle()
                        .fill(accentColor)
                        .shadow(color: accentColor.opacity(0.5), radius: 4, x: 0, y: 2)
                )
        }
    }

    private var backgroundColor: Color {
        switch scheme {
        case .system:
            return Color(red: 0.98, green: 0.96, blue: 0.92)
        case .light:
            return Color(red: 0.98, green: 0.96, blue: 0.92)
        case .dark:
            return Color(red: 0.12, green: 0.11, blue: 0.10)
        }
    }

    private var cardColor: Color {
        switch scheme {
        case .system, .light:
            return Color(red: 1.0, green: 0.99, blue: 0.97)
        case .dark:
            return Color(red: 0.18, green: 0.17, blue: 0.16)
        }
    }

    private var accentColor: Color {
        Color(red: 0.85, green: 0.55, blue: 0.45)
    }
}

/// Compact theme toggle button for toolbars
struct ThemeToggleButton: View {
    @Bindable var themeManager: ThemeManager

    var body: some View {
        Button {
            themeManager.cycleTheme()
        } label: {
            Image(systemName: themeManager.selectedScheme.icon)
                .font(.title3)
                .foregroundColor(.appAccent)
        }
        .accessibilityLabel("Toggle theme")
        .accessibilityHint("Current theme: \(themeManager.selectedScheme.rawValue)")
    }
}

/// Settings row style theme picker (for list context)
struct ThemePickerRow: View {
    @Bindable var themeManager: ThemeManager
    @State private var showingPicker = false

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            HStack {
                Image(systemName: themeManager.selectedScheme.icon)
                    .font(.body)
                    .foregroundColor(.appAccent)
                    .frame(width: 24)

                Text("Appearance")
                    .font(.body)
                    .foregroundColor(.textPrimary)

                Spacer()

                Text(themeManager.selectedScheme.rawValue)
                    .font(.body)
                    .foregroundColor(.textSecondary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.textMuted)
            }
        }
        .sheet(isPresented: $showingPicker) {
            ThemePickerSheet(themeManager: themeManager)
                .presentationDetents([.height(320)])
        }
    }
}

/// Sheet presentation for theme picker
struct ThemePickerSheet: View {
    @Bindable var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ThemePicker(themeManager: themeManager)
                    .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.top, 20)
            .background(WarmGradientBackground())
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Theme Picker") {
    VStack(spacing: 24) {
        ThemePicker(themeManager: ThemeManager.shared)
    }
    .padding()
    .background(WarmGradientBackground())
}

#Preview("Theme Options") {
    HStack(spacing: 16) {
        ForEach(AppColorScheme.allCases) { scheme in
            ThemePreviewIcon(scheme: scheme)
                .frame(width: 80, height: 80)
        }
    }
    .padding()
    .background(Color.appBackground)
}
