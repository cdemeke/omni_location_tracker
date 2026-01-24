//
//  SettingsBackupView.swift
//  OmniSiteTracker
//
//  Backup and restore app settings
//

import SwiftUI

@MainActor
@Observable
final class SettingsBackupManager {
    var backups: [SettingsBackup] = []
    var isBackingUp = false
    var isRestoring = false
    
    struct SettingsBackup: Identifiable {
        let id = UUID()
        let date: Date
        let size: Int
        let version: String
    }
    
    func createBackup() async {
        isBackingUp = true
        try? await Task.sleep(for: .seconds(1))
        
        let backup = SettingsBackup(
            date: Date(),
            size: Int.random(in: 10...100),
            version: "1.0"
        )
        backups.insert(backup, at: 0)
        isBackingUp = false
    }
    
    func restore(_ backup: SettingsBackup) async {
        isRestoring = true
        try? await Task.sleep(for: .seconds(2))
        isRestoring = false
    }
    
    func delete(_ backup: SettingsBackup) {
        backups.removeAll { $0.id == backup.id }
    }
}

struct SettingsBackupView: View {
    @State private var manager = SettingsBackupManager()
    
    var body: some View {
        List {
            Section {
                Button {
                    Task { await manager.createBackup() }
                } label: {
                    HStack {
                        if manager.isBackingUp {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.up.doc")
                        }
                        Text("Create Backup")
                    }
                }
                .disabled(manager.isBackingUp)
            }
            
            Section("Backups") {
                if manager.backups.isEmpty {
                    Text("No backups yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(manager.backups) { backup in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(backup.date.formatted())
                                    .font(.headline)
                                Text("\(backup.size) KB • v\(backup.version)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Restore") {
                                Task { await manager.restore(backup) }
                            }
                            .buttonStyle(.bordered)
                            .disabled(manager.isRestoring)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            manager.delete(manager.backups[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings Backup")
    }
}

#Preview {
    NavigationStack {
        SettingsBackupView()
    }
}
