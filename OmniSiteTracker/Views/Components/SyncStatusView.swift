//
//  SyncStatusView.swift
//  OmniSiteTracker
//
//  UI components for displaying iCloud sync status.
//  Shows sync progress, last sync time, and sync controls.
//

import SwiftUI

/// View showing iCloud sync status and controls
struct SyncStatusView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var cloudKitManager = CloudKitManager.shared
    @State private var showingDetails = false
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 0) {
            // Main sync status card
            Button(action: { showingDetails.toggle() }) {
                HStack(spacing: 12) {
                    // Status icon
                    syncIcon
                        .font(.title2)
                        .foregroundColor(iconColor)
                        .rotationEffect(Angle(degrees: isAnimating && cloudKitManager.syncStatus.isInProgress ? 360 : 0))
                        .animation(
                            cloudKitManager.syncStatus.isInProgress
                                ? Animation.linear(duration: 2).repeatForever(autoreverses: false)
                                : .default,
                            value: isAnimating
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(cloudKitManager.syncStatus.description)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)

                        if let lastSync = cloudKitManager.lastSyncDate {
                            Text("Last synced \(lastSync, style: .relative) ago")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        } else {
                            Text("Never synced")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Spacer()

                    // Pending count badge
                    if cloudKitManager.pendingChangesCount > 0 {
                        Text("\(cloudKitManager.pendingChangesCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }

                    Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            // Expanded details
            if showingDetails {
                VStack(spacing: 12) {
                    Divider()

                    // Cloud availability
                    HStack {
                        Image(systemName: cloudKitManager.isCloudAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(cloudKitManager.isCloudAvailable ? .green : .red)
                        Text("iCloud \(cloudKitManager.isCloudAvailable ? "Available" : "Unavailable")")
                            .font(.subheadline)
                        Spacer()
                    }

                    // Error message if any
                    if let error = cloudKitManager.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Sync button
                    Button(action: {
                        Task {
                            await cloudKitManager.performSync(modelContext: modelContext)
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Sync Now")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            cloudKitManager.syncStatus.isInProgress
                                ? Color.gray
                                : Color.appAccent
                        )
                        .cornerRadius(10)
                    }
                    .disabled(cloudKitManager.syncStatus.isInProgress || !cloudKitManager.isCloudAvailable)
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingDetails)
        .onAppear {
            isAnimating = true
            Task {
                await cloudKitManager.checkCloudAvailability()
            }
        }
    }

    private var syncIcon: Image {
        Image(systemName: cloudKitManager.syncStatus.iconName)
    }

    private var iconColor: Color {
        switch cloudKitManager.syncStatus {
        case .success:
            return .green
        case .error, .offline:
            return .red
        case .syncing, .uploading, .downloading:
            return .blue
        default:
            return .textSecondary
        }
    }
}

// MARK: - Compact Sync Status

/// Compact sync status indicator for navigation bar
struct CompactSyncStatusView: View {
    @State private var cloudKitManager = CloudKitManager.shared

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: cloudKitManager.syncStatus.iconName)
                .font(.caption)

            if cloudKitManager.pendingChangesCount > 0 {
                Text("\(cloudKitManager.pendingChangesCount)")
                    .font(.caption2)
            }
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch cloudKitManager.syncStatus {
        case .success:
            return .green
        case .error, .offline:
            return .red
        case .syncing, .uploading, .downloading:
            return .blue
        default:
            return .secondary
        }
    }
}

// MARK: - Sync Progress View

/// Shows detailed sync progress
struct SyncProgressView: View {
    let status: CloudKitManager.SyncStatus

    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: progress)
                .tint(.appAccent)

            Text(status.description)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
    }

    private var progress: Double {
        switch status {
        case .uploading(let p), .downloading(let p):
            return p
        case .syncing:
            return 0.5
        case .success:
            return 1.0
        default:
            return 0
        }
    }
}

// MARK: - iCloud Settings Section

/// Settings section for iCloud sync
struct iCloudSettingsSection: View {
    @AppStorage("icloud_syncEnabled") private var syncEnabled = true
    @AppStorage("icloud_syncPhotos") private var syncPhotos = false
    @AppStorage("icloud_wifiOnly") private var wifiOnly = false

    @Environment(\.modelContext) private var modelContext
    @State private var cloudKitManager = CloudKitManager.shared
    @State private var showingResetConfirmation = false

    var body: some View {
        Section {
            // Sync toggle
            Toggle(isOn: $syncEnabled) {
                Label("iCloud Sync", systemImage: "icloud")
            }

            if syncEnabled {
                // Sync status
                SyncStatusView()
                    .padding(.vertical, 4)

                // Sync photos toggle
                Toggle(isOn: $syncPhotos) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sync Photos")
                        Text("Upload placement photos to iCloud")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                // WiFi only toggle
                Toggle(isOn: $wifiOnly) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("WiFi Only")
                        Text("Only sync when connected to WiFi")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                // Manual sync button
                Button(action: {
                    Task {
                        await cloudKitManager.performSync(modelContext: modelContext)
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Sync Now")
                        Spacer()
                        if cloudKitManager.syncStatus.isInProgress {
                            ProgressView()
                        }
                    }
                }
                .disabled(cloudKitManager.syncStatus.isInProgress)

                // Reset sync data button
                Button(role: .destructive) {
                    showingResetConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Reset iCloud Data")
                        Spacer()
                    }
                }
            }
        } header: {
            Text("iCloud")
        } footer: {
            Text("Your placement data is synced securely to your private iCloud account and available on all your devices.")
        }
        .alert("Reset iCloud Data?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                // Reset sync data
                UserDefaults.standard.removeObject(forKey: "CloudKit_LastSyncDate")
                UserDefaults.standard.removeObject(forKey: "CloudKit_LastSyncToken")
            }
        } message: {
            Text("This will remove all synced data from iCloud. Local data will remain on this device.")
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        SyncStatusView()
        CompactSyncStatusView()
    }
    .padding()
    .background(Color.appBackground)
}
