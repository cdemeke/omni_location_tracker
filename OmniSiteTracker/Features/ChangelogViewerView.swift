//
//  ChangelogViewerView.swift
//  OmniSiteTracker
//
//  View app version history and changes
//

import SwiftUI

struct ChangelogEntry: Identifiable {
    let id = UUID()
    let version: String
    let date: Date
    let changes: [Change]
    
    struct Change: Identifiable {
        let id = UUID()
        let type: ChangeType
        let description: String
        
        enum ChangeType: String {
            case feature = "New"
            case improvement = "Improved"
            case fix = "Fixed"
            case removed = "Removed"
            
            var color: Color {
                switch self {
                case .feature: return .green
                case .improvement: return .blue
                case .fix: return .orange
                case .removed: return .red
                }
            }
        }
    }
}

struct ChangelogViewerView: View {
    private let changelog: [ChangelogEntry] = [
        ChangelogEntry(
            version: "2.0.0",
            date: Date(),
            changes: [
                .init(type: .feature, description: "Complete UI redesign with modern look"),
                .init(type: .feature, description: "iCloud sync support"),
                .init(type: .improvement, description: "Faster app launch time"),
                .init(type: .fix, description: "Fixed notification delivery issues")
            ]
        ),
        ChangelogEntry(
            version: "1.5.0",
            date: Date().addingTimeInterval(-30*24*60*60),
            changes: [
                .init(type: .feature, description: "Widget support"),
                .init(type: .feature, description: "Apple Watch app"),
                .init(type: .improvement, description: "Better site suggestions")
            ]
        ),
        ChangelogEntry(
            version: "1.0.0",
            date: Date().addingTimeInterval(-90*24*60*60),
            changes: [
                .init(type: .feature, description: "Initial release"),
                .init(type: .feature, description: "Site rotation tracking"),
                .init(type: .feature, description: "Basic analytics")
            ]
        )
    ]
    
    var body: some View {
        List {
            ForEach(changelog) { entry in
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Version \(entry.version)")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        ForEach(entry.changes) { change in
                            HStack(alignment: .top) {
                                Text(change.type.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(change.type.color.opacity(0.2))
                                    .foregroundStyle(change.type.color)
                                    .clipShape(Capsule())
                                
                                Text(change.description)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Whats New")
    }
}

#Preview {
    NavigationStack {
        ChangelogViewerView()
    }
}
