//
//  QuickActionsMenuView.swift
//  OmniSiteTracker
//
//  Customizable quick actions
//

import SwiftUI

struct QuickAction: Identifiable {
    let id = UUID()
    var name: String
    var icon: String
    var action: ActionType
    var isEnabled: Bool
    
    enum ActionType: String, CaseIterable {
        case logSite = "Log Site"
        case viewHistory = "View History"
        case nextSuggestion = "Next Suggestion"
        case viewStats = "View Stats"
        case setReminder = "Set Reminder"
        case exportData = "Export Data"
    }
}

@MainActor
@Observable
final class QuickActionsManager {
    var actions: [QuickAction] = [
        QuickAction(name: "Quick Log", icon: "plus.circle.fill", action: .logSite, isEnabled: true),
        QuickAction(name: "History", icon: "clock.fill", action: .viewHistory, isEnabled: true),
        QuickAction(name: "Suggestion", icon: "lightbulb.fill", action: .nextSuggestion, isEnabled: true),
        QuickAction(name: "Stats", icon: "chart.bar.fill", action: .viewStats, isEnabled: false)
    ]
    
    var enabledActions: [QuickAction] {
        actions.filter { $0.isEnabled }
    }
}

struct QuickActionsMenuView: View {
    @State private var manager = QuickActionsManager()
    
    var body: some View {
        List {
            Section("Enabled Actions") {
                ForEach($manager.actions) { $action in
                    HStack {
                        Image(systemName: action.icon)
                            .foregroundStyle(.blue)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text(action.name)
                                .font(.headline)
                            Text(action.action.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $action.isEnabled)
                    }
                }
                .onMove { from, to in
                    manager.actions.move(fromOffsets: from, toOffset: to)
                }
            }
            
            Section("Preview") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(manager.enabledActions) { action in
                        VStack(spacing: 8) {
                            Image(systemName: action.icon)
                                .font(.title2)
                            Text(action.name)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Quick Actions")
        .toolbar {
            EditButton()
        }
    }
}

struct QuickActionsFloatingMenu: View {
    let actions: [QuickAction]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 12) {
            if isExpanded {
                ForEach(actions) { action in
                    Button {
                        // Perform action
                    } label: {
                        Image(systemName: action.icon)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(.blue)
                            .clipShape(Circle())
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(.blue)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
        }
    }
}

#Preview {
    NavigationStack {
        QuickActionsMenuView()
    }
}
