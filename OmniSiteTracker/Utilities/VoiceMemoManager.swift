//
//  VoiceMemoManager.swift
//  OmniSiteTracker
//
//  Manages voice note recording for pump site documentation.
//  Allows hands-free note taking about site conditions.
//

import Foundation
import AVFoundation
import SwiftUI

/// Manages voice memo recording and playback
@MainActor
@Observable
final class VoiceMemoManager: NSObject {
    // MARK: - Singleton

    static let shared = VoiceMemoManager()

    // MARK: - Properties

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?

    private(set) var isRecording = false
    private(set) var isPlaying = false
    private(set) var recordingDuration: TimeInterval = 0
    private(set) var playbackProgress: Double = 0

    private var recordingTimer: Timer?
    private var playbackTimer: Timer?

    private let memosDirectory: URL

    // MARK: - Initialization

    private override init() {
        // Set up memos directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        memosDirectory = documentsPath.appendingPathComponent("VoiceMemos", isDirectory: true)

        super.init()

        // Create directory if needed
        try? FileManager.default.createDirectory(at: memosDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Recording

    /// Starts recording a voice memo
    func startRecording() throws -> String {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default)
        try session.setActive(true)

        let filename = "memo_\(UUID().uuidString).m4a"
        let fileURL = memosDirectory.appendingPathComponent(filename)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
        audioRecorder?.record()

        isRecording = true
        recordingDuration = 0

        // Start timer to track duration
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordingDuration += 0.1
            }
        }

        return filename
    }

    /// Stops recording and returns the filename
    func stopRecording() -> String? {
        recordingTimer?.invalidate()
        recordingTimer = nil

        guard let recorder = audioRecorder else { return nil }

        let url = recorder.url
        recorder.stop()
        audioRecorder = nil
        isRecording = false

        return url.lastPathComponent
    }

    /// Cancels recording and deletes the file
    func cancelRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil

        guard let recorder = audioRecorder else { return }

        let url = recorder.url
        recorder.stop()
        audioRecorder = nil
        isRecording = false

        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Playback

    /// Plays a voice memo
    func play(filename: String) throws {
        let fileURL = memosDirectory.appendingPathComponent(filename)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw VoiceMemoError.fileNotFound
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)

        audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
        audioPlayer?.delegate = self
        audioPlayer?.play()

        isPlaying = true
        playbackProgress = 0

        // Start timer to track progress
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let player = self?.audioPlayer else { return }
                self?.playbackProgress = player.currentTime / player.duration
            }
        }
    }

    /// Stops playback
    func stopPlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil

        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        playbackProgress = 0
    }

    /// Pauses playback
    func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
    }

    /// Resumes playback
    func resumePlayback() {
        audioPlayer?.play()
        isPlaying = true
    }

    // MARK: - File Management

    /// Gets the URL for a memo file
    func getMemoURL(filename: String) -> URL {
        memosDirectory.appendingPathComponent(filename)
    }

    /// Gets the duration of a memo
    func getDuration(filename: String) -> TimeInterval? {
        let fileURL = memosDirectory.appendingPathComponent(filename)

        guard let player = try? AVAudioPlayer(contentsOf: fileURL) else {
            return nil
        }

        return player.duration
    }

    /// Deletes a memo file
    func deleteMemo(filename: String) throws {
        let fileURL = memosDirectory.appendingPathComponent(filename)
        try FileManager.default.removeItem(at: fileURL)
    }

    /// Lists all memo files
    func listMemos() -> [String] {
        let files = try? FileManager.default.contentsOfDirectory(at: memosDirectory, includingPropertiesForKeys: nil)
        return files?.map(\.lastPathComponent).filter { $0.hasSuffix(".m4a") } ?? []
    }
}

// MARK: - AVAudioPlayerDelegate

extension VoiceMemoManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.stopPlayback()
        }
    }
}

// MARK: - Errors

enum VoiceMemoError: LocalizedError {
    case fileNotFound
    case recordingFailed
    case playbackFailed

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Voice memo file not found"
        case .recordingFailed:
            return "Failed to start recording"
        case .playbackFailed:
            return "Failed to play voice memo"
        }
    }
}

// MARK: - Voice Memo Recorder View

struct VoiceMemoRecorderView: View {
    @State private var voiceMemoManager = VoiceMemoManager.shared
    @State private var currentFilename: String?
    @Binding var savedFilename: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text(voiceMemoManager.isRecording ? "Recording..." : "Record Voice Note")
                .font(.headline)

            // Waveform / Duration display
            VStack(spacing: 8) {
                if voiceMemoManager.isRecording {
                    // Recording indicator
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.red)
                                .frame(width: 4, height: CGFloat.random(in: 10...40))
                                .animation(.easeInOut(duration: 0.2).repeatForever(), value: voiceMemoManager.recordingDuration)
                        }
                    }
                    .frame(height: 50)
                } else {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                }

                // Duration
                Text(formatDuration(voiceMemoManager.recordingDuration))
                    .font(.title)
                    .monospacedDigit()
            }
            .frame(height: 100)

            // Controls
            HStack(spacing: 40) {
                // Cancel button
                Button(action: {
                    if voiceMemoManager.isRecording {
                        voiceMemoManager.cancelRecording()
                    }
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                }

                // Record/Stop button
                Button(action: toggleRecording) {
                    ZStack {
                        Circle()
                            .fill(voiceMemoManager.isRecording ? Color.red.opacity(0.2) : Color.red)
                            .frame(width: 80, height: 80)

                        if voiceMemoManager.isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.red)
                                .frame(width: 30, height: 30)
                        } else {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 70, height: 70)
                        }
                    }
                }

                // Done button
                Button(action: saveRecording) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(voiceMemoManager.isRecording && voiceMemoManager.recordingDuration > 0.5 ? .green : .gray)
                }
                .disabled(!voiceMemoManager.isRecording || voiceMemoManager.recordingDuration < 0.5)
            }

            Text("Tap to record, tap again to stop")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private func toggleRecording() {
        if voiceMemoManager.isRecording {
            _ = voiceMemoManager.stopRecording()
        } else {
            currentFilename = try? voiceMemoManager.startRecording()
        }
    }

    private func saveRecording() {
        if let filename = voiceMemoManager.stopRecording() {
            savedFilename = filename
        }
        dismiss()
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let tenths = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }
}

// MARK: - Voice Memo Player View

struct VoiceMemoPlayerView: View {
    let filename: String
    @State private var voiceMemoManager = VoiceMemoManager.shared
    @State private var duration: TimeInterval?
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        HStack(spacing: 12) {
            // Play/Pause button
            Button(action: togglePlayback) {
                Image(systemName: voiceMemoManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title)
                    .foregroundColor(.blue)
            }

            // Progress
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: voiceMemoManager.playbackProgress)
                    .tint(.blue)

                if let duration = duration {
                    Text(formatDuration(duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Delete button
            Button(action: deleteMemo) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
            duration = voiceMemoManager.getDuration(filename: filename)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func togglePlayback() {
        if voiceMemoManager.isPlaying {
            voiceMemoManager.pausePlayback()
        } else {
            do {
                try voiceMemoManager.play(filename: filename)
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }

    private func deleteMemo() {
        voiceMemoManager.stopPlayback()
        try? voiceMemoManager.deleteMemo(filename: filename)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        VoiceMemoRecorderView(savedFilename: .constant(nil))
    }
}
