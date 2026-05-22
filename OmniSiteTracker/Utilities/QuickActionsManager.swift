//
//  QuickActionsManager.swift
//  OmniSiteTracker
//
//  3D Touch / Haptic Touch quick actions from home screen.
//

import Foundation
import UIKit
import SwiftUI

@MainActor
@Observable
final class QuickActionsManager {
    static let shared = QuickActionsManager()
    
    enum ActionType: String {
        case logPlacement = "LogPlacement"
        case viewRecommendation = "ViewRecommendation"
        case viewHistory = "ViewHistory"
        case quickStats = "QuickStats"
    }
    
    var pendingAction: ActionType?
    
    private init() {}
    
    func setupQuickActions() {
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(
                type: ActionType.logPlacement.rawValue,
                localizedTitle: "Log Placement",
                localizedSubtitle: "Record a new site",
                icon: UIApplicationShortcutIcon(systemImageName: "plus.circle.fill")
            ),
            UIApplicationShortcutItem(
                type: ActionType.viewRecommendation.rawValue,
                localizedTitle: "Get Recommendation",
                localizedSubtitle: "See suggested site",
                icon: UIApplicationShortcutIcon(systemImageName: "star.fill")
            ),
            UIApplicationShortcutItem(
                type: ActionType.viewHistory.rawValue,
                localizedTitle: "View History",
                localizedSubtitle: "Recent placements",
                icon: UIApplicationShortcutIcon(systemImageName: "clock.fill")
            ),
            UIApplicationShortcutItem(
                type: ActionType.quickStats.rawValue,
                localizedTitle: "Quick Stats",
                localizedSubtitle: "Current streak",
                icon: UIApplicationShortcutIcon(systemImageName: "chart.bar.fill")
            )
        ]
    }
    
    func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let actionType = ActionType(rawValue: shortcutItem.type) else {
            return false
        }
        pendingAction = actionType
        return true
    }
}

struct QuickActionHandler: ViewModifier {
    @State private var quickActions = QuickActionsManager.shared
    @State private var showLogPlacement = false
    @State private var showRecommendation = false
    @State private var showHistory = false
    @State private var showStats = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                handlePendingAction()
            }
            .onChange(of: quickActions.pendingAction) { _, _ in
                handlePendingAction()
            }
            .sheet(isPresented: $showLogPlacement) {
                QuickLogSheet()
            }
            .sheet(isPresented: $showRecommendation) {
                QuickRecommendationSheet()
            }
            .sheet(isPresented: $showHistory) {
                QuickHistorySheet()
            }
            .sheet(isPresented: $showStats) {
                QuickStatsSheet()
            }
    }
    
    private func handlePendingAction() {
        guard let action = quickActions.pendingAction else { return }
        quickActions.pendingAction = nil
        
        switch action {
        case .logPlacement: showLogPlacement = true
        case .viewRecommendation: showRecommendation = true
        case .viewHistory: showHistory = true
        case .quickStats: showStats = true
        }
    }
}

struct QuickLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Quick Log")
                    .font(.title)
                // Add quick log UI
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct QuickRecommendationSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                Text("Recommended Site")
                    .font(.title2)
                
                Text("Abdomen Left")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Last used 21 days ago")
                    .foregroundColor(.secondary)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct QuickHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Text("Recent placements will appear here")
            }
            .navigationTitle("Recent History")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct QuickStatsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                VStack {
                    Text("7")
                        .font(.system(size: 80, weight: .bold))
                    Text("Day Streak")
                        .font(.title2)
                }
                
                HStack(spacing: 40) {
                    VStack {
                        Text("42")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Total Logs")
                            .font(.caption)
                    }
                    
                    VStack {
                        Text("8")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Sites Used")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Quick Stats")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

extension View {
    func handleQuickActions() -> some View {
        modifier(QuickActionHandler())
    }
}

#Preview {
    Text("Main App")
        .handleQuickActions()
}
