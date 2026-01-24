//
//  SharePlayManager.swift
//  OmniSiteTracker
//
//  Enables SharePlay for real-time site status sharing during FaceTime.
//  Caregivers can view placement status and recommendations.
//

import Foundation
import GroupActivities
import SwiftUI
import Combine

// MARK: - Group Activity

/// SharePlay activity for sharing site status
struct SiteStatusActivity: GroupActivity {
    static let activityIdentifier = "com.omnisite.tracker.shareplay"

    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = "Share Site Status"
        metadata.subtitle = "View pump site status together"
        metadata.type = .generic
        return metadata
    }
}

// MARK: - Shared State

/// State shared during SharePlay session
struct SharedSiteState: Codable {
    let recommendedSite: String
    let daysSinceUse: Int?
    let recentPlacements: [SharedPlacement]
    let timestamp: Date

    struct SharedPlacement: Codable {
        let site: String
        let date: Date
        let daysSince: Int
    }
}

// MARK: - SharePlay Manager

/// Manages SharePlay sessions for the app
@MainActor
@Observable
final class SharePlayManager {
    // MARK: - Singleton

    static let shared = SharePlayManager()

    // MARK: - Properties

    /// Whether SharePlay is available
    var isSharePlayAvailable: Bool {
        groupSession != nil
    }

    /// Current shared state
    private(set) var sharedState: SharedSiteState?

    /// Whether we're the host (sharing data)
    private(set) var isHost: Bool = false

    /// Number of participants
    private(set) var participantCount: Int = 0

    /// SharePlay session
    private var groupSession: GroupSession<SiteStatusActivity>?

    /// Messenger for sending messages
    private var messenger: GroupSessionMessenger?

    /// Subscriptions
    private var subscriptions = Set<AnyCancellable>()

    /// Tasks
    private var tasks = Set<Task<Void, Never>>()

    // MARK: - Initialization

    private init() {
        // Listen for group sessions
        Task {
            for await session in SiteStatusActivity.sessions() {
                await configureSession(session)
            }
        }
    }

    // MARK: - Public Methods

    /// Starts a SharePlay session
    func startSharing() async throws {
        let activity = SiteStatusActivity()

        switch await activity.prepareForActivation() {
        case .activationPreferred:
            _ = try await activity.activate()
        case .activationDisabled:
            throw SharePlayError.disabled
        case .cancelled:
            throw SharePlayError.cancelled
        @unknown default:
            throw SharePlayError.unknown
        }
    }

    /// Ends the current SharePlay session
    func stopSharing() {
        groupSession?.end()
        groupSession = nil
        messenger = nil
        sharedState = nil
        isHost = false
        participantCount = 0
    }

    /// Updates the shared state (host only)
    func updateSharedState(
        recommendedSite: String,
        daysSinceUse: Int?,
        recentPlacements: [(site: String, date: Date, daysSince: Int)]
    ) async {
        guard isHost, let messenger = messenger else { return }

        let state = SharedSiteState(
            recommendedSite: recommendedSite,
            daysSinceUse: daysSinceUse,
            recentPlacements: recentPlacements.map {
                SharedSiteState.SharedPlacement(site: $0.site, date: $0.date, daysSince: $0.daysSince)
            },
            timestamp: .now
        )

        sharedState = state

        do {
            try await messenger.send(state)
        } catch {
            print("Failed to send state: \(error)")
        }
    }

    // MARK: - Private Methods

    private func configureSession(_ session: GroupSession<SiteStatusActivity>) async {
        groupSession = session
        messenger = GroupSessionMessenger(session: session)

        // Track participants
        session.$activeParticipants
            .sink { [weak self] participants in
                Task { @MainActor in
                    self?.participantCount = participants.count
                    // First participant is typically the host
                    self?.isHost = participants.first?.id == session.localParticipant.id
                }
            }
            .store(in: &subscriptions)

        // Handle session state
        session.$state
            .sink { [weak self] state in
                if case .invalidated = state {
                    Task { @MainActor in
                        self?.stopSharing()
                    }
                }
            }
            .store(in: &subscriptions)

        // Receive messages
        let task = Task {
            guard let messenger = messenger else { return }
            for await (state, _) in messenger.messages(of: SharedSiteState.self) {
                await MainActor.run {
                    self.sharedState = state
                }
            }
        }
        tasks.insert(task)

        // Join session
        session.join()
    }
}

// MARK: - Errors

enum SharePlayError: LocalizedError {
    case disabled
    case cancelled
    case unknown

    var errorDescription: String? {
        switch self {
        case .disabled:
            return "SharePlay is disabled"
        case .cancelled:
            return "SharePlay was cancelled"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - SharePlay View

struct SharePlayView: View {
    @State private var sharePlayManager = SharePlayManager.shared
    @State private var isStartingSession = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "shareplay")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)

                Text("SharePlay")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Share your site status with caregivers during a FaceTime call")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            // Session status
            if sharePlayManager.isSharePlayAvailable {
                VStack(spacing: 16) {
                    // Participants
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("\(sharePlayManager.participantCount) participants")
                    }
                    .font(.headline)
                    .foregroundColor(.green)

                    // Role
                    Text(sharePlayManager.isHost ? "You are sharing" : "Viewing shared data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Shared state preview
                    if let state = sharePlayManager.sharedState {
                        SharedStateCard(state: state)
                    }

                    // Stop button
                    Button(action: {
                        sharePlayManager.stopSharing()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("End SharePlay")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                }
            } else {
                // Start button
                Button(action: startSession) {
                    HStack {
                        if isStartingSession {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "shareplay")
                        }
                        Text("Start SharePlay")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(12)
                }
                .disabled(isStartingSession)
                .padding(.horizontal)
            }

            Spacer()

            // Instructions
            VStack(alignment: .leading, spacing: 12) {
                InstructionRow(number: 1, text: "Start a FaceTime call with your caregiver")
                InstructionRow(number: 2, text: "Tap 'Start SharePlay' to share your screen")
                InstructionRow(number: 3, text: "They'll see your current site status and recommendations")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding()
        }
        .alert("SharePlay Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func startSession() {
        isStartingSession = true
        Task {
            do {
                try await sharePlayManager.startSharing()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            isStartingSession = false
        }
    }
}

// MARK: - Shared State Card

struct SharedStateCard: View {
    let state: SharedSiteState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recommended Site")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(state.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(state.recommendedSite)
                .font(.title2)
                .fontWeight(.bold)

            if let days = state.daysSinceUse {
                Text("\(days) days since last use")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Divider()

            Text("Recent Placements")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(state.recentPlacements.prefix(3), id: \.date) { placement in
                HStack {
                    Text(placement.site)
                        .font(.body)
                    Spacer()
                    Text("\(placement.daysSince)d ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Instruction Row

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.purple)
                .clipShape(Circle())

            Text(text)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview

#Preview {
    SharePlayView()
}
