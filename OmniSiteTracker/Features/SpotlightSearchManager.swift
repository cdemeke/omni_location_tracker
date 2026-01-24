//
//  SpotlightSearchManager.swift
//  OmniSiteTracker
//
//  Spotlight search integration for quick access
//

import SwiftUI
import CoreSpotlight
import MobileCoreServices

struct SpotlightItem: Identifiable {
    let id: String
    let title: String
    let description: String
    let type: ItemType
    let date: Date?
    
    enum ItemType: String {
        case site = "site"
        case log = "log"
        case setting = "setting"
        case action = "action"
        
        var domainIdentifier: String {
            "com.omnitracker.\(rawValue)"
        }
        
        var contentType: String {
            switch self {
            case .site, .log: return UTType.content.identifier
            case .setting: return UTType.item.identifier
            case .action: return UTType.item.identifier
            }
        }
    }
}

@MainActor
@Observable
final class SpotlightSearchManager {
    static let shared = SpotlightSearchManager()
    
    private(set) var indexedItemCount = 0
    private(set) var lastIndexDate: Date?
    private(set) var isIndexing = false
    
    private let searchableIndex = CSSearchableIndex.default()
    
    func indexSites(_ sites: [String]) async {
        isIndexing = true
        
        var items: [CSSearchableItem] = []
        
        for site in sites {
            let item = SpotlightItem(
                id: "site_\(site.lowercased().replacingOccurrences(of: " ", with: "_"))",
                title: site,
                description: "Injection site: \(site)",
                type: .site,
                date: nil
            )
            items.append(createSearchableItem(from: item))
        }
        
        do {
            try await searchableIndex.indexSearchableItems(items)
            indexedItemCount += items.count
            lastIndexDate = Date()
        } catch {
            print("Failed to index sites: \(error)")
        }
        
        isIndexing = false
    }
    
    func indexPlacementLogs(_ logs: [PlacementLog]) async {
        isIndexing = true
        
        var items: [CSSearchableItem] = []
        
        for log in logs.prefix(100) {
            let item = SpotlightItem(
                id: "log_\(log.id.uuidString)",
                title: "Site Log: \(log.site)",
                description: "Logged on \(log.placedAt.formatted())",
                type: .log,
                date: log.placedAt
            )
            items.append(createSearchableItem(from: item))
        }
        
        do {
            try await searchableIndex.indexSearchableItems(items)
            indexedItemCount += items.count
            lastIndexDate = Date()
        } catch {
            print("Failed to index logs: \(error)")
        }
        
        isIndexing = false
    }
    
    func indexActions() async {
        let actions = [
            SpotlightItem(id: "action_log", title: "Log New Site", description: "Record a new site rotation", type: .action, date: nil),
            SpotlightItem(id: "action_history", title: "View History", description: "See past site rotations", type: .action, date: nil),
            SpotlightItem(id: "action_export", title: "Export Data", description: "Export your site history", type: .action, date: nil),
            SpotlightItem(id: "action_stats", title: "View Statistics", description: "See usage analytics", type: .action, date: nil)
        ]
        
        let items = actions.map { createSearchableItem(from: $0) }
        
        do {
            try await searchableIndex.indexSearchableItems(items)
            indexedItemCount += items.count
        } catch {
            print("Failed to index actions: \(error)")
        }
    }
    
    func removeItem(identifier: String) async {
        do {
            try await searchableIndex.deleteSearchableItems(withIdentifiers: [identifier])
            indexedItemCount = max(0, indexedItemCount - 1)
        } catch {
            print("Failed to remove item: \(error)")
        }
    }
    
    func removeAllItems() async {
        do {
            try await searchableIndex.deleteAllSearchableItems()
            indexedItemCount = 0
        } catch {
            print("Failed to remove all items: \(error)")
        }
    }
    
    func handleSpotlightActivity(_ userActivity: NSUserActivity) -> SpotlightItem? {
        guard userActivity.activityType == CSSearchableItemActionType,
              let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return nil
        }
        
        // Parse the identifier to determine the item type
        if identifier.hasPrefix("site_") {
            let site = identifier.replacingOccurrences(of: "site_", with: "").replacingOccurrences(of: "_", with: " ").capitalized
            return SpotlightItem(id: identifier, title: site, description: "", type: .site, date: nil)
        } else if identifier.hasPrefix("action_") {
            return SpotlightItem(id: identifier, title: identifier.replacingOccurrences(of: "action_", with: "").capitalized, description: "", type: .action, date: nil)
        } else if identifier.hasPrefix("log_") {
            return SpotlightItem(id: identifier, title: "Site Log", description: "", type: .log, date: nil)
        }
        
        return nil
    }
    
    private func createSearchableItem(from item: SpotlightItem) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: UTType(item.type.contentType) ?? .content)
        attributeSet.title = item.title
        attributeSet.contentDescription = item.description
        attributeSet.keywords = [item.title, item.type.rawValue, "omnipod", "site", "tracker"]
        
        if let date = item.date {
            attributeSet.contentCreationDate = date
        }
        
        return CSSearchableItem(
            uniqueIdentifier: item.id,
            domainIdentifier: item.type.domainIdentifier,
            attributeSet: attributeSet
        )
    }
}

struct SpotlightSettingsView: View {
    @State private var manager = SpotlightSearchManager.shared
    @State private var showDeleteAlert = false
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text("Spotlight Search")
                            .font(.headline)
                        Text("Find items from Spotlight")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Index Status") {
                LabeledContent("Indexed Items", value: "\(manager.indexedItemCount)")
                
                if let lastIndex = manager.lastIndexDate {
                    LabeledContent("Last Index", value: lastIndex.formatted())
                } else {
                    LabeledContent("Last Index", value: "Never")
                }
                
                if manager.isIndexing {
                    HStack {
                        Text("Indexing...")
                        Spacer()
                        ProgressView()
                    }
                }
            }
            
            Section("Actions") {
                Button("Index Sites") {
                    Task {
                        await manager.indexSites([
                            "Abdomen - Left", "Abdomen - Right",
                            "Upper Arm - Left", "Upper Arm - Right",
                            "Thigh - Left", "Thigh - Right"
                        ])
                    }
                }
                .disabled(manager.isIndexing)
                
                Button("Index Quick Actions") {
                    Task {
                        await manager.indexActions()
                    }
                }
                .disabled(manager.isIndexing)
                
                Button("Clear Index", role: .destructive) {
                    showDeleteAlert = true
                }
                .disabled(manager.isIndexing)
            }
            
            Section("How It Works") {
                Label("Search \"OmniSite\" in Spotlight", systemImage: "magnifyingglass")
                Label("Find sites and logs quickly", systemImage: "doc.text.magnifyingglass")
                Label("Launch actions directly", systemImage: "bolt")
                Label("Results update automatically", systemImage: "arrow.triangle.2.circlepath")
            }
        }
        .navigationTitle("Spotlight")
        .alert("Clear Index", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                Task {
                    await manager.removeAllItems()
                }
            }
        } message: {
            Text("This will remove all items from Spotlight search.")
        }
    }
}

#Preview {
    NavigationStack {
        SpotlightSettingsView()
    }
}
