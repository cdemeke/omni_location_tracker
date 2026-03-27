//
//  DataSyncStatusView.swift
//  OmniSiteTracker
//
//  Monitor sync status and conflicts
//

import SwiftUI

struct SyncStatus {
    var lastSync: Date?
    var pendingChanges: Int
    var conflicts: Int
    var isConnected: Bool
    var isSyncing: Bool
}

@MainActor
@Observable
final class DataSyncManager {
    var status = SyncStatus(lastSync: Date().addingTimeInterval(-3600), pendingChanges: 3, conflicts: 0, isConnected: true, isSyncing: false)
    
    func sync() async {
        status.isSyncing = true
        try? await Task.sleep(for: .seconds(2))
        status.lastSync = Date()
        status.pendingChanges = 0
        status.isSyncing = false
    }
    
    func resolveConflicts() async {
        try? await Task.sleep(for: .seconds(1))
        status.conflicts = 0
    }
}

struct DataSyncStatusView: View {
    @State private var manager = DataSyncManager()
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: manager.status.isConnected ? "wifi" : "wifi.slash")
                        .foregroundStyle(manager.status.isConnected ? .green : .red)
                    Text(manager.status.isConnected ? "Connected" : "Offline")
                    Spacer()
                    if manager.status.isSyncing {
                        ProgressView()
                    }
                }
            }
            
            Section("Status") {
                if let lastSync = manager.status.lastSync {
                    LabeledContent("Last Sync", value: lastSync.formatted(date: .abbreviated, time: .shortened))
                }
                
                LabeledContent("Pending Changes", value: "\(manager.status.pendingChanges)")
                
                if manager.status.conflicts > 0 {
                    HStack {
                        Text("Conflicts")
                        Spacer()
                        Text("\(manager.status.conflicts)")
                            .foregroundStyle(.red)
                    }
                }
            }
            
            Section {
                Button {
                    Task { await manager.sync() }
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Sync Now")
                    }
                }
                .disabled(manager.status.isSyncing || !manager.status.isConnected)
                
                if manager.status.conflicts > 0 {
                    Button {
                        Task { await manager.resolveConflicts() }
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text("Resolve Conflicts")
                        }
                    }
                    .foregroundStyle(.orange)
                }
            }
            
            Section("Settings") {
                Toggle("Auto-Sync", isOn: .constant(true))
                Toggle("Sync on Cellular", isOn: .constant(false))
                Toggle("Background Sync", isOn: .constant(true))
            }
        }
        .navigationTitle("Sync Status")
    }
}

#Preview {
    NavigationStack {
        DataSyncStatusView()
    }
}
