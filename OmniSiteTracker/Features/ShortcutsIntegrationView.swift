//
//  ShortcutsIntegrationView.swift
//  OmniSiteTracker
//
//  Siri Shortcuts integration for quick actions
//

import SwiftUI
import Intents

struct ShortcutItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let iconName: String
    let phrase: String
}

@MainActor
@Observable
final class ShortcutsManager {
    static let shared = ShortcutsManager()
    
    private(set) var availableShortcuts: [ShortcutItem] = [
        ShortcutItem(title: "Log Site Change", subtitle: "Record a new site rotation", iconName: "plus.circle", phrase: "Log my Omnipod site"),
        ShortcutItem(title: "Check Current Site", subtitle: "View active site info", iconName: "mappin.circle", phrase: "Where is my Omnipod"),
        ShortcutItem(title: "Site History", subtitle: "Review recent rotations", iconName: "clock", phrase: "Show site history"),
        ShortcutItem(title: "Next Reminder", subtitle: "When to rotate next", iconName: "bell", phrase: "When should I rotate"),
        ShortcutItem(title: "Quick Stats", subtitle: "Usage statistics", iconName: "chart.bar", phrase: "My Omnipod stats")
    ]
    
    private(set) var donatedShortcuts: Set<String> = []
    
    func donateShortcut(_ shortcut: ShortcutItem) {
        donatedShortcuts.insert(shortcut.id.uuidString)
        // In production, use INInteraction to donate
    }
    
    func removeShortcut(_ shortcut: ShortcutItem) {
        donatedShortcuts.remove(shortcut.id.uuidString)
    }
}

struct ShortcutsIntegrationView: View {
    @State private var manager = ShortcutsManager.shared
    @State private var showingAddSheet = false
    @State private var selectedShortcut: ShortcutItem?
    
    var body: some View {
        List {
            Section {
                ForEach(manager.availableShortcuts) { shortcut in
                    ShortcutRow(shortcut: shortcut, isAdded: manager.donatedShortcuts.contains(shortcut.id.uuidString)) {
                        selectedShortcut = shortcut
                        showingAddSheet = true
                    }
                }
            } header: {
                Text("Available Shortcuts")
            } footer: {
                Text("Add shortcuts to Siri for quick voice commands")
            }
            
            Section("Tips") {
                Label("Say \"Hey Siri\" followed by your phrase", systemImage: "waveform")
                Label("Customize phrases in the Shortcuts app", systemImage: "gear")
                Label("Create automations with site changes", systemImage: "bolt.fill")
            }
        }
        .navigationTitle("Siri Shortcuts")
        .sheet(item: $selectedShortcut) { shortcut in
            AddShortcutSheet(shortcut: shortcut, manager: manager)
        }
    }
}

struct ShortcutRow: View {
    let shortcut: ShortcutItem
    let isAdded: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: shortcut.iconName)
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading) {
                    Text(shortcut.title)
                        .font(.headline)
                    Text(shortcut.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isAdded {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct AddShortcutSheet: View {
    let shortcut: ShortcutItem
    let manager: ShortcutsManager
    @Environment(\.dismiss) private var dismiss
    @State private var customPhrase: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Shortcut") {
                    HStack {
                        Image(systemName: shortcut.iconName)
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text(shortcut.title)
                                .font(.headline)
                            Text(shortcut.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Siri Phrase") {
                    TextField("Custom phrase", text: $customPhrase)
                    Text("Suggested: \"\(shortcut.phrase)\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    Button("Add to Siri") {
                        manager.donateShortcut(shortcut)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Add Shortcut")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                customPhrase = shortcut.phrase
            }
        }
    }
}

#Preview {
    NavigationStack {
        ShortcutsIntegrationView()
    }
}
