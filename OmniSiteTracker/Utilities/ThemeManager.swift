//
//  ThemeManager.swift
//  OmniSiteTracker
//
//  Manages app-wide theme state and user preferences.
//  Uses @Observable for SwiftUI integration and persists to UserDefaults.
//

import SwiftUI

/// Global theme manager for handling app appearance
@Observable
final class ThemeManager {
    /// Singleton instance for app-wide access
    static let shared = ThemeManager()

    /// UserDefaults key for storing theme preference
    private let themePreferenceKey = "appColorScheme"

    /// Current user-selected color scheme preference
    var selectedScheme: AppColorScheme {
        didSet {
            savePreference()
        }
    }

    /// The actual ColorScheme to apply (nil means follow system)
    var currentColorScheme: ColorScheme? {
        selectedScheme.colorScheme
    }

    /// Initialize with saved preference or default to system
    private init() {
        if let savedValue = UserDefaults.standard.string(forKey: themePreferenceKey),
           let scheme = AppColorScheme(rawValue: savedValue) {
            self.selectedScheme = scheme
        } else {
            self.selectedScheme = .system
        }
    }

    /// Save current preference to UserDefaults
    private func savePreference() {
        UserDefaults.standard.set(selectedScheme.rawValue, forKey: themePreferenceKey)
    }

    /// Set theme with animation
    func setTheme(_ scheme: AppColorScheme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedScheme = scheme
        }
    }

    /// Cycle through themes (useful for quick toggle)
    func cycleTheme() {
        let allCases = AppColorScheme.allCases
        guard let currentIndex = allCases.firstIndex(of: selectedScheme) else { return }
        let nextIndex = (currentIndex + 1) % allCases.count
        setTheme(allCases[nextIndex])
    }

    /// Check if currently in dark mode (considering system setting)
    func isDarkMode(in environment: ColorScheme) -> Bool {
        switch selectedScheme {
        case .system:
            return environment == .dark
        case .light:
            return false
        case .dark:
            return true
        }
    }
}

// MARK: - Environment Key

private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - View Extension for Theme Application

extension View {
    /// Applies the current theme preference to the view hierarchy
    func applyTheme() -> some View {
        modifier(ThemeModifier())
    }
}

/// View modifier that applies theme preference
struct ThemeModifier: ViewModifier {
    @State private var themeManager = ThemeManager.shared

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.currentColorScheme)
            .environment(\.themeManager, themeManager)
    }
}
