//
//  KeyboardShortcutsView.swift
//  OmniSiteTracker
//
//  Keyboard shortcuts for iPad and Mac
//

import SwiftUI

struct KeyboardShortcut: Identifiable {
    let id = UUID()
    let keys: String
    let action: String
    let category: String
}

struct KeyboardShortcutsView: View {
    private let shortcuts: [KeyboardShortcut] = [
        KeyboardShortcut(keys: "⌘ N", action: "New Log Entry", category: "Logging"),
        KeyboardShortcut(keys: "⌘ S", action: "Save Current", category: "Logging"),
        KeyboardShortcut(keys: "⌘ ⇧ N", action: "Next Site Suggestion", category: "Navigation"),
        KeyboardShortcut(keys: "⌘ H", action: "View History", category: "Navigation"),
        KeyboardShortcut(keys: "⌘ ,", action: "Open Settings", category: "General"),
        KeyboardShortcut(keys: "⌘ /", action: "Show Shortcuts", category: "General"),
        KeyboardShortcut(keys: "⌘ E", action: "Export Data", category: "Data"),
        KeyboardShortcut(keys: "⌘ I", action: "Import Data", category: "Data")
    ]
    
    private var groupedShortcuts: [String: [KeyboardShortcut]] {
        Dictionary(grouping: shortcuts, by: { $0.category })
    }
    
    var body: some View {
        List {
            ForEach(groupedShortcuts.keys.sorted(), id: \.self) { category in
                Section(category) {
                    ForEach(groupedShortcuts[category] ?? []) { shortcut in
                        HStack {
                            Text(shortcut.action)
                            Spacer()
                            Text(shortcut.keys)
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.secondary.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
        }
        .navigationTitle("Keyboard Shortcuts")
    }
}

#Preview {
    NavigationStack {
        KeyboardShortcutsView()
    }
}
