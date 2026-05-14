//
//  FocusModeView.swift
//  OmniSiteTracker
//
//  Distraction-free logging mode
//

import SwiftUI

@MainActor
@Observable
final class FocusModeManager {
    var isEnabled = false
    var hideNavigation = true
    var hideStats = true
    var simplifiedUI = true
    var largeButtons = true
    var autoExit = true
    var autoExitMinutes = 5
}

struct FocusModeView: View {
    @State private var manager = FocusModeManager()
    
    var body: some View {
        List {
            Section {
                Toggle("Enable Focus Mode", isOn: $manager.isEnabled)
            } footer: {
                Text("Focus Mode provides a simplified interface for quick logging.")
            }
            
            if manager.isEnabled {
                Section("Display") {
                    Toggle("Hide Navigation", isOn: $manager.hideNavigation)
                    Toggle("Hide Statistics", isOn: $manager.hideStats)
                    Toggle("Simplified UI", isOn: $manager.simplifiedUI)
                    Toggle("Large Buttons", isOn: $manager.largeButtons)
                }
                
                Section("Behavior") {
                    Toggle("Auto-Exit Focus Mode", isOn: $manager.autoExit)
                    
                    if manager.autoExit {
                        Stepper("Exit after \(manager.autoExitMinutes) minutes", value: $manager.autoExitMinutes, in: 1...30)
                    }
                }
                
                Section("Preview") {
                    FocusModePreview()
                }
            }
        }
        .navigationTitle("Focus Mode")
    }
}

struct FocusModePreview: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Quick Log")
                .font(.title)
                .bold()
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(["Left Arm", "Right Arm", "Left Thigh", "Right Thigh"], id: \.self) { site in
                    Button(site) {}
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            }
            
            Button("Exit Focus Mode") {}
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        FocusModeView()
    }
}
