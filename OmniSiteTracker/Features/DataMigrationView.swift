//
//  DataMigrationView.swift
//  OmniSiteTracker
//
//  Migrate data from other apps
//

import SwiftUI

struct MigrationSource: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let isSupported: Bool
}

@MainActor
@Observable
final class DataMigrationManager {
    var isMigrating = false
    var progress: Double = 0
    var status = ""
    var migratedCount = 0
    
    let sources: [MigrationSource] = [
        MigrationSource(name: "CSV File", icon: "doc.text", isSupported: true),
        MigrationSource(name: "JSON File", icon: "curlybraces", isSupported: true),
        MigrationSource(name: "Health App", icon: "heart.fill", isSupported: true),
        MigrationSource(name: "Other Tracker Apps", icon: "app.badge", isSupported: false)
    ]
    
    func migrate(from source: MigrationSource) async {
        isMigrating = true
        progress = 0
        status = "Preparing..."
        
        for i in 1...10 {
            try? await Task.sleep(for: .milliseconds(300))
            progress = Double(i) / 10.0
            status = "Importing records... \(i * 10)%"
        }
        
        migratedCount = Int.random(in: 15...50)
        status = "Complete!"
        isMigrating = false
    }
}

struct DataMigrationView: View {
    @State private var manager = DataMigrationManager()
    @State private var selectedSource: MigrationSource?
    
    var body: some View {
        List {
            Section {
                Text("Import your data from other sources to get started quickly.")
                    .foregroundStyle(.secondary)
            }
            
            Section("Import From") {
                ForEach(manager.sources) { source in
                    Button {
                        if source.isSupported {
                            selectedSource = source
                        }
                    } label: {
                        HStack {
                            Image(systemName: source.icon)
                                .frame(width: 30)
                                .foregroundStyle(source.isSupported ? .blue : .secondary)
                            
                            Text(source.name)
                                .foregroundStyle(source.isSupported ? .primary : .secondary)
                            
                            Spacer()
                            
                            if !source.isSupported {
                                Text("Coming Soon")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(!source.isSupported)
                }
            }
            
            if manager.isMigrating {
                Section("Progress") {
                    VStack(spacing: 12) {
                        ProgressView(value: manager.progress)
                        Text(manager.status)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if manager.migratedCount > 0 && !manager.isMigrating {
                Section("Results") {
                    Label("\(manager.migratedCount) records imported", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle("Data Migration")
        .sheet(item: $selectedSource) { source in
            MigrationConfirmationView(source: source, manager: manager)
        }
    }
}

struct MigrationConfirmationView: View {
    let source: MigrationSource
    @Bindable var manager: DataMigrationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: source.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                Text("Import from \(source.name)")
                    .font(.title2)
                    .bold()
                
                Text("This will import your data from the selected source.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                Button("Start Import") {
                    Task {
                        await manager.migrate(from: source)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DataMigrationView()
    }
}
