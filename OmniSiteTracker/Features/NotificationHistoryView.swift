//
//  NotificationHistoryView.swift
//  OmniSiteTracker
//
//  View past notifications
//

import SwiftUI

struct NotificationRecord: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let date: Date
    let type: NotificationType
    var wasRead: Bool
    
    enum NotificationType: String {
        case reminder = "Reminder"
        case alert = "Alert"
        case achievement = "Achievement"
        case system = "System"
        
        var icon: String {
            switch self {
            case .reminder: return "bell.fill"
            case .alert: return "exclamationmark.triangle.fill"
            case .achievement: return "star.fill"
            case .system: return "gear"
            }
        }
        
        var color: Color {
            switch self {
            case .reminder: return .blue
            case .alert: return .orange
            case .achievement: return .yellow
            case .system: return .secondary
            }
        }
    }
}

@MainActor
@Observable
final class NotificationHistoryManager {
    var records: [NotificationRecord] = [
        NotificationRecord(title: "Site Change Due", body: "Time to rotate to a new site", date: Date().addingTimeInterval(-3600), type: .reminder, wasRead: true),
        NotificationRecord(title: "Great Job!", body: "You reached a 7-day streak", date: Date().addingTimeInterval(-86400), type: .achievement, wasRead: false),
        NotificationRecord(title: "Sync Complete", body: "Your data has been synced", date: Date().addingTimeInterval(-172800), type: .system, wasRead: true)
    ]
    
    var unreadCount: Int {
        records.filter { !$0.wasRead }.count
    }
    
    func markAsRead(_ record: NotificationRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index].wasRead = true
        }
    }
    
    func markAllAsRead() {
        for index in records.indices {
            records[index].wasRead = true
        }
    }
    
    func clear() {
        records.removeAll()
    }
}

struct NotificationHistoryView: View {
    @State private var manager = NotificationHistoryManager()
    
    var body: some View {
        List {
            ForEach(manager.records) { record in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: record.type.icon)
                        .foregroundStyle(record.type.color)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(record.title)
                                .font(.headline)
                            
                            if !record.wasRead {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        Text(record.body)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(record.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 4)
                .onTapGesture {
                    manager.markAsRead(record)
                }
            }
        }
        .navigationTitle("Notifications")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Mark All as Read") {
                        manager.markAllAsRead()
                    }
                    Button("Clear All", role: .destructive) {
                        manager.clear()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotificationHistoryView()
    }
}
