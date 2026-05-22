//
//  HapticFeedbackManager.swift
//  OmniSiteTracker
//
//  Haptic feedback system for enhanced user experience
//

import SwiftUI
import CoreHaptics

enum HapticPattern: String, CaseIterable {
    case success = "Success"
    case warning = "Warning"
    case error = "Error"
    case selection = "Selection"
    case impact = "Impact"
    case siteLogged = "Site Logged"
    case reminder = "Reminder"
}

@MainActor
@Observable
final class HapticFeedbackManager {
    static let shared = HapticFeedbackManager()
    
    private(set) var isHapticsEnabled = true
    private(set) var isHapticsSupported = false
    private(set) var hapticIntensity: Float = 1.0
    private var engine: CHHapticEngine?
    
    init() {
        isHapticsSupported = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        setupEngine()
        loadPreferences()
    }
    
    private func setupEngine() {
        guard isHapticsSupported else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch { print("Haptic engine error: \(error)") }
    }
    
    func play(_ pattern: HapticPattern) {
        guard isHapticsEnabled else { return }
        switch pattern {
        case .success: playNotificationHaptic(.success)
        case .warning: playNotificationHaptic(.warning)
        case .error: playNotificationHaptic(.error)
        case .selection: playSelectionHaptic()
        case .impact: playImpactHaptic(.medium)
        case .siteLogged: playCustomSitePattern()
        case .reminder: playNotificationHaptic(.warning)
        }
    }
    
    func playImpactHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isHapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred(intensity: CGFloat(hapticIntensity))
    }
    
    func playSelectionHaptic() {
        guard isHapticsEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    func playNotificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    
    private func playCustomSitePattern() {
        guard isHapticsSupported, let engine = engine else { playNotificationHaptic(.success); return }
        do {
            let events = [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: hapticIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: hapticIntensity * 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ], relativeTime: 0.1)
            ]
            let pattern = try CHHapticPattern(events: events, parameters: [])
            try engine.makePlayer(with: pattern).start(atTime: 0)
        } catch { playNotificationHaptic(.success) }
    }
    
    func setHapticsEnabled(_ enabled: Bool) {
        isHapticsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "haptics_enabled")
    }
    
    func setIntensity(_ intensity: Float) {
        hapticIntensity = intensity
        UserDefaults.standard.set(intensity, forKey: "haptic_intensity")
    }
    
    private func loadPreferences() {
        isHapticsEnabled = UserDefaults.standard.object(forKey: "haptics_enabled") as? Bool ?? true
        hapticIntensity = UserDefaults.standard.object(forKey: "haptic_intensity") as? Float ?? 1.0
    }
}

struct HapticFeedbackSettingsView: View {
    @State private var manager = HapticFeedbackManager.shared
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "waveform").font(.largeTitle).foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text("Haptic Feedback").font(.headline)
                        Text(manager.isHapticsSupported ? "Supported" : "Not Supported")
                            .font(.subheadline).foregroundStyle(manager.isHapticsSupported ? .green : .red)
                    }
                }
            }
            
            Section("Settings") {
                Toggle("Enable Haptics", isOn: Binding(get: { manager.isHapticsEnabled }, set: { manager.setHapticsEnabled($0) }))
                VStack(alignment: .leading) {
                    Text("Intensity: \(Int(manager.hapticIntensity * 100))%")
                    Slider(value: Binding(get: { manager.hapticIntensity }, set: { manager.setIntensity($0) }), in: 0.1...1.0)
                }.disabled(!manager.isHapticsEnabled)
            }
            
            Section("Test Patterns") {
                ForEach(HapticPattern.allCases, id: \.self) { pattern in
                    Button { manager.play(pattern) } label: { HStack { Text(pattern.rawValue); Spacer(); Image(systemName: "play.circle") } }
                }
            }
        }
        .navigationTitle("Haptic Feedback")
    }
}

#Preview { NavigationStack { HapticFeedbackSettingsView() } }
