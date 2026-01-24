//
//  OmniSiteWatchApp.swift
//  OmniSiteWatch
//
//  watchOS companion app for OmniSite Tracker.
//  Provides quick logging and site recommendations on Apple Watch.
//

import SwiftUI
import WatchConnectivity

@main
struct OmniSiteWatchApp: App {
    @StateObject private var connectivityManager = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivityManager)
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        NavigationStack {
            TabView {
                // Quick Log Tab
                QuickLogView()
                    .tag(0)

                // Recommendation Tab
                RecommendationView()
                    .tag(1)

                // History Tab
                HistoryView()
                    .tag(2)
            }
            .tabViewStyle(.verticalPage)
        }
    }
}

// MARK: - Quick Log View

struct QuickLogView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @State private var selectedSite: String?
    @State private var showingConfirmation = false
    @State private var isLogging = false

    let sites = [
        "Abdomen Left",
        "Abdomen Right",
        "Left Thigh",
        "Right Thigh",
        "Left Arm",
        "Right Arm",
        "Left Hip",
        "Right Hip"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Quick Log")
                    .font(.headline)
                    .padding(.top)

                ForEach(sites, id: \.self) { site in
                    Button(action: {
                        selectedSite = site
                        showingConfirmation = true
                    }) {
                        HStack {
                            Text(site)
                                .font(.body)
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .confirmationDialog(
            "Log Placement",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Confirm \(selectedSite ?? "")") {
                logPlacement()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Log placement at \(selectedSite ?? "")?")
        }
        .overlay {
            if isLogging {
                ProgressView("Logging...")
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
            }
        }
    }

    private func logPlacement() {
        guard let site = selectedSite else { return }
        isLogging = true

        connectivity.sendPlacement(site: site) { success in
            isLogging = false
            if success {
                WKInterfaceDevice.current().play(.success)
            } else {
                WKInterfaceDevice.current().play(.failure)
            }
        }
    }
}

// MARK: - Recommendation View

struct RecommendationView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Recommendation header
                VStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.title)
                        .foregroundColor(.yellow)

                    Text("Recommended")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(connectivity.recommendedSite ?? "Loading...")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
                .padding()

                // Days since last use
                if let daysSince = connectivity.daysSinceRecommended {
                    HStack {
                        Image(systemName: "clock")
                        Text("\(daysSince) days since last use")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                // Quick log button
                if let site = connectivity.recommendedSite {
                    Button(action: {
                        connectivity.sendPlacement(site: site) { _ in }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Log Now")
                        }
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }

                // Refresh button
                Button(action: {
                    connectivity.requestUpdate()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding()
        }
    }
}

// MARK: - History View

struct HistoryView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent")
                    .font(.headline)
                    .padding(.top)

                if connectivity.recentPlacements.isEmpty {
                    Text("No recent placements")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(connectivity.recentPlacements, id: \.date) { placement in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(placement.site)
                                    .font(.body)
                                Text(placement.date, style: .relative)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Watch Connectivity Manager

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    @Published var recommendedSite: String?
    @Published var daysSinceRecommended: Int?
    @Published var recentPlacements: [WatchPlacement] = []
    @Published var isConnected: Bool = false

    private var session: WCSession?

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    // MARK: - Public Methods

    func sendPlacement(site: String, completion: @escaping (Bool) -> Void) {
        guard let session = session, session.isReachable else {
            completion(false)
            return
        }

        let message: [String: Any] = [
            "action": "logPlacement",
            "site": site,
            "date": Date()
        ]

        session.sendMessage(message, replyHandler: { reply in
            DispatchQueue.main.async {
                completion(reply["success"] as? Bool ?? false)
                self.requestUpdate()
            }
        }) { error in
            print("Failed to send placement: \(error)")
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }

    func requestUpdate() {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = ["action": "requestUpdate"]

        session.sendMessage(message, replyHandler: { reply in
            DispatchQueue.main.async {
                self.updateFromReply(reply)
            }
        }) { error in
            print("Failed to request update: \(error)")
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
            if self.isConnected {
                self.requestUpdate()
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.updateFromReply(applicationContext)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.updateFromReply(message)
        }
    }

    // MARK: - Private Methods

    private func updateFromReply(_ data: [String: Any]) {
        if let site = data["recommendedSite"] as? String {
            recommendedSite = site
        }
        if let days = data["daysSinceRecommended"] as? Int {
            daysSinceRecommended = days
        }
        if let placements = data["recentPlacements"] as? [[String: Any]] {
            recentPlacements = placements.compactMap { WatchPlacement(from: $0) }
        }
    }
}

// MARK: - Watch Placement Model

struct WatchPlacement {
    let site: String
    let date: Date

    init?(from dict: [String: Any]) {
        guard let site = dict["site"] as? String,
              let date = dict["date"] as? Date else {
            return nil
        }
        self.site = site
        self.date = date
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(WatchConnectivityManager.shared)
}
