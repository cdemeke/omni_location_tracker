//
//  ContentView.swift
//  OmniSiteTracker
//
//  Root view containing tab navigation between Home and History screens.
//

import SwiftUI

/// Root content view with tab-based navigation
struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(1)

            PatternsView()
                .tabItem {
                    Label("Patterns", systemImage: "chart.bar.doc.horizontal")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.appAccent)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: PlacementLog.self, inMemory: true)
}
