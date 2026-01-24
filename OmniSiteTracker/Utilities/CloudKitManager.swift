//
//  CloudKitManager.swift
//  OmniSiteTracker
//
//  Manages iCloud sync using CloudKit.
//  Provides automatic sync of placement data across devices.
//

import Foundation
import CloudKit
import SwiftData
import Combine

/// Manages iCloud synchronization for placement data
@MainActor
@Observable
final class CloudKitManager {
    // MARK: - Singleton

    static let shared = CloudKitManager()

    // MARK: - Properties

    /// Current sync status
    private(set) var syncStatus: SyncStatus = .idle

    /// Last successful sync date
    private(set) var lastSyncDate: Date?

    /// Number of pending changes to sync
    private(set) var pendingChangesCount: Int = 0

    /// Whether iCloud is available
    private(set) var isCloudAvailable: Bool = false

    /// Error message if sync failed
    private(set) var errorMessage: String?

    /// CloudKit container
    private let container: CKContainer

    /// Private database
    private let privateDatabase: CKDatabase

    /// Record zone for placements
    private let recordZone: CKRecordZone

    /// Subscription for remote changes
    private var subscription: CKSubscription?

    /// UserDefaults for sync metadata
    private let defaults = UserDefaults.standard

    /// Key for last sync token
    private let lastSyncTokenKey = "CloudKit_LastSyncToken"

    // MARK: - Sync Status

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case uploading(progress: Double)
        case downloading(progress: Double)
        case success
        case error(String)
        case offline

        var description: String {
            switch self {
            case .idle:
                return "Ready to sync"
            case .syncing:
                return "Syncing..."
            case .uploading(let progress):
                return "Uploading \(Int(progress * 100))%"
            case .downloading(let progress):
                return "Downloading \(Int(progress * 100))%"
            case .success:
                return "Synced"
            case .error(let message):
                return "Error: \(message)"
            case .offline:
                return "Offline"
            }
        }

        var iconName: String {
            switch self {
            case .idle: return "icloud"
            case .syncing, .uploading, .downloading: return "icloud.and.arrow.up"
            case .success: return "checkmark.icloud"
            case .error: return "exclamationmark.icloud"
            case .offline: return "icloud.slash"
            }
        }

