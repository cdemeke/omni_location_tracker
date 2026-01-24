//
//  VoiceCommandsView.swift
//  OmniSiteTracker
//
//  Voice control for hands-free operation
//

import SwiftUI
import Speech

@MainActor
@Observable
final class VoiceCommandManager: NSObject {
    var isListening = false
    var lastCommand = ""
    var isAuthorized = false
    var availableCommands: [VoiceCommand] = []
    
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    struct VoiceCommand: Identifiable {
        let id = UUID()
        let phrase: String
        let action: String
        let example: String
    }
    
    override init() {
        super.init()
        availableCommands = [
            VoiceCommand(phrase: "Log site", action: "Log a new placement", example: "\"Log site left arm\""),
            VoiceCommand(phrase: "Show history", action: "Open history view", example: "\"Show my history\""),
            VoiceCommand(phrase: "Next suggestion", action: "Get next site suggestion", example: "\"Whats my next site\""),
            VoiceCommand(phrase: "Add note", action: "Add a note to last entry", example: "\"Add note feeling good\""),
            VoiceCommand(phrase: "Set reminder", action: "Create a reminder", example: "\"Remind me in 3 days\"")
        ]
    }
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.isAuthorized = status == .authorized
            }
        }
    }
    
    func startListening() {
        guard isAuthorized else { return }
        isListening = true
        // In production, start speech recognition
    }
    
    func stopListening() {
        isListening = false
    }
}

struct VoiceCommandsView: View {
    @State private var manager = VoiceCommandManager()
    
    var body: some View {
        List {
            Section {
                if manager.isAuthorized {
                    Button {
                        if manager.isListening {
                            manager.stopListening()
                        } else {
                            manager.startListening()
                        }
                    } label: {
                        HStack {
                            Image(systemName: manager.isListening ? "mic.fill" : "mic")
                                .foregroundStyle(manager.isListening ? .red : .blue)
                            Text(manager.isListening ? "Listening..." : "Start Voice Control")
                        }
                    }
                } else {
                    Button {
                        manager.requestAuthorization()
                    } label: {
                        Label("Enable Voice Control", systemImage: "mic.badge.plus")
                    }
                }
            }
            
            if !manager.lastCommand.isEmpty {
                Section("Last Command") {
                    Text(manager.lastCommand)
                        .font(.system(.body, design: .monospaced))
                }
            }
            
            Section("Available Commands") {
                ForEach(manager.availableCommands) { command in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(command.phrase)
                            .font(.headline)
                        Text(command.action)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(command.example)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Voice Commands")
        .onAppear {
            manager.requestAuthorization()
        }
    }
}

#Preview {
    NavigationStack {
        VoiceCommandsView()
    }
}
