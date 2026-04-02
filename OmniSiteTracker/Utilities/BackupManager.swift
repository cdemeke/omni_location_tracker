//
//  BackupManager.swift
//  OmniSiteTracker
//
//  Manages local data backup and restore functionality.
//  Supports scheduled backups and manual backup/restore operations.
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Manages backup and restore operations
@MainActor
@Observable
final class BackupManager {
    // MARK: - Singleton

    static let shared = BackupManager()

    // MARK: - Properties

    /// List of available backups
    private(set) var backups: [BackupInfo] = []

    /// Whether a backup is in progress
    private(set) var isBackingUp: Bool = false

    /// Whether a restore is in progress
    private(set) var isRestoring: Bool = false

    /// Last backup date
    private(set) var lastBackupDate: Date?

    /// Backup directory
    private let backupDirectory: URL

    // MARK: - Initialization

    private init() {
        // Set up backup directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        backupDirectory = documentsPath.appendingPathComponent("Backups", isDirectory: true)

        // Create backup directory if needed
        try? FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)

        // Load backup list
        loadBackupList()

        // Load last backup date
        lastBackupDate = UserDefaults.standard.object(forKey: "lastBackupDate") as? Date
    }

    // MARK: - Public Methods

    /// Creates a new backup
    func createBackup(modelContext: ModelContext) async throws -> BackupInfo {
        isBackingUp = true
        defer { isBackingUp = false }

        // Fetch all data
        let placementDescriptor = FetchDescriptor<PlacementLog>()
        let placements = try modelContext.fetch(placementDescriptor)

        let customSiteDescriptor = FetchDescriptor<CustomSite>()
        let customSites = try modelContext.fetch(customSiteDescriptor)

        let settingsDescriptor = FetchDescriptor<UserSettings>()
        let settings = try modelContext.fetch(settingsDescriptor).first

        // Create backup data
        let backupData = BackupData(
            version: "1.0",
            createdAt: .now,
            placements: placements.map { PlacementBackup(from: $0) },
            customSites: customSites.map { CustomSiteBackup(from: $0) },
            settings: settings.map { SettingsBackup(from: $0) }
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(backupData)

        // Create backup file
        let filename = "backup_\(ISO8601DateFormatter().string(from: .now)).json"
            .replacingOccurrences(of: ":", with: "-")
        let fileURL = backupDirectory.appendingPathComponent(filename)

        try jsonData.write(to: fileURL)

        // Create backup info
        let info = BackupInfo(
            id: UUID(),
            filename: filename,
            fileURL: fileURL,
            createdAt: .now,
            placementCount: placements.count,
            customSiteCount: customSites.count,
            fileSize: Int64(jsonData.count)
        )

        // Update state
        backups.insert(info, at: 0)
        lastBackupDate = .now
        UserDefaults.standard.set(lastBackupDate, forKey: "lastBackupDate")

        return info
    }

    /// Restores from a backup
    func restoreBackup(_ backup: BackupInfo, modelContext: ModelContext) async throws -> RestoreResult {
        isRestoring = true
        defer { isRestoring = false }

        // Read backup file
        let data = try Data(contentsOf: backup.fileURL)

        // Decode backup
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backupData = try decoder.decode(BackupData.self, from: data)

        var restoredPlacements = 0
        var restoredCustomSites = 0
        var skippedDuplicates = 0

        // Restore custom sites first
        for siteBackup in backupData.customSites {
            let descriptor = FetchDescriptor<CustomSite>(
                predicate: #Predicate { $0.id == siteBackup.id }
            )
            let existing = try modelContext.fetch(descriptor)

            if existing.isEmpty {
                let site = CustomSite(
                    id: siteBackup.id,
                    name: siteBackup.name,
                    bodyRegion: BodyRegion(rawValue: siteBackup.bodyRegion) ?? .abdomen,
                    notes: siteBackup.notes
                )
                site.isEnabled = siteBackup.isEnabled
                modelContext.insert(site)
                restoredCustomSites += 1
            } else {
                skippedDuplicates += 1
            }
        }

        // Restore placements
        for placementBackup in backupData.placements {
            let descriptor = FetchDescriptor<PlacementLog>(
                predicate: #Predicate { $0.id == placementBackup.id }
            )
            let existing = try modelContext.fetch(descriptor)

            if existing.isEmpty {
                let placement = PlacementLog(id: placementBackup.id, placedAt: placementBackup.placedAt)
                placement.locationRawValue = placementBackup.locationRawValue
                placement.customSiteId = placementBackup.customSiteId
                placement.customSiteName = placementBackup.customSiteName
                placement.note = placementBackup.note
                modelContext.insert(placement)
                restoredPlacements += 1
            } else {
                skippedDuplicates += 1
            }
        }

        try modelContext.save()

        return RestoreResult(
            restoredPlacements: restoredPlacements,
            restoredCustomSites: restoredCustomSites,
            skippedDuplicates: skippedDuplicates
        )
    }

    /// Deletes a backup
    func deleteBackup(_ backup: BackupInfo) throws {
        try FileManager.default.removeItem(at: backup.fileURL)
        backups.removeAll { $0.id == backup.id }
    }

    /// Exports a backup file
    func exportBackup(_ backup: BackupInfo) -> URL {
        backup.fileURL
    }

    /// Imports a backup file
    func importBackup(from url: URL) throws -> BackupInfo {
        // Read and validate
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backupData = try decoder.decode(BackupData.self, from: data)

        // Copy to backup directory
        let filename = "imported_\(ISO8601DateFormatter().string(from: .now)).json"
            .replacingOccurrences(of: ":", with: "-")
        let destURL = backupDirectory.appendingPathComponent(filename)

        try data.write(to: destURL)

        let info = BackupInfo(
            id: UUID(),
            filename: filename,
            fileURL: destURL,
            createdAt: backupData.createdAt,
            placementCount: backupData.placements.count,
            customSiteCount: backupData.customSites.count,
            fileSize: Int64(data.count)
        )

        backups.insert(info, at: 0)
        return info
    }

    // MARK: - Private Methods

    private func loadBackupList() {
        backups = []

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: backupDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .creationDateKey]
        ) else { return }

        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let backup = try? JSONDecoder().decode(BackupData.self, from: data) else {
                continue
            }

            let attributes = try? file.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])

            let info = BackupInfo(
                id: UUID(),
                filename: file.lastPathComponent,
                fileURL: file,
                createdAt: backup.createdAt,
                placementCount: backup.placements.count,
                customSiteCount: backup.customSites.count,
                fileSize: Int64(attributes?.fileSize ?? 0)
            )

            backups.append(info)
        }

        backups.sort { $0.createdAt > $1.createdAt }
    }
}

