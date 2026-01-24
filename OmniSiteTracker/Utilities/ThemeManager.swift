//
//  ThemeManager.swift
//  OmniSiteTracker
//
//  Manages custom app themes with color customization.
//  Supports preset themes and user-created custom themes.
//

import SwiftUI
import Foundation

/// Represents a custom app theme
struct AppTheme: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var primaryColor: CodableColor
    var secondaryColor: CodableColor
    var accentColor: CodableColor
    var backgroundColor: CodableColor
    var cardColor: CodableColor
    var isBuiltIn: Bool = false

    static let defaultTheme = AppTheme(
        name: "Default",
        primaryColor: CodableColor(.primary),
        secondaryColor: CodableColor(.secondary),
        accentColor: CodableColor(.blue),
        backgroundColor: CodableColor(Color(uiColor: .systemBackground)),
        cardColor: CodableColor(Color(uiColor: .secondarySystemBackground)),
        isBuiltIn: true
    )

    static let presets: [AppTheme] = [
        defaultTheme,
        AppTheme(
            name: "Ocean",
            primaryColor: CodableColor(Color(hex: "1A535C")),
            secondaryColor: CodableColor(Color(hex: "4ECDC4")),
            accentColor: CodableColor(Color(hex: "FF6B6B")),
            backgroundColor: CodableColor(Color(hex: "F7FFF7")),
            cardColor: CodableColor(Color(hex: "FFFFFF")),
            isBuiltIn: true
        ),
        AppTheme(
            name: "Sunset",
            primaryColor: CodableColor(Color(hex: "2B2D42")),
            secondaryColor: CodableColor(Color(hex: "8D99AE")),
            accentColor: CodableColor(Color(hex: "EF233C")),
            backgroundColor: CodableColor(Color(hex: "EDF2F4")),
            cardColor: CodableColor(Color(hex: "FFFFFF")),
            isBuiltIn: true
        ),
        AppTheme(
            name: "Forest",
            primaryColor: CodableColor(Color(hex: "2D6A4F")),
            secondaryColor: CodableColor(Color(hex: "40916C")),
            accentColor: CodableColor(Color(hex: "95D5B2")),
            backgroundColor: CodableColor(Color(hex: "D8F3DC")),
            cardColor: CodableColor(Color(hex: "FFFFFF")),
            isBuiltIn: true
        ),
        AppTheme(
            name: "Midnight",
            primaryColor: CodableColor(Color(hex: "E0E0E0")),
            secondaryColor: CodableColor(Color(hex: "A0A0A0")),
            accentColor: CodableColor(Color(hex: "BB86FC")),
            backgroundColor: CodableColor(Color(hex: "121212")),
            cardColor: CodableColor(Color(hex: "1E1E1E")),
            isBuiltIn: true
        ),
        AppTheme(
            name: "Coral",
            primaryColor: CodableColor(Color(hex: "264653")),
            secondaryColor: CodableColor(Color(hex: "2A9D8F")),
            accentColor: CodableColor(Color(hex: "E76F51")),
            backgroundColor: CodableColor(Color(hex: "F4F1DE")),
            cardColor: CodableColor(Color(hex: "FFFFFF")),
            isBuiltIn: true
        )
    ]
}