        var isInProgress: Bool {
            switch self {
            case .syncing, .uploading, .downloading:
                return true
            default:
                return false
            }
        }
    }

    // MARK: - Initialization

    private init() {
        // Use default container - in production, use your app's container identifier
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase
        recordZone = CKRecordZone(zoneName: "OmniSiteTrackerZone")

        // Load last sync date
        lastSyncDate = defaults.object(forKey: "CloudKit_LastSyncDate") as? Date

        // Check initial availability
        Task {
            await checkCloudAvailability()
        }

        // Setup notifications for account changes
        setupAccountChangeObserver()
    }

    // MARK: - Public Methods

    /// Checks if iCloud is available
    func checkCloudAvailability() async {
        do {
            let status = try await container.accountStatus()
            isCloudAvailable = status == .available

            if !isCloudAvailable {
                syncStatus = .offline
            }
        } catch {
            isCloudAvailable = false
            syncStatus = .offline
            errorMessage = error.localizedDescription
        }
    }

    /// Initializes the CloudKit zone if needed
    func initializeZone() async throws {
        guard isCloudAvailable else {
            throw CloudKitError.notAvailable
        }

        do {
            _ = try await privateDatabase.save(recordZone)
        } catch let error as CKError {
            // Zone already exists is fine
            if error.code != .serverRecordChanged {
                throw error
            }
        }
    }

    /// Performs a full sync
    func performSync(modelContext: ModelContext) async {
        guard isCloudAvailable else {
            syncStatus = .offline
            return
        }

        guard !syncStatus.isInProgress else { return }

        syncStatus = .syncing
        errorMessage = nil

        do {
            // Ensure zone exists
            try await initializeZone()

            // Upload local changes
            syncStatus = .uploading(progress: 0)
            try await uploadLocalChanges(modelContext: modelContext)

            // Download remote changes
            syncStatus = .downloading(progress: 0)
            try await downloadRemoteChanges(modelContext: modelContext)

            // Save sync date
            lastSyncDate = Date()
            defaults.set(lastSyncDate, forKey: "CloudKit_LastSyncDate")

            syncStatus = .success
            pendingChangesCount = 0

            // Reset to idle after a delay
            Task {
                try? await Task.sleep(for: .seconds(3))
                if syncStatus == .success {
                    syncStatus = .idle
                }
            }
        } catch {
            syncStatus = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    /// Saves a placement to CloudKit
    func savePlacement(_ placement: PlacementLog) async throws {
        guard isCloudAvailable else {
            pendingChangesCount += 1
            throw CloudKitError.notAvailable
        }

        let record = placementToRecord(placement)

        do {
            _ = try await privateDatabase.save(record)
        } catch {
            pendingChangesCount += 1
            throw error
        }
    }

    /// Deletes a placement from CloudKit
    func deletePlacement(_ placement: PlacementLog) async throws {
        guard isCloudAvailable else {
            pendingChangesCount += 1
            throw CloudKitError.notAvailable
        }

        let recordID = CKRecord.ID(recordName: placement.id.uuidString, zoneID: recordZone.zoneID)

        try await privateDatabase.deleteRecord(withID: recordID)
    }

    /// Registers for remote change notifications
    func registerForRemoteNotifications() async throws {
        guard isCloudAvailable else { return }

        let subscription = CKDatabaseSubscription(subscriptionID: "placement-changes")

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        do {
            self.subscription = try await privateDatabase.save(subscription)
        } catch let error as CKError {
            // Subscription already exists is fine
            if error.code != .serverRecordChanged {
                throw error
            }
        }
    }

    // MARK: - Private Methods

    private func setupAccountChangeObserver() {
        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.checkCloudAvailability()
            }
        }
    }

    private func uploadLocalChanges(modelContext: ModelContext) async throws {
        let descriptor = FetchDescriptor<PlacementLog>(
            predicate: #Predicate { $0.needsCloudSync == true },
            sortBy: [SortDescriptor(\.placedAt)]
        )

        let placements = try modelContext.fetch(descriptor)
        let total = Double(placements.count)

        for (index, placement) in placements.enumerated() {
            let record = placementToRecord(placement)
            _ = try await privateDatabase.save(record)

            placement.needsCloudSync = false
            placement.cloudSyncedAt = Date()

            syncStatus = .uploading(progress: Double(index + 1) / max(total, 1))
        }

        try modelContext.save()
    }

    private func downloadRemoteChanges(modelContext: ModelContext) async throws {
        // Fetch all records from the zone
        let query = CKQuery(recordType: "PlacementLog", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "placedAt", ascending: false)]

        let results = try await privateDatabase.records(matching: query, inZoneWith: recordZone.zoneID)
        let records = results.matchResults.compactMap { try? $0.1.get() }

        let total = Double(records.count)

        for (index, record) in records.enumerated() {
            // Check if we already have this record
            let recordID = UUID(uuidString: record.recordID.recordName) ?? UUID()

            let descriptor = FetchDescriptor<PlacementLog>(
                predicate: #Predicate { $0.id == recordID }
            )

            let existingPlacements = try modelContext.fetch(descriptor)

            if let existing = existingPlacements.first {
                // Update if remote is newer
                if let remoteModified = record.modificationDate,
                   let localModified = existing.cloudSyncedAt,
                   remoteModified > localModified {
                    updatePlacementFromRecord(existing, record: record)
                }
            } else {
                // Create new local record
                let placement = createPlacementFromRecord(record)
                modelContext.insert(placement)
            }

            syncStatus = .downloading(progress: Double(index + 1) / max(total, 1))
        }

        try modelContext.save()
    }

    private func placementToRecord(_ placement: PlacementLog) -> CKRecord {
        let recordID = CKRecord.ID(recordName: placement.id.uuidString, zoneID: recordZone.zoneID)
        let record = CKRecord(recordType: "PlacementLog", recordID: recordID)

        record["placedAt"] = placement.placedAt as CKRecordValue
        record["locationRawValue"] = placement.locationRawValue as CKRecordValue?
        record["customSiteName"] = placement.customSiteName as CKRecordValue?
        record["note"] = placement.note as CKRecordValue?
        record["wasRecommended"] = (placement.wasRecommended ? 1 : 0) as CKRecordValue
        record["reminderScheduled"] = (placement.reminderScheduled ? 1 : 0) as CKRecordValue
        record["photoFileName"] = placement.photoFileName as CKRecordValue?
        record["profileId"] = placement.profileId?.uuidString as CKRecordValue?

        return record
    }

    private func updatePlacementFromRecord(_ placement: PlacementLog, record: CKRecord) {
        placement.placedAt = record["placedAt"] as? Date ?? placement.placedAt
        placement.locationRawValue = record["locationRawValue"] as? String
        placement.customSiteName = record["customSiteName"] as? String
        placement.note = record["note"] as? String
        placement.wasRecommended = (record["wasRecommended"] as? Int ?? 0) == 1
        placement.reminderScheduled = (record["reminderScheduled"] as? Int ?? 0) == 1
        placement.photoFileName = record["photoFileName"] as? String

        if let profileIdString = record["profileId"] as? String {
            placement.profileId = UUID(uuidString: profileIdString)
        }

        placement.cloudSyncedAt = Date()
        placement.needsCloudSync = false
    }

    private func createPlacementFromRecord(_ record: CKRecord) -> PlacementLog {
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let placedAt = record["placedAt"] as? Date ?? Date()

        let placement = PlacementLog(id: id, placedAt: placedAt)
        placement.locationRawValue = record["locationRawValue"] as? String
        placement.customSiteName = record["customSiteName"] as? String
        placement.note = record["note"] as? String
        placement.wasRecommended = (record["wasRecommended"] as? Int ?? 0) == 1
        placement.reminderScheduled = (record["reminderScheduled"] as? Int ?? 0) == 1
        placement.photoFileName = record["photoFileName"] as? String

        if let profileIdString = record["profileId"] as? String {
            placement.profileId = UUID(uuidString: profileIdString)
        }

        placement.cloudSyncedAt = Date()
        placement.needsCloudSync = false

        return placement
    }
}

// MARK: - Errors

enum CloudKitError: LocalizedError {
    case notAvailable
    case recordNotFound
    case syncFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "iCloud is not available. Please sign in to iCloud in Settings."
        case .recordNotFound:
            return "Record not found in iCloud."
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        }
    }
}

// MARK: - Sync Conflict Resolution

enum ConflictResolution {
    case keepLocal
    case keepRemote
    case merge
}

extension CloudKitManager {
    /// Resolves a sync conflict between local and remote data
    func resolveConflict(
        local: PlacementLog,
        remote: CKRecord,
        resolution: ConflictResolution
    ) -> PlacementLog {
        switch resolution {
        case .keepLocal:
            return local
        case .keepRemote:
            updatePlacementFromRecord(local, record: remote)
            return local
        case .merge:
            // Keep the most recent data for each field
            if let remoteDate = remote["placedAt"] as? Date,
               remoteDate > local.placedAt {
                local.placedAt = remoteDate
            }

            // Keep notes from both if different
            if let remoteNote = remote["note"] as? String,
               let localNote = local.note,
               remoteNote != localNote {
                local.note = "\(localNote)\n---\n\(remoteNote)"
            }

            return local
        }
    }
}
