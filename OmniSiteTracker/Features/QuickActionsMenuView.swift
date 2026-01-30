//
//  QuickActionsMenuView.swift
//  OmniSiteTracker
//
//  Quick actions menu for fast access to common tasks
//

import SwiftUI
import UIKit

@MainActor
@Observable
final class QuickActionsManager {
    static let shared = QuickActionsManager()
    
    private(set) var recentActions: [String] = []
    private(set) var favoriteActions: Set<String> = []
    
    init() {
        loadPreferences()
        setupShortcutItems()
    }
    
    func setupShortcutItems() {
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(type: "com.omnitracker.logsite", localizedTitle: "Log Site", localizedSubtitle: "Record rotation", icon: UIApplicationShortcutIcon(systemImageName: "plus.circle"), userInfo: nil),
            UIApplicationShortcutItem(type: "com.omnitracker.history", localizedTitle: "History", localizedSubtitle: "View past rotations", icon: UIApplicationShortcutIcon(systemImageName: "clock"), userInfo: nil),
            UIApplicationShortcutItem(type: "com.omnitracker.stats", localizedTitle: "Statistics", localizedSubtitle: "View analytics", icon: UIApplicationShortcutIcon(systemImageName: "chart.bar"), userInfo: nil)
        ]
    }
    
    func handleShortcut(_ item: UIApplicationShortcutItem) -> QuickActionType? {
        switch item.type {
        case "com.omnitracker.logsite": recordAction("Log Site"); return .logSite
        case "com.omnitracker.history": recordAction("History"); return .history
        case "com.omnitracker.stats": recordAction("Statistics"); return .statistics
        default: return nil
        }
    }
    
    func recordAction(_ title: String) {
        recentActions.removeAll { $0 == title }
        recentActions.insert(title, at: 0)
        if recentActions.count > 5 { recentActions = Array(recentActions.prefix(5)) }
        savePreferences()
    }
    
    func toggleFavorite(_ title: String) {
        if favoriteActions.contains(title) { favoriteActions.remove(title) }
        else { favoriteActions.insert(title) }
        savePreferences()
    }
    
    private func loadPreferences() {
        recentActions = UserDefaults.standard.stringArray(forKey: "recent_actions") ?? []
        favoriteActions = Set(UserDefaults.standard.stringArray(forKey: "favorite_actions") ?? [])
    }
    
    private func savePreferences() {
        UserDefaults.standard.set(recentActions, forKey: "recent_actions")
        UserDefaults.standard.set(Array(favoriteActions), forKey: "favorite_actions")
    }
}

enum QuickActionType { case logSite, history, statistics, settings }

struct QuickActionsMenuView: View {
    @State private var manager = QuickActionsManager.shared
    let actions = [("Log Site", "plus.circle", QuickActionType.logSite), ("History", "clock", QuickActionType.history), ("Statistics", "chart.bar", QuickActionType.statistics), ("Settings", "gear", QuickActionType.settings)]
    
    var body: some View {
        List {
            Section("Quick Actions") {
                ForEach(actions, id: \.0) { action in
                    HStack {
                        Image(systemName: action.1).foregroundStyle(.blue).frame(width: 30)
                        Text(action.0)
                        Spacer()
                        Button { manager.toggleFavorite(action.0) } label: {
                            Image(systemName: manager.favoriteActions.contains(action.0) ? "star.fill" : "star")
                                .foregroundStyle(manager.favoriteActions.contains(action.0) ? .yellow : .gray)
                        }.buttonStyle(.plain)
                    }
                }
            }
            
            if !manager.recentActions.isEmpty {
                Section("Recent") {
                    ForEach(manager.recentActions, id: \.self) { action in
                        Text(action).foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Home Screen Shortcuts") {
                Label("Long press app icon to access", systemImage: "hand.tap")
                Label("Customize in Settings", systemImage: "gear")
            }
        }
        .navigationTitle("Quick Actions")
    }
}

#Preview { NavigationStack { QuickActionsMenuView() } }
