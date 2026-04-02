//
//  VoiceCommandsView.swift
//  OmniSiteTracker
//
//  Voice command recognition for hands-free operation
//

import SwiftUI
import Speech
import AVFoundation

@MainActor
@Observable
final class VoiceCommandManager: NSObject {
    static let shared = VoiceCommandManager()
    
    private(set) var isListening = false
    private(set) var recognizedText = ""
    private(set) var lastCommand: VoiceCommand?
    private(set) var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    enum VoiceCommand: String, CaseIterable {
        case logSite = "log site"
        case showHistory = "show history"
        case viewStats = "view stats"
        case help = "help"
        
        var response: String {
            switch self {
            case .logSite: return "Opening site logger"
            case .showHistory: return "Showing history"
            case .viewStats: return "Displaying statistics"
            case .help: return "Say: log site, show history, or view stats"
            }
        }
    }
    
    override init() {
        super.init()
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in self.authorizationStatus = status }
        }
    }
    
    func startListening() throws {
        guard !isListening, authorizationStatus == .authorized else { return }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { [weak self] result, _ in
            Task { @MainActor in
                if let text = result?.bestTranscription.formattedString {
                    self?.recognizedText = text
                    self?.processCommand(text)
                }
            }
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNode.outputFormat(forBus: 0)) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        isListening = true
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isListening = false
    }
    
    private func processCommand(_ text: String) {
        let lowercased = text.lowercased()
        for command in VoiceCommand.allCases where lowercased.contains(command.rawValue) {
            lastCommand = command
            break
        }
    }
}

struct VoiceCommandsView: View {
    @State private var manager = VoiceCommandManager.shared
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "waveform.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(manager.isListening ? .green : .blue)
                    VStack(alignment: .leading) {
                        Text("Voice Commands").font(.headline)
                        Text(manager.authorizationStatus == .authorized ? (manager.isListening ? "Listening..." : "Ready") : "Permission needed")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
            
            Section {
                Button {
                    if manager.isListening { manager.stopListening() }
                    else { try? manager.startListening() }
                } label: {
                    Label(manager.isListening ? "Stop" : "Start Listening", systemImage: manager.isListening ? "stop.circle.fill" : "mic.circle.fill")
                        .frame(maxWidth: .infinity)
                }.disabled(manager.authorizationStatus != .authorized)
            }
            
            if !manager.recognizedText.isEmpty {
                Section("Recognized") { Text(manager.recognizedText) }
            }
            
            Section("Commands") {
                ForEach(VoiceCommandManager.VoiceCommand.allCases, id: \.self) { cmd in
                    HStack {
                        Text("\"\(cmd.rawValue)\"").font(.system(.body, design: .monospaced))
                        Spacer()
                        if manager.lastCommand == cmd { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
                    }
                }
            }
        }
        .navigationTitle("Voice Commands")
    }
}

#Preview { NavigationStack { VoiceCommandsView() } }
