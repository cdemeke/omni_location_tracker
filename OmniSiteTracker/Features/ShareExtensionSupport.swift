//
//  ShareExtensionSupport.swift
//  OmniSiteTracker
//
//  Share extension support for quick sharing
//

import SwiftUI
import UniformTypeIdentifiers

struct ShareableContent: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let url: URL?
    let image: UIImage?
    
    var activityItems: [Any] {
        var items: [Any] = [body]
        if let url = url {
            items.append(url)
        }
        if let image = image {
            items.append(image)
        }
        return items
    }
}

@MainActor
@Observable
final class ShareManager {
    static let shared = ShareManager()
    
    private(set) var recentShares: [ShareableContent] = []
    
    func createSiteShareContent(site: String, date: Date) -> ShareableContent {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        let body = """
        📍 Site Rotation Log
        
        Site: \(site)
        Date: \(dateFormatter.string(from: date))
        
        Tracked with OmniSite Tracker
        """
        
        return ShareableContent(
            title: "Site Rotation: \(site)",
            body: body,
            url: URL(string: "https://omnitracker.app"),
            image: nil
        )
    }
    
    func createHistoryShareContent(placements: [PlacementLog]) -> ShareableContent {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        var lines = ["📊 Site Rotation History", ""]
        
        for placement in placements.prefix(10) {
            lines.append("• \(placement.site) - \(dateFormatter.string(from: placement.placedAt))")
        }
        
        if placements.count > 10 {
            lines.append("... and \(placements.count - 10) more")
        }
        
        lines.append("")
        lines.append("Tracked with OmniSite Tracker")
        
        return ShareableContent(
            title: "Site Rotation History",
            body: lines.joined(separator: "\n"),
            url: nil,
            image: nil
        )
    }
    
    func createStatsShareContent(totalRotations: Int, favoriteSite: String, streak: Int) -> ShareableContent {
        let body = """
        📈 My OmniSite Stats
        
        Total Rotations: \(totalRotations)
        Favorite Site: \(favoriteSite)
        Current Streak: \(streak) days
        
        Track your sites with OmniSite Tracker!
        """
        
        return ShareableContent(
            title: "My OmniSite Stats",
            body: body,
            url: URL(string: "https://omnitracker.app"),
            image: nil
        )
    }
    
    func trackShare(_ content: ShareableContent) {
        recentShares.insert(content, at: 0)
        if recentShares.count > 10 {
            recentShares = Array(recentShares.prefix(10))
        }
    }
}

struct ShareView: View {
    let content: ShareableContent
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Preview
                VStack(alignment: .leading, spacing: 12) {
                    Text(content.title)
                        .font(.headline)
                    
                    Text(content.body)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    if let url = content.url {
                        Link(url.absoluteString, destination: url)
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Share Options
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 20) {
                    ShareOptionButton(icon: "message.fill", title: "Messages", color: .green)
                    ShareOptionButton(icon: "envelope.fill", title: "Mail", color: .blue)
                    ShareOptionButton(icon: "doc.on.doc", title: "Copy", color: .gray)
                    ShareOptionButton(icon: "square.and.arrow.up", title: "More", color: .orange)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct ShareOptionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 50, height: 50)
                .background(color)
                .foregroundStyle(.white)
                .cornerRadius(12)
            
            Text(title)
                .font(.caption)
        }
    }
}

// Share Sheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let completion: ((Bool) -> Void)?
    
    init(items: [Any], completion: ((Bool) -> Void)? = nil) {
        self.items = items
        self.completion = completion
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            completion?(completed)
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Extension settings view
struct ShareExtensionSettingsView: View {
    @State private var manager = ShareManager.shared
    @State private var includeAppLink = true
    @State private var includeEmojis = true
    @State private var defaultFormat = "Standard"
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text("Share Extension")
                            .font(.headline)
                        Text("Share your tracking data")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Format Options") {
                Toggle("Include App Link", isOn: $includeAppLink)
                Toggle("Include Emojis", isOn: $includeEmojis)
                
                Picker("Default Format", selection: $defaultFormat) {
                    Text("Standard").tag("Standard")
                    Text("Compact").tag("Compact")
                    Text("Detailed").tag("Detailed")
                }
            }
            
            Section("Recent Shares") {
                if manager.recentShares.isEmpty {
                    Text("No recent shares")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(manager.recentShares) { share in
                        VStack(alignment: .leading) {
                            Text(share.title)
                                .font(.headline)
                            Text(share.body.prefix(50) + "...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section("What You Can Share") {
                Label("Individual site rotations", systemImage: "mappin.circle")
                Label("History summaries", systemImage: "clock")
                Label("Statistics and streaks", systemImage: "chart.bar")
                Label("Export reports", systemImage: "doc.text")
            }
        }
        .navigationTitle("Share Settings")
    }
}

#Preview {
    NavigationStack {
        ShareExtensionSettingsView()
    }
}