// MARK: - Backup Models

struct BackupInfo: Identifiable {
    let id: UUID
    let filename: String
    let fileURL: URL
    let createdAt: Date
    let placementCount: Int
    let customSiteCount: Int
    let fileSize: Int64

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

struct RestoreResult {
    let restoredPlacements: Int
    let restoredCustomSites: Int
    let skippedDuplicates: Int
}

struct BackupData: Codable {
    let version: String
    let createdAt: Date
    let placements: [PlacementBackup]
    let customSites: [CustomSiteBackup]
    let settings: SettingsBackup?
}

struct PlacementBackup: Codable {
    let id: UUID
    let placedAt: Date
    let locationRawValue: String?
    let customSiteId: UUID?
    let customSiteName: String?
    let note: String?

    init(from placement: PlacementLog) {
        self.id = placement.id
        self.placedAt = placement.placedAt
        self.locationRawValue = placement.locationRawValue
        self.customSiteId = placement.customSiteId
        self.customSiteName = placement.customSiteName
        self.note = placement.note
    }
}

struct CustomSiteBackup: Codable {
    let id: UUID
    let name: String
    let bodyRegion: String
    let notes: String?
    let isEnabled: Bool

    init(from site: CustomSite) {
        self.id = site.id
        self.name = site.name
        self.bodyRegion = site.bodyRegion.rawValue
        self.notes = site.notes
        self.isEnabled = site.isEnabled
    }
}

struct SettingsBackup: Codable {
    let minimumRestDays: Int
    let showDisabledSitesInHistory: Bool

    init(from settings: UserSettings) {
        self.minimumRestDays = settings.minimumRestDays
        self.showDisabledSitesInHistory = settings.showDisabledSitesInHistory
    }
}

// MARK: - Backup View

struct BackupView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var backupManager = BackupManager.shared

