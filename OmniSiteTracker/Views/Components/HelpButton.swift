//
//  HelpButton.swift
//  OmniSiteTracker
//
//  A reusable help button for triggering contextual tooltips throughout the app.
//

import SwiftUI

/// Button style that provides a subtle scale animation on press
struct HelpButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// A reusable help button component for triggering contextual help tooltips
struct HelpButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 18))
                .foregroundColor(.textMuted)
        }
        .buttonStyle(HelpButtonStyle())
    }
}

// MARK: - Scroll Offset Tracking

/// Preference key to track scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    /// Tracks the vertical scroll offset of this view within a named coordinate space
    func trackScrollOffset(coordinateSpace: String) -> some View {
        self.overlay(
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geo.frame(in: .named(coordinateSpace)).minY
                    )
            }
        )
    }

    /// Responds to scroll offset changes
    func onScrollOffsetChange(perform action: @escaping (CGFloat) -> Void) -> some View {
        self.onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: action)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 20) {
        Text("Section Title")
            .font(.headline)
        HelpButton {
            print("Help tapped")
        }
    }
    .padding()
    .background(Color.appBackground)
}
