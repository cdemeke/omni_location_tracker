//
//  WatchConnectivityManager.swift
//  OmniSiteTracker
//
//  Apple Watch connectivity and data sync
//

import SwiftUI
import WatchConnectivity

@MainActor
@Observable
final class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()
    
    private(set) var isWatchPaired = false
    private(set) var isWatchAppInstalled = false
    private(set) var isReachable = false
    private(set) var lastSyncDate: Date?
    private(set) var pendingMessages: Int = 0
    
    private var session: WCSession?
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        guard WCSession.isSupported() else { return }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }
    
    func sendSiteLog(_ site: String, date: Date = Date()) {
        guard let session = session, session.isReachable else {
            pendingMessages += 1
            return
        }
        
        let message: [String: Any] = [
            "type": "siteLog",
            "site": site,
            "date": date.timeIntervalSince1970
        ]
        
        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send message: \(error.localizedDescription)")
        }
    }
    
    func syncAllData(placements: [PlacementLog]) {
        guard let session = session else { return }
        
        let data = placements.prefix(50).map { placement -> [String: Any] in
            [
                "site": placement.site,
                "date": placement.placedAt.timeIntervalSince1970
            ]
        }
        
        do {
            try session.updateApplicationContext(["placements": data])
            lastSyncDate = Date()
        } catch {
            print("Failed to sync: \(error.localizedDescription)")
        }
    }
    
    func requestWatchData() {
        guard let session = session, session.isReachable else { return }
        
        session.sendMessage(["type": "requestData"], replyHandler: { response in
            // Handle response from watch
            print("Received watch data: \(response)")
        }, errorHandler: { error in
            print("Failed to request data: \(error.localizedDescription)")
        })
    }
    
    func transferFile(_ fileURL: URL, metadata: [String: Any]? = nil) {
        session?.transferFile(fileURL, metadata: metadata)
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isWatchPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isReachable = session.isReachable
        }
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            handleReceivedMessage(message)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            handleReceivedMessage(message)
            replyHandler(["status": "received"])
        }
    }
    
    @MainActor
    private func handleReceivedMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }
        
        switch type {
        case "siteLog":
            if let site = message["site"] as? String {
                // Handle site log from watch
                NotificationCenter.default.post(
                    name: .watchDidLogSite,
                    object: nil,
                    userInfo: ["site": site]
                )
            }
        case "sync":
            lastSyncDate = Date()
        default:
            break
        }
    }
}

extension Notification.Name {
    static let watchDidLogSite = Notification.Name("watchDidLogSite")
}

struct WatchConnectivityView: View {
    @State private var manager = WatchConnectivityManager.shared
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "applewatch")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text("Apple Watch")
                            .font(.headline)
                        Text(statusText)
                            .font(.subheadline)
                            .foregroundStyle(statusColor)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Connection Status") {
                StatusRow(title: "Watch Paired", isActive: manager.isWatchPaired)
                StatusRow(title: "App Installed", isActive: manager.isWatchAppInstalled)
                StatusRow(title: "Reachable", isActive: manager.isReachable)
            }
            
            Section("Sync") {
                if let lastSync = manager.lastSyncDate {
                    LabeledContent("Last Sync", value: lastSync.formatted())
                } else {
                    LabeledContent("Last Sync", value: "Never")
                }
                
                if manager.pendingMessages > 0 {
                    LabeledContent("Pending Messages", value: "\(manager.pendingMessages)")
                }
                
                Button("Sync Now") {
                    // Would call syncAllData with actual placements
                }
                .disabled(!manager.isReachable)
            }
            
            Section("Test") {
                Button("Send Test Log") {
                    manager.sendSiteLog("Test Site")
                }
                .disabled(!manager.isReachable)
                
                Button("Request Watch Data") {
                    manager.requestWatchData()
                }
                .disabled(!manager.isReachable)
            }
            
            Section("Watch App Features") {
                Label("Quick site logging", systemImage: "plus.circle")
                Label("Complication support", systemImage: "clock.badge.checkmark")
                Label("Haptic feedback", systemImage: "hand.tap")
                Label("Glanceable history", systemImage: "list.bullet")
            }
        }
        .navigationTitle("Apple Watch")
    }
    
    var statusText: String {
        if !manager.isWatchPaired {
            return "No watch paired"
        } else if !manager.isWatchAppInstalled {
            return "Install watch app"
        } else if manager.isReachable {
            return "Connected"
        } else {
            return "Not reachable"
        }
    }
    
    var statusColor: Color {
        if manager.isReachable {
            return .green
        } else if manager.isWatchPaired {
            return .orange
        } else {
            return .secondary
        }
    }
}

struct StatusRow: View {
    let title: String
    let isActive: Bool
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isActive ? .green : .gray)
        }
    }
}

#Preview {
    NavigationStack {
        WatchConnectivityView()
    }
}