    @State private var showingRestoreConfirmation = false
    @State private var selectedBackup: BackupInfo?
    @State private var showingResult = false
    @State private var resultMessage = ""
    @State private var showingImporter = false
    @State private var showingExporter = false
    @State private var exportURL: URL?

    var body: some View {
        List {
            // Create backup section
            Section {
                Button(action: createBackup) {
                    HStack {
                        Image(systemName: "arrow.up.doc")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Create Backup")
                                .foregroundColor(.primary)
                            if let lastDate = backupManager.lastBackupDate {
                                Text("Last backup: \(lastDate, style: .relative) ago")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if backupManager.isBackingUp {
                            ProgressView()
                        }
                    }
                }
                .disabled(backupManager.isBackingUp)

                Button(action: { showingImporter = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.green)
                        Text("Import Backup")
                            .foregroundColor(.primary)
                    }
                }
            } header: {
                Text("Backup")
            }

            // Backup list section
            Section {
                if backupManager.backups.isEmpty {
                    Text("No backups yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(backupManager.backups) { backup in
                        BackupRow(backup: backup)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteBackup(backup)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    selectedBackup = backup
                                    showingRestoreConfirmation = true
                                } label: {
                                    Label("Restore", systemImage: "arrow.counterclockwise")
                                }
                                .tint(.blue)

                                Button {
                                    exportURL = backup.fileURL
                                    showingExporter = true
                                } label: {
                                    Label("Export", systemImage: "square.and.arrow.up")
                                }
                                .tint(.orange)
                            }
                    }
                }
            } header: {
                Text("Available Backups")
            } footer: {
                Text("Swipe left to delete, right to restore or export.")
            }
        }
        .navigationTitle("Backup & Restore")
        .alert("Restore Backup?", isPresented: $showingRestoreConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Restore") {
                if let backup = selectedBackup {
                    restoreBackup(backup)
                }
            }
        } message: {
            if let backup = selectedBackup {
                Text("This will restore \(backup.placementCount) placements and \(backup.customSiteCount) custom sites. Existing data will not be deleted.")
            }
        }
        .alert("Complete", isPresented: $showingResult) {
            Button("OK") { }
        } message: {
            Text(resultMessage)
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: exportURL.map { BackupDocument(url: $0) },
            contentType: .json,
            defaultFilename: selectedBackup?.filename ?? "backup.json"
        ) { _ in }
    }

    private func createBackup() {
        Task {
            do {
                let backup = try await backupManager.createBackup(modelContext: modelContext)
                resultMessage = "Backup created with \(backup.placementCount) placements."
                showingResult = true
            } catch {
                resultMessage = "Backup failed: \(error.localizedDescription)"
                showingResult = true
            }
        }
    }

    private func restoreBackup(_ backup: BackupInfo) {
        Task {
            do {
                let result = try await backupManager.restoreBackup(backup, modelContext: modelContext)
                resultMessage = "Restored \(result.restoredPlacements) placements and \(result.restoredCustomSites) custom sites. Skipped \(result.skippedDuplicates) duplicates."
                showingResult = true
            } catch {
                resultMessage = "Restore failed: \(error.localizedDescription)"
                showingResult = true
            }
        }
    }

    private func deleteBackup(_ backup: BackupInfo) {
        try? backupManager.deleteBackup(backup)
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            do {
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }

                let backup = try backupManager.importBackup(from: url)
                resultMessage = "Imported backup with \(backup.placementCount) placements."
                showingResult = true
            } catch {
                resultMessage = "Import failed: \(error.localizedDescription)"
                showingResult = true
            }

        case .failure(let error):
            resultMessage = "Import failed: \(error.localizedDescription)"
            showingResult = true
        }
    }
}

// MARK: - Backup Row

struct BackupRow: View {
    let backup: BackupInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(backup.formattedDate)
                .font(.body)

            HStack(spacing: 12) {
                Label("\(backup.placementCount)", systemImage: "list.bullet")
                Label("\(backup.customSiteCount)", systemImage: "mappin")
                Text(backup.formattedSize)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Backup Document

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let url: URL

    init(url: URL) {
        self.url = url
    }

    init(configuration: ReadConfiguration) throws {
        url = URL(fileURLWithPath: "")
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try FileWrapper(url: url)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BackupView()
    }
}
