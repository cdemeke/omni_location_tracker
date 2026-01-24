//
//  AccessibilityOptionsView.swift
//  OmniSiteTracker
//
//  Comprehensive accessibility settings
//

import SwiftUI

@MainActor
@Observable
final class AccessibilitySettings {
    var largeText = false
    var boldText = false
    var reduceMotion = false
    var highContrast = false
    var voiceOverHints = true
    var buttonShapes = false
    var increaseContrast = false
    
    var fontScale: Double = 1.0
}

struct AccessibilityOptionsView: View {
    @State private var settings = AccessibilitySettings()
    
    var body: some View {
        List {
            Section("Text") {
                Toggle("Large Text", isOn: $settings.largeText)
                Toggle("Bold Text", isOn: $settings.boldText)
                
                VStack(alignment: .leading) {
                    Text("Font Scale: \(String(format: "%.1f", settings.fontScale))x")
                    Slider(value: $settings.fontScale, in: 0.8...2.0, step: 0.1)
                }
            }
            
            Section("Display") {
                Toggle("Increase Contrast", isOn: $settings.increaseContrast)
                Toggle("Button Shapes", isOn: $settings.buttonShapes)
                Toggle("High Contrast Mode", isOn: $settings.highContrast)
            }
            
            Section("Motion") {
                Toggle("Reduce Motion", isOn: $settings.reduceMotion)
            }
            
            Section("VoiceOver") {
                Toggle("Speak Hints", isOn: $settings.voiceOverHints)
            }
            
            Section {
                Button("Reset to Defaults") {
                    settings = AccessibilitySettings()
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Accessibility")
    }
}

#Preview {
    NavigationStack {
        AccessibilityOptionsView()
    }
}
