//
//  AccessibilityManager.swift
//  OmniSiteTracker
//
//  Manages accessibility features and preferences.
//  Provides VoiceOver support, dynamic type, and reduced motion options.
//

import Foundation
import SwiftUI
import Combine

/// Manages app-wide accessibility settings and features
@MainActor
@Observable
final class AccessibilityManager {
    // MARK: - Singleton

    static let shared = AccessibilityManager()

    // MARK: - System Accessibility State

    /// Whether VoiceOver is currently running
    var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }

    /// Whether the user prefers reduced motion
    var prefersReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    /// Whether the user prefers reduced transparency
    var prefersReducedTransparency: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }

    /// Whether bold text is enabled
    var isBoldTextEnabled: Bool {
        UIAccessibility.isBoldTextEnabled
    }

    /// Whether differentiate without color is enabled
    var differentiateWithoutColor: Bool {
        UIAccessibility.shouldDifferentiateWithoutColor
    }

    // MARK: - App Accessibility Preferences

    /// Whether to show text alternatives for icons
    @AppStorage("accessibility_showIconLabels") var showIconLabels: Bool = false

    /// Whether to use larger touch targets
    @AppStorage("accessibility_largerTouchTargets") var useLargerTouchTargets: Bool = false

    /// Whether to use high contrast mode
    @AppStorage("accessibility_highContrast") var useHighContrast: Bool = false

    /// Whether to announce placement confirmations
    @AppStorage("accessibility_announceConfirmations") var announceConfirmations: Bool = true

    // MARK: - Initialization

    private init() {
        // Register for accessibility notifications
        setupNotifications()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.objectWillChange.send()
        }

        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    // MARK: - Accessibility Announcements

    /// Makes a VoiceOver announcement
    /// - Parameter message: The message to announce
    func announce(_ message: String) {
        guard isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    /// Announces screen changes
    /// - Parameter message: The screen change message
    func announceScreenChange(_ message: String) {
        guard isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .screenChanged, argument: message)
    }

    /// Announces placement confirmation if enabled
    /// - Parameters:
    ///   - location: The placement location
    ///   - isRecommended: Whether this was the recommended site
    func announcePlacementConfirmed(location: String, isRecommended: Bool) {
        guard announceConfirmations else { return }

        var message = "Placement logged at \(location)."
        if isRecommended {
            message += " This was the recommended site."
        }

        announce(message)
    }

    // MARK: - Accessibility Helpers

    /// Returns the recommended minimum touch target size
    var minimumTouchTargetSize: CGFloat {
        useLargerTouchTargets ? 60 : 44
    }

    /// Returns animation duration based on reduced motion preference
    var animationDuration: Double {
        prefersReducedMotion ? 0 : 0.3
    }

    /// Returns whether to use animations
    var shouldAnimate: Bool {
        !prefersReducedMotion
    }
}

// MARK: - View Extensions

extension View {
    /// Applies accessibility-aware touch target sizing
    func accessibleTouchTarget() -> some View {
        self.frame(
            minWidth: AccessibilityManager.shared.minimumTouchTargetSize,
            minHeight: AccessibilityManager.shared.minimumTouchTargetSize
        )
    }

    /// Applies accessibility-aware animation
    func accessibleAnimation<V: Equatable>(_ animation: Animation? = .default, value: V) -> some View {
        self.animation(
            AccessibilityManager.shared.shouldAnimate ? animation : nil,
            value: value
        )
    }

    /// Adds a label for VoiceOver alongside an icon
    func iconWithLabel(_ label: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)

            if AccessibilityManager.shared.showIconLabels {
                Text(label)
                    .font(.caption)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }

    /// Makes a view more accessible with custom label and hint
    func accessibleElement(label: String, hint: String? = nil, traits: AccessibilityTraits = []) -> some View {
        self.accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }

    /// Adds high contrast border if enabled
    func highContrastBorder() -> some View {
        self.overlay(
            AccessibilityManager.shared.useHighContrast
                ? RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary, lineWidth: 2)
                : nil
        )
    }
}

// MARK: - Accessible Data Representations

/// Provides accessible text descriptions for placement data
struct AccessiblePlacementDescription {
    let placement: PlacementLog
    let minimumRestDays: Int

    /// Full description for VoiceOver
    var fullDescription: String {
        var description = "\(locationName) placement on \(dateDescription)."

        if let days = daysSincePlacement {
            description += " \(days) days ago."
            if days < minimumRestDays {
                description += " This site is still resting."
            } else {
                description += " This site is ready for use."
            }
        }

        if let note = placement.note, !note.isEmpty {
            description += " Note: \(note)"
        }

        return description
    }

    /// Short description for list items
    var shortDescription: String {
        "\(locationName), \(relativeDateDescription)"
    }

    private var locationName: String {
        placement.locationRawValue ?? placement.customSiteName ?? "Unknown location"
    }

    private var dateDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: placement.placedAt)
    }

    private var relativeDateDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: placement.placedAt, relativeTo: .now)
    }

    private var daysSincePlacement: Int? {
        Calendar.current.dateComponents([.day], from: placement.placedAt, to: .now).day
    }
}

/// Accessible representation of site status
struct AccessibleSiteStatus {
    let siteName: String
    let daysSinceUse: Int?
    let minimumRestDays: Int
    let isCustomSite: Bool

    /// Full description for VoiceOver
    var description: String {
        var text = siteName

        if isCustomSite {
            text += ", custom site"
        }

        if let days = daysSinceUse {
            text += ". Last used \(days) days ago."

            if days < minimumRestDays {
                let remaining = minimumRestDays - days
                text += " Needs \(remaining) more days of rest."
            } else {
                text += " Ready to use."
            }
        } else {
            text += ". Never used before. Ready for first placement."
        }

        return text
    }

    /// Status for color-blind users
    var statusText: String {
        if let days = daysSinceUse {
            if days >= minimumRestDays {
                return "Ready"
            } else {
                return "Resting"
            }
        }
        return "Available"
    }
}

// MARK: - UIKit Integration

import UIKit

extension UIAccessibility {
    /// Checks if VoiceOver or other screen reader is running
    static var isScreenReaderRunning: Bool {
        isVoiceOverRunning || isSwitchControlRunning
    }
}
