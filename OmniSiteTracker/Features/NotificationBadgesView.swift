//
//  NotificationBadgesView.swift
//  OmniSiteTracker
//
//  Customize app badge notifications
//

import SwiftUI
import UserNotifications

@MainActor
@Observable
final class BadgeManager {
    var badgeCount = 0
    var showPendingReminders = true
    var showOverdueCount = true
    var showAchievements = false
    
    func updateBadge() {
        var count = 0
        if showPendingReminders { count += 2 }
        if showOverdueCount { count += 1 }
        badgeCount = count
        
        UNUserNotificationCenter.current().setBadgeCount(count)
    }
    
    func clearBadge() {
        badgeCount = 0
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

struct NotificationBadgesView: View {
    @State private var manager = BadgeManager()
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Current Badge")
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(.red)
                            .frame(width: 30, height: 30)
                        Text("\(manager.badgeCount)")
                            .foregroundStyle(.white)
                            .font(.caption.bold())
                    }
                }
            }
            
            Section("Include in Badge Count") {
                Toggle("Pending Reminders", isOn: $manager.showPendingReminders)
                Toggle("Overdue Items", isOn: $manager.showOverdueCount)
                Toggle("New Achievements", isOn: $manager.showAchievements)
            }
            
            Section {
                Button("Update Badge") {
                    manager.updateBadge()
                }
                
                Button("Clear Badge", role: .destructive) {
                    manager.clearBadge()
                }
            }
        }
        .navigationTitle("App Badge")
        .onChange(of: manager.showPendingReminders) { _, _ in manager.updateBadge() }
        .onChange(of: manager.showOverdueCount) { _, _ in manager.updateBadge() }
        .onChange(of: manager.showAchievements) { _, _ in manager.updateBadge() }
    }
}

#Preview {
    NavigationStack {
        NotificationBadgesView()
    }
}
