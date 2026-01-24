//
//  CarPlayManager.swift
//  OmniSiteTracker
//
//  CarPlay integration for in-vehicle site logging
//

import SwiftUI
import CarPlay

@MainActor
@Observable
final class CarPlayManager: NSObject {
    static let shared = CarPlayManager()
    
    private(set) var isConnected = false
    private(set) var interfaceController: CPInterfaceController?
    private(set) var lastLoggedSite: String?
    private(set) var recentSites: [String] = []
    
    private let sites = [
        "Abdomen - Left",
        "Abdomen - Right",
        "Upper Arm - Left", 
        "Upper Arm - Right",
        "Thigh - Left",
        "Thigh - Right"
    ]
    
    override init() {
        super.init()
        loadRecentSites()
    }
    
    func connect(to controller: CPInterfaceController) {
        interfaceController = controller
        isConnected = true
        setupRootTemplate()
    }
    
    func disconnect() {
        interfaceController = nil
        isConnected = false
    }
    
    private func setupRootTemplate() {
        let listTemplate = createMainListTemplate()
        interfaceController?.setRootTemplate(listTemplate, animated: true, completion: nil)
    }
    
    private func createMainListTemplate() -> CPListTemplate {
        // Quick Log Section
        let quickLogItems = sites.prefix(4).map { site in
            let item = CPListItem(text: site, detailText: "Tap to log")
            item.handler = { [weak self] _, completion in
                self?.logSite(site)
                completion()
            }
            return item
        }
        let quickLogSection = CPListSection(items: quickLogItems, header: "Quick Log", sectionIndexTitle: nil)
        
        // Recent Sites Section
        let recentItems = recentSites.prefix(3).map { site in
            let item = CPListItem(text: site, detailText: "Recently used")
            item.handler = { [weak self] _, completion in
                self?.logSite(site)
                completion()
            }
            return item
        }
        let recentSection = CPListSection(items: recentItems, header: "Recent", sectionIndexTitle: nil)
        
        // More Options Section
        let allSitesItem = CPListItem(text: "All Sites", detailText: "View all injection sites")
        allSitesItem.handler = { [weak self] _, completion in
            self?.showAllSites()
            completion()
        }
        
        let historyItem = CPListItem(text: "History", detailText: "View recent logs")
        historyItem.handler = { [weak self] _, completion in
            self?.showHistory()
            completion()
        }
        
        let moreSection = CPListSection(items: [allSitesItem, historyItem], header: "More", sectionIndexTitle: nil)
        
        let template = CPListTemplate(title: "OmniSite", sections: [quickLogSection, recentSection, moreSection])
        return template
    }
    
    private func showAllSites() {
        let items = sites.map { site in
            let item = CPListItem(text: site, detailText: nil)
            item.handler = { [weak self] _, completion in
                self?.logSite(site)
                completion()
            }
            return item
        }
        
        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "All Sites", sections: [section])
        
        interfaceController?.pushTemplate(template, animated: true, completion: nil)
    }
    
    private func showHistory() {
        let items = recentSites.enumerated().map { index, site in
            CPListItem(text: site, detailText: "Log #\(recentSites.count - index)")
        }
        
        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "History", sections: [section])
        
        interfaceController?.pushTemplate(template, animated: true, completion: nil)
    }
    
    func logSite(_ site: String) {
        lastLoggedSite = site
        
        // Add to recent sites
        recentSites.removeAll { $0 == site }
        recentSites.insert(site, at: 0)
        if recentSites.count > 10 {
            recentSites = Array(recentSites.prefix(10))
        }
        saveRecentSites()
        
        // Show confirmation
        let alert = CPAlertTemplate(
            titleVariants: ["Site Logged"],
            actions: [
                CPAlertAction(title: "OK", style: .default) { [weak self] _ in
                    self?.interfaceController?.dismissTemplate(animated: true, completion: nil)
                }
            ]
        )
        
        interfaceController?.presentTemplate(alert, animated: true, completion: nil)
    }
    
    private func loadRecentSites() {
        recentSites = UserDefaults.standard.stringArray(forKey: "carplay_recent_sites") ?? []
    }
    
    private func saveRecentSites() {
        UserDefaults.standard.set(recentSites, forKey: "carplay_recent_sites")
    }
}

// CarPlay Scene Delegate
class CarPlaySceneDelegate: NSObject, CPTemplateApplicationSceneDelegate {
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        Task { @MainActor in
            CarPlayManager.shared.connect(to: interfaceController)
        }
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController) {
        Task { @MainActor in
            CarPlayManager.shared.disconnect()
        }
    }
}

// Settings view for CarPlay configuration
struct CarPlaySettingsView: View {
    @State private var manager = CarPlayManager.shared
    @State private var showQuickLogSites = true
    @State private var showRecentSites = true
    @State private var maxRecentSites = 5
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "car.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text("CarPlay")
                            .font(.headline)
                        Text(manager.isConnected ? "Connected" : "Not Connected")
                            .font(.subheadline)
                            .foregroundStyle(manager.isConnected ? .green : .secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Display Options") {
                Toggle("Show Quick Log Sites", isOn: $showQuickLogSites)
                Toggle("Show Recent Sites", isOn: $showRecentSites)
                
                Stepper("Recent Sites: \(maxRecentSites)", value: $maxRecentSites, in: 3...10)
            }
            
            Section("Recent Sites") {
                if manager.recentSites.isEmpty {
                    Text("No recent sites")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(manager.recentSites, id: \.self) { site in
                        Text(site)
                    }
                }
            }
            
            if let lastSite = manager.lastLoggedSite {
                Section("Last Logged") {
                    LabeledContent("Site", value: lastSite)
                }
            }
            
            Section("Tips") {
                Label("Connect your iPhone to CarPlay", systemImage: "cable.connector")
                Label("Use voice commands with Siri", systemImage: "waveform")
                Label("Quick access from CarPlay home", systemImage: "apps.iphone")
            }
        }
        .navigationTitle("CarPlay Settings")
    }
}

#Preview {
    NavigationStack {
        CarPlaySettingsView()
    }
}
