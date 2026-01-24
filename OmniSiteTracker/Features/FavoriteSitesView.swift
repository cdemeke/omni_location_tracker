//
//  FavoriteSitesView.swift
//  OmniSiteTracker
//
//  Manage favorite sites for quick access
//

import SwiftUI

@MainActor
@Observable
final class FavoritesManager {
    var favorites: [String] = []
    
    init() {
        load()
    }
    
    func add(_ site: String) {
        if !favorites.contains(site) {
            favorites.append(site)
            save()
        }
    }
    
    func remove(_ site: String) {
        favorites.removeAll { $0 == site }
        save()
    }
    
    func isFavorite(_ site: String) -> Bool {
        favorites.contains(site)
    }
    
    func toggle(_ site: String) {
        if isFavorite(site) {
            remove(site)
        } else {
            add(site)
        }
    }
    
    private func save() {
        UserDefaults.standard.set(favorites, forKey: "favoriteSites")
    }
    
    private func load() {
        favorites = UserDefaults.standard.stringArray(forKey: "favoriteSites") ?? []
    }
}

struct FavoriteSitesView: View {
    @State private var manager = FavoritesManager()
    
    private let allSites = [
        "Left Arm (Upper)", "Left Arm (Lower)",
        "Right Arm (Upper)", "Right Arm (Lower)",
        "Left Thigh (Outer)", "Left Thigh (Inner)",
        "Right Thigh (Outer)", "Right Thigh (Inner)",
        "Abdomen (Left)", "Abdomen (Right)",
        "Lower Back (Left)", "Lower Back (Right)"
    ]
    
    var body: some View {
        List {
            if !manager.favorites.isEmpty {
                Section("Favorites") {
                    ForEach(manager.favorites, id: \.self) { site in
                        HStack {
                            Text(site)
                            Spacer()
                            Button {
                                manager.remove(site)
                            } label: {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                    .onMove { from, to in
                        manager.favorites.move(fromOffsets: from, toOffset: to)
                    }
                }
            }
            
            Section("All Sites") {
                ForEach(allSites, id: \.self) { site in
                    HStack {
                        Text(site)
                        Spacer()
                        Button {
                            manager.toggle(site)
                        } label: {
                            Image(systemName: manager.isFavorite(site) ? "star.fill" : "star")
                                .foregroundStyle(manager.isFavorite(site) ? .yellow : .secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Favorite Sites")
        .toolbar {
            EditButton()
        }
    }
}

#Preview {
    NavigationStack {
        FavoriteSitesView()
    }
}
