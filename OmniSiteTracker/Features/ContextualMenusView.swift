//
//  ContextualMenusView.swift
//  OmniSiteTracker
//
//  Context menus for quick actions throughout the app
//

import SwiftUI
import SwiftData

struct SiteContextMenu: View {
    let site: String
    let onLog: () -> Void
    let onFavorite: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        Button { onLog() } label: { Label("Log Site", systemImage: "plus.circle") }
        Button { onFavorite() } label: { Label("Add to Favorites", systemImage: "star") }
        Button { onShare() } label: { Label("Share", systemImage: "square.and.arrow.up") }
        Divider()
        Button(role: .destructive) {} label: { Label("Hide Site", systemImage: "eye.slash") }
    }
}

struct PlacementContextMenu: View {
    let placement: PlacementLog
    let onEdit: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
        Button { onShare() } label: { Label("Share", systemImage: "square.and.arrow.up") }
        Button {} label: { Label("Add Note", systemImage: "note.text") }
        Divider()
        Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
    }
}

struct HistoryContextMenu: View {
    let onExport: () -> Void
    let onFilter: () -> Void
    let onSort: () -> Void
    
    var body: some View {
        Button { onExport() } label: { Label("Export History", systemImage: "square.and.arrow.up") }
        Button { onFilter() } label: { Label("Filter", systemImage: "line.3.horizontal.decrease.circle") }
        Button { onSort() } label: { Label("Sort", systemImage: "arrow.up.arrow.down") }
    }
}

// Demo view showing context menu usage
struct ContextualMenusDemoView: View {
    @State private var sites = ["Abdomen - Left", "Abdomen - Right", "Upper Arm - Left", "Upper Arm - Right"]
    @State private var selectedSite: String?
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        List {
            Section("Sites (Long press for menu)") {
                ForEach(sites, id: \.self) { site in
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.blue)
                        Text(site)
                        Spacer()
                        if selectedSite == site {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .contextMenu {
                        SiteContextMenu(
                            site: site,
                            onLog: {
                                alertMessage = "Logged: \(site)"
                                showAlert = true
                            },
                            onFavorite: {
                                alertMessage = "Added to favorites: \(site)"
                                showAlert = true
                            },
                            onShare: {
                                alertMessage = "Sharing: \(site)"
                                showAlert = true
                            }
                        )
                    }
                    .onTapGesture {
                        selectedSite = site
                    }
                }
            }
            
            Section("Quick Actions") {
                ForEach(["Log Site", "View History", "Export Data"], id: \.self) { action in
                    Label(action, systemImage: actionIcon(action))
                        .contextMenu {
                            Button { } label: { Label("Run Action", systemImage: "play") }
                            Button { } label: { Label("Add to Shortcuts", systemImage: "bolt") }
                            Button { } label: { Label("Info", systemImage: "info.circle") }
                        }
                }
            }
            
            Section("Instructions") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Long press any item for options", systemImage: "hand.tap")
                    Label("Context menus provide quick actions", systemImage: "bolt")
                    Label("Available throughout the app", systemImage: "apps.iphone")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Context Menus")
        .alert("Action", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
    }
    
    func actionIcon(_ action: String) -> String {
        switch action {
        case "Log Site": return "plus.circle"
        case "View History": return "clock"
        case "Export Data": return "square.and.arrow.up"
        default: return "circle"
        }
    }
}

// View modifier for adding standard context menu
struct StandardContextMenuModifier: ViewModifier {
    let title: String
    let onPrimary: () -> Void
    let onSecondary: () -> Void
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button(action: onPrimary) {
                    Label("Primary Action", systemImage: "star")
                }
                Button(action: onSecondary) {
                    Label("Secondary Action", systemImage: "ellipsis.circle")
                }
                Divider()
                Button(role: .destructive) {} label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }
}

extension View {
    func standardContextMenu(title: String, onPrimary: @escaping () -> Void, onSecondary: @escaping () -> Void) -> some View {
        modifier(StandardContextMenuModifier(title: title, onPrimary: onPrimary, onSecondary: onSecondary))
    }
}

#Preview {
    NavigationStack {
        ContextualMenusDemoView()
    }
}
