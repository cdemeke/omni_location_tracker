//
//  MacCatalystSupport.swift
//  OmniSiteTracker
//
//  Mac Catalyst support for desktop experience
//

import SwiftUI

#if targetEnvironment(macCatalyst)
import AppKit

@MainActor
@Observable
final class MacCatalystManager {
    static let shared = MacCatalystManager()
    
    private(set) var windowSize: CGSize = .zero
    private(set) var isFullScreen = false
    private(set) var toolbarStyle: ToolbarStyle = .automatic
    
    enum ToolbarStyle: String, CaseIterable {
        case automatic = "Automatic"
        case expanded = "Expanded"
        case compact = "Compact"
        case unified = "Unified"
    }
    
    func configureWindow(_ scene: UIWindowScene) {
        guard let window = scene.windows.first else { return }
        
        // Set minimum and maximum window size
        scene.sizeRestrictions?.minimumSize = CGSize(width: 800, height: 600)
        scene.sizeRestrictions?.maximumSize = CGSize(width: 1920, height: 1200)
        
        // Configure title bar
        if let titlebar = scene.titlebar {
            titlebar.titleVisibility = .visible
            titlebar.toolbarStyle = .unified
        }
        
        windowSize = window.frame.size
    }
    
    func toggleFullScreen() {
        isFullScreen.toggle()
    }
    
    func setToolbarStyle(_ style: ToolbarStyle) {
        toolbarStyle = style
    }
}
#endif

struct MacCatalystSettingsView: View {
    #if targetEnvironment(macCatalyst)
    @State private var manager = MacCatalystManager.shared
    #endif
    
    @State private var enableKeyboardShortcuts = true
    @State private var enableMenuBar = true
    @State private var enableTouchBar = true
    @State private var windowBehavior = "Remember"
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "macbook")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text("Mac Catalyst")
                            .font(.headline)
                        Text(isMacCatalyst ? "Running on Mac" : "iOS Device")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Window") {
                Picker("Window Behavior", selection: $windowBehavior) {
                    Text("Remember Size").tag("Remember")
                    Text("Default Size").tag("Default")
                    Text("Full Screen").tag("FullScreen")
                }
                
                #if targetEnvironment(macCatalyst)
                LabeledContent("Current Size") {
                    Text("\(Int(manager.windowSize.width)) × \(Int(manager.windowSize.height))")
                }
                
                Picker("Toolbar Style", selection: .constant(manager.toolbarStyle)) {
                    ForEach(MacCatalystManager.ToolbarStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                #endif
            }
            
            Section("Input") {
                Toggle("Keyboard Shortcuts", isOn: $enableKeyboardShortcuts)
                Toggle("Menu Bar Items", isOn: $enableMenuBar)
                Toggle("Touch Bar Support", isOn: $enableTouchBar)
            }
            
            Section("Keyboard Shortcuts") {
                ShortcutRow(key: "⌘N", action: "New Site Log")
                ShortcutRow(key: "⌘,", action: "Preferences")
                ShortcutRow(key: "⌘E", action: "Export Data")
                ShortcutRow(key: "⌘F", action: "Search")
                ShortcutRow(key: "⌘1", action: "Dashboard")
                ShortcutRow(key: "⌘2", action: "History")
                ShortcutRow(key: "⌘3", action: "Analytics")
            }
            
            Section("Menu Bar") {
                Label("File → New Site Log", systemImage: "doc.badge.plus")
                Label("Edit → Undo/Redo", systemImage: "arrow.uturn.backward")
                Label("View → Sidebar", systemImage: "sidebar.left")
                Label("Window → Full Screen", systemImage: "arrow.up.left.and.arrow.down.right")
            }
        }
        .navigationTitle("Mac Settings")
    }
    
    var isMacCatalyst: Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return false
        #endif
    }
}

struct ShortcutRow: View {
    let key: String
    let action: String
    
    var body: some View {
        HStack {
            Text(action)
            Spacer()
            Text(key)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .cornerRadius(4)
        }
    }
}

// Mac-specific sidebar view
struct MacSidebarView: View {
    @Binding var selectedTab: String
    
    let tabs = [
        ("Dashboard", "house.fill"),
        ("Log Site", "plus.circle.fill"),
        ("History", "clock.fill"),
        ("Analytics", "chart.bar.fill"),
        ("Settings", "gear")
    ]
    
    var body: some View {
        List(selection: $selectedTab) {
            Section("Navigation") {
                ForEach(tabs, id: \.0) { tab in
                    Label(tab.0, systemImage: tab.1)
                        .tag(tab.0)
                }
            }
            
            Section("Quick Actions") {
                Button {
                    // Quick log action
                } label: {
                    Label("Quick Log", systemImage: "bolt.fill")
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button {
                    // Export action
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .keyboardShortcut("e", modifiers: .command)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
    }
}

// Touch Bar support
struct TouchBarView: View {
    var body: some View {
        HStack {
            Button("Log Site") {}
            Button("History") {}
            Button("Stats") {}
        }
    }
}

#Preview {
    NavigationStack {
        MacCatalystSettingsView()
    }
}
