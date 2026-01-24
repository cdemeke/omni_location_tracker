//
//  ContextualHelpView.swift
//  OmniSiteTracker
//
//  Context-aware help tooltips
//

import SwiftUI

struct HelpTooltip: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let screen: String
}

@MainActor
@Observable
final class ContextualHelpManager {
    var isEnabled = true
    var shownTooltips: Set<String> = []
    
    private let tooltips: [HelpTooltip] = [
        HelpTooltip(title: "Quick Tip", message: "Tap the + button to log a new site placement.", screen: "home"),
        HelpTooltip(title: "Site Selection", message: "Choose from your available sites or add new ones.", screen: "logEntry"),
        HelpTooltip(title: "History View", message: "Swipe left on any entry to delete it.", screen: "history"),
        HelpTooltip(title: "Analytics", message: "View your rotation patterns and statistics here.", screen: "analytics")
    ]
    
    func tooltip(for screen: String) -> HelpTooltip? {
        guard isEnabled else { return nil }
        guard !shownTooltips.contains(screen) else { return nil }
        return tooltips.first { $0.screen == screen }
    }
    
    func markShown(_ screen: String) {
        shownTooltips.insert(screen)
    }
    
    func resetAll() {
        shownTooltips.removeAll()
    }
}

struct ContextualHelpView: View {
    @State private var manager = ContextualHelpManager()
    
    var body: some View {
        List {
            Section {
                Toggle("Show Help Tips", isOn: $manager.isEnabled)
            } footer: {
                Text("Display helpful tooltips as you navigate the app.")
            }
            
            Section("Shown Tips") {
                if manager.shownTooltips.isEmpty {
                    Text("No tips shown yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(manager.shownTooltips), id: \.self) { screen in
                        Text(screen.capitalized)
                    }
                }
            }
            
            Section {
                Button("Reset All Tips") {
                    manager.resetAll()
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Help Tips")
    }
}

struct TooltipModifier: ViewModifier {
    let tooltip: HelpTooltip?
    let onDismiss: () -> Void
    
    @State private var isShowing = false
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let tooltip = tooltip, isShowing {
                    VStack(spacing: 8) {
                        Text(tooltip.title)
                            .font(.headline)
                        Text(tooltip.message)
                            .font(.subheadline)
                        Button("Got it") {
                            isShowing = false
                            onDismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 10)
                    .padding()
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .onAppear {
                if tooltip != nil {
                    withAnimation(.spring(response: 0.3)) {
                        isShowing = true
                    }
                }
            }
    }
}

#Preview {
    NavigationStack {
        ContextualHelpView()
    }
}
