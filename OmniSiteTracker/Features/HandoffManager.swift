//
//  HandoffManager.swift
//  OmniSiteTracker
//
//  Handoff support for seamless device transitions
//

import SwiftUI

struct HandoffActivity {
    static let logSite = "com.omnitracker.activity.logsite"
    static let viewHistory = "com.omnitracker.activity.viewhistory"
    static let viewStats = "com.omnitracker.activity.viewstats"
    static let editSettings = "com.omnitracker.activity.editsettings"
}

@MainActor
@Observable
final class HandoffManager {
    static let shared = HandoffManager()
    
    private(set) var currentActivity: NSUserActivity?
    private(set) var receivedActivity: NSUserActivity?
    private(set) var isHandoffAvailable = true
    
    func startLogSiteActivity(site: String? = nil) {
        let activity = NSUserActivity(activityType: HandoffActivity.logSite)
        activity.title = "Log Site"
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        
        if let site = site {
            activity.userInfo = ["selectedSite": site]
        }
        
        activity.becomeCurrent()
        currentActivity = activity
    }
    
    func startViewHistoryActivity(dateRange: String? = nil) {
        let activity = NSUserActivity(activityType: HandoffActivity.viewHistory)
        activity.title = "View History"
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = true
        
        if let dateRange = dateRange {
            activity.userInfo = ["dateRange": dateRange]
        }
        
        activity.becomeCurrent()
        currentActivity = activity
    }
    
    func startViewStatsActivity() {
        let activity = NSUserActivity(activityType: HandoffActivity.viewStats)
        activity.title = "View Statistics"
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = true
        
        activity.becomeCurrent()
        currentActivity = activity
    }
    
    func startEditSettingsActivity() {
        let activity = NSUserActivity(activityType: HandoffActivity.editSettings)
        activity.title = "Edit Settings"
        activity.isEligibleForHandoff = true
        
        activity.becomeCurrent()
        currentActivity = activity
    }
    
    func stopCurrentActivity() {
        currentActivity?.invalidate()
        currentActivity = nil
    }
    
    func handleIncomingActivity(_ activity: NSUserActivity) -> HandoffDestination? {
        receivedActivity = activity
        
        switch activity.activityType {
        case HandoffActivity.logSite:
            let site = activity.userInfo?["selectedSite"] as? String
            return .logSite(preselectedSite: site)
            
        case HandoffActivity.viewHistory:
            let dateRange = activity.userInfo?["dateRange"] as? String
            return .history(dateRange: dateRange)
            
        case HandoffActivity.viewStats:
            return .statistics
            
        case HandoffActivity.editSettings:
            return .settings
            
        default:
            return nil
        }
    }
}

enum HandoffDestination: Equatable {
    case logSite(preselectedSite: String?)
    case history(dateRange: String?)
    case statistics
    case settings
}

struct HandoffSettingsView: View {
    @State private var manager = HandoffManager.shared
    @State private var enableHandoff = true
    @State private var enablePrediction = true
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text("Handoff")
                            .font(.headline)
                        Text("Continue on other devices")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Settings") {
                Toggle("Enable Handoff", isOn: $enableHandoff)
                Toggle("Siri Suggestions", isOn: $enablePrediction)
            }
            
            Section("Current Activity") {
                if let activity = manager.currentActivity {
                    LabeledContent("Type", value: activity.activityType.components(separatedBy: ".").last ?? "Unknown")
                    LabeledContent("Title", value: activity.title ?? "None")
                    LabeledContent("Handoff", value: activity.isEligibleForHandoff ? "Enabled" : "Disabled")
                } else {
                    Text("No active activity")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Supported Activities") {
                ActivityRow(title: "Log Site", description: "Continue site logging", icon: "plus.circle")
                ActivityRow(title: "View History", description: "Continue browsing history", icon: "clock")
                ActivityRow(title: "View Statistics", description: "Continue viewing stats", icon: "chart.bar")
                ActivityRow(title: "Edit Settings", description: "Continue adjusting settings", icon: "gear")
            }
            
            Section("How It Works") {
                Label("Sign in with same Apple ID", systemImage: "person.circle")
                Label("Enable Handoff in System Settings", systemImage: "gear")
                Label("Look for app icon in Dock", systemImage: "dock.rectangle")
                Label("Swipe up on Lock Screen", systemImage: "arrow.up.circle")
            }
            
            Section("Test") {
                Button("Start Log Site Activity") {
                    manager.startLogSiteActivity(site: "Abdomen - Left")
                }
                
                Button("Start History Activity") {
                    manager.startViewHistoryActivity(dateRange: "30 days")
                }
                
                Button("Stop Current Activity") {
                    manager.stopCurrentActivity()
                }
                .disabled(manager.currentActivity == nil)
            }
        }
        .navigationTitle("Handoff")
    }
}

struct ActivityRow: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// View modifier for automatic Handoff
struct HandoffModifier: ViewModifier {
    let activityType: String
    let title: String
    let userInfo: [String: Any]?
    
    func body(content: Content) -> some View {
        content
            .userActivity(activityType) { activity in
                activity.title = title
                activity.isEligibleForHandoff = true
                activity.isEligibleForSearch = true
                if let info = userInfo {
                    activity.userInfo = info
                }
            }
    }
}

extension View {
    func handoff(_ activityType: String, title: String, userInfo: [String: Any]? = nil) -> some View {
        modifier(HandoffModifier(activityType: activityType, title: title, userInfo: userInfo))
    }
}

#Preview {
    NavigationStack {
        HandoffSettingsView()
    }
}