/// Codable wrapper for Color
struct CodableColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    init(_ color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(a)
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

/// Manages app themes
@MainActor
@Observable
final class ThemeManager {
    // MARK: - Singleton

    static let shared = ThemeManager()

    // MARK: - Properties

    private(set) var currentTheme: AppTheme
    private(set) var customThemes: [AppTheme] = []

    private let defaults = UserDefaults.standard
    private let currentThemeKey = "currentTheme"
    private let customThemesKey = "customThemes"

    // MARK: - Initialization

    private init() {
        // Load current theme
        if let data = defaults.data(forKey: currentThemeKey),
           let theme = try? JSONDecoder().decode(AppTheme.self, from: data) {
            currentTheme = theme
        } else {
            currentTheme = AppTheme.defaultTheme
        }

        // Load custom themes
        if let data = defaults.data(forKey: customThemesKey),
           let themes = try? JSONDecoder().decode([AppTheme].self, from: data) {
            customThemes = themes
        }
    }

    // MARK: - Public Methods

    /// Sets the current theme
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        saveCurrentTheme()
    }

    /// Adds a custom theme
    func addCustomTheme(_ theme: AppTheme) {
        var newTheme = theme
        newTheme.isBuiltIn = false
        customThemes.append(newTheme)
        saveCustomThemes()
    }

    /// Updates a custom theme
    func updateCustomTheme(_ theme: AppTheme) {
        if let index = customThemes.firstIndex(where: { $0.id == theme.id }) {
            customThemes[index] = theme
            saveCustomThemes()

            if currentTheme.id == theme.id {
                currentTheme = theme
                saveCurrentTheme()
            }
        }
    }

    /// Deletes a custom theme
    func deleteCustomTheme(_ theme: AppTheme) {
        customThemes.removeAll { $0.id == theme.id }
        saveCustomThemes()

        if currentTheme.id == theme.id {
            currentTheme = AppTheme.defaultTheme
            saveCurrentTheme()
        }
    }

    /// Gets all available themes (presets + custom)
    var allThemes: [AppTheme] {
        AppTheme.presets + customThemes
    }

    // MARK: - Private Methods

    private func saveCurrentTheme() {
        if let data = try? JSONEncoder().encode(currentTheme) {
            defaults.set(data, forKey: currentThemeKey)
        }
    }

    private func saveCustomThemes() {
        if let data = try? JSONEncoder().encode(customThemes) {
            defaults.set(data, forKey: customThemesKey)
        }
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme Selector View

struct ThemeSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var themeManager = ThemeManager.shared
    @State private var showingEditor = false
    @State private var editingTheme: AppTheme?

    var body: some View {
        NavigationStack {
            List {
                // Preset themes
                Section("Preset Themes") {
                    ForEach(AppTheme.presets) { theme in
                        ThemeRow(theme: theme, isSelected: themeManager.currentTheme.id == theme.id) {
                            themeManager.setTheme(theme)
                        }
                    }
                }

                // Custom themes
                if !themeManager.customThemes.isEmpty {
                    Section("Custom Themes") {
                        ForEach(themeManager.customThemes) { theme in
                            ThemeRow(theme: theme, isSelected: themeManager.currentTheme.id == theme.id) {
                                themeManager.setTheme(theme)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    themeManager.deleteCustomTheme(theme)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    editingTheme = theme
                                    showingEditor = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }

                // Create new theme
                Section {
                    Button(action: {
                        editingTheme = nil
                        showingEditor = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("Create Custom Theme")
                        }
                    }
                }
            }
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                ThemeEditorView(theme: editingTheme)
            }
        }
    }
}

// MARK: - Theme Row

struct ThemeRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Color preview
                HStack(spacing: 4) {
                    Circle()
                        .fill(theme.primaryColor.color)
                        .frame(width: 20, height: 20)
                    Circle()
                        .fill(theme.accentColor.color)
                        .frame(width: 20, height: 20)
                    Circle()
                        .fill(theme.backgroundColor.color)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                }

                Text(theme.name)
                    .foregroundColor(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Theme Editor View

struct ThemeEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var themeManager = ThemeManager.shared

    @State private var themeName: String
    @State private var primaryColor: Color
    @State private var secondaryColor: Color
    @State private var accentColor: Color
    @State private var backgroundColor: Color
    @State private var cardColor: Color

    private let existingTheme: AppTheme?

    init(theme: AppTheme?) {
        existingTheme = theme
        _themeName = State(initialValue: theme?.name ?? "My Theme")
        _primaryColor = State(initialValue: theme?.primaryColor.color ?? .primary)
        _secondaryColor = State(initialValue: theme?.secondaryColor.color ?? .secondary)
        _accentColor = State(initialValue: theme?.accentColor.color ?? .blue)
        _backgroundColor = State(initialValue: theme?.backgroundColor.color ?? Color(uiColor: .systemBackground))
        _cardColor = State(initialValue: theme?.cardColor.color ?? Color(uiColor: .secondarySystemBackground))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Theme Name") {
                    TextField("Name", text: $themeName)
                }

                Section("Colors") {
                    ColorPicker("Primary", selection: $primaryColor)
                    ColorPicker("Secondary", selection: $secondaryColor)
                    ColorPicker("Accent", selection: $accentColor)
                    ColorPicker("Background", selection: $backgroundColor)
                    ColorPicker("Card", selection: $cardColor)
                }

                Section("Preview") {
                    ThemePreview(
                        primary: primaryColor,
                        secondary: secondaryColor,
                        accent: accentColor,
                        background: backgroundColor,
                        card: cardColor
                    )
                }
            }
            .navigationTitle(existingTheme == nil ? "New Theme" : "Edit Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTheme()
                        dismiss()
                    }
                    .disabled(themeName.isEmpty)
                }
            }
        }
    }

    private func saveTheme() {
        let theme = AppTheme(
            id: existingTheme?.id ?? UUID(),
            name: themeName,
            primaryColor: CodableColor(primaryColor),
            secondaryColor: CodableColor(secondaryColor),
            accentColor: CodableColor(accentColor),
            backgroundColor: CodableColor(backgroundColor),
            cardColor: CodableColor(cardColor),
            isBuiltIn: false
        )

        if existingTheme != nil {
            themeManager.updateCustomTheme(theme)
        } else {
            themeManager.addCustomTheme(theme)
        }
    }
}

// MARK: - Theme Preview

struct ThemePreview: View {
    let primary: Color
    let secondary: Color
    let accent: Color
    let background: Color
    let card: Color

    var body: some View {
        VStack(spacing: 12) {
            // Sample card
            VStack(alignment: .leading, spacing: 8) {
                Text("Sample Card")
                    .font(.headline)
                    .foregroundColor(primary)

                Text("This is how your content will look")
                    .font(.subheadline)
                    .foregroundColor(secondary)

                Button("Action Button") { }
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(accent)
                    .cornerRadius(8)
            }
            .padding()
            .background(card)
            .cornerRadius(12)
        }
        .padding()
        .background(background)
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview {
    ThemeSelectorView()
}
