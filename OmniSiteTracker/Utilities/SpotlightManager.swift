//
//  SpotlightManager.swift
//  OmniSiteTracker
//
//  Spotlight search integration for placements.
//

import Foundation
import CoreSpotlight
import MobileCoreServices
import SwiftUI

@MainActor
final class SpotlightManager {
    static let shared = SpotlightManager()
    
    private init() {}
    
    func indexPlacement(id: UUID, site: String, date: Date, note: String?) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = "Pump Site: \(site)"
        attributeSet.contentDescription = formatDate(date) + (note.map { " - \($0)" } ?? "")
        attributeSet.keywords = ["pump", "site", "placement", site.lowercased()]
        
        let item = CSSearchableItem(
            uniqueIdentifier: id.uuidString,
            domainIdentifier: "com.omnisite.placements",
            attributeSet: attributeSet
        )
        item.expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: date)
        
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                print("Spotlight indexing error: \(error)")
            }
        }
    }
    
    func removePlacement(id: UUID) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [id.uuidString]) { error in
            if let error = error {
                print("Spotlight removal error: \(error)")
            }
        }
    }
    
    func removeAllPlacements() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: ["com.omnisite.placements"]) { error in
            if let error = error {
                print("Spotlight removal error: \(error)")
            }
        }
    }
    
    func indexAllPlacements(_ placements: [(id: UUID, site: String, date: Date, note: String?)]) {
        let items = placements.map { placement -> CSSearchableItem in
            let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
            attributeSet.title = "Pump Site: \(placement.site)"
            attributeSet.contentDescription = formatDate(placement.date) + (placement.note.map { " - \($0)" } ?? "")
            attributeSet.keywords = ["pump", "site", "placement", placement.site.lowercased()]
            
            let item = CSSearchableItem(
                uniqueIdentifier: placement.id.uuidString,
                domainIdentifier: "com.omnisite.placements",
                attributeSet: attributeSet
            )
            return item
        }
        
        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                print("Spotlight indexing error: \(error)")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SpotlightSettingsView: View {
    @AppStorage("spotlight_enabled") private var spotlightEnabled = true
    @State private var isReindexing = false
    
    var body: some View {
        List {
            Section {
                Toggle("Enable Spotlight Search", isOn: $spotlightEnabled)
                    .onChange(of: spotlightEnabled) { _, newValue in
                        if !newValue {
                            SpotlightManager.shared.removeAllPlacements()
                        }
                    }
            } header: {
                Text("Spotlight")
            } footer: {
                Text("When enabled, placements can be found through iOS Spotlight search.")
            }
            
            if spotlightEnabled {
                Section {
                    Button(action: reindex) {
                        HStack {
                            Text("Reindex All Placements")
                            Spacer()
                            if isReindexing {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isReindexing)
                } header: {
                    Text("Maintenance")
                }
            }
        }
        .navigationTitle("Spotlight Search")
    }
    
    private func reindex() {
        isReindexing = true
        // In real implementation, fetch placements and reindex
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isReindexing = false
        }
    }
}

#Preview {
    NavigationStack {
        SpotlightSettingsView()
    }
}
