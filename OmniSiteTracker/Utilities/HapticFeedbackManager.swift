//
//  HapticFeedbackManager.swift
//  OmniSiteTracker
//
//  Customizable haptic feedback for app interactions.
//

import Foundation
import UIKit
import SwiftUI

@MainActor
@Observable
final class HapticFeedbackManager {
    static let shared = HapticFeedbackManager()
    
    @AppStorage("haptics_enabled") var hapticsEnabled = true
    @AppStorage("haptics_intensity") var intensity: HapticIntensity = .medium
    
    enum HapticIntensity: String, CaseIterable {
        case light = "Light"
        case medium = "Medium"
        case heavy = "Heavy"
    }
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()
    
    private init() {
        prepareGenerators()
    }
    
    func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notification.prepare()
        selection.prepare()
    }
    
    func impact() {
        guard hapticsEnabled else { return }
        switch intensity {
        case .light: impactLight.impactOccurred()
        case .medium: impactMedium.impactOccurred()
        case .heavy: impactHeavy.impactOccurred()
        }
    }
    
    func success() {
        guard hapticsEnabled else { return }
        notification.notificationOccurred(.success)
    }
    
    func warning() {
        guard hapticsEnabled else { return }
        notification.notificationOccurred(.warning)
    }
    
    func error() {
        guard hapticsEnabled else { return }
        notification.notificationOccurred(.error)
    }
    
    func selection() {
        guard hapticsEnabled else { return }
        self.selection.selectionChanged()
    }
    
    func placementConfirmed() {
        guard hapticsEnabled else { return }
        impactHeavy.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.notification.notificationOccurred(.success)
        }
    }
    
    func streakMilestone() {
        guard hapticsEnabled else { return }
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                self.impactMedium.impactOccurred()
            }
        }
    }
}

struct HapticSettingsView: View {
    @State private var hapticManager = HapticFeedbackManager.shared
    
    var body: some View {
        List {
            Section {
                Toggle("Enable Haptics", isOn: $hapticManager.hapticsEnabled)
                
                if hapticManager.hapticsEnabled {
                    Picker("Intensity", selection: $hapticManager.intensity) {
                        ForEach(HapticFeedbackManager.HapticIntensity.allCases, id: \.self) { intensity in
                            Text(intensity.rawValue).tag(intensity)
                        }
                    }
                }
            } header: {
                Text("Haptic Feedback")
            }
            
            if hapticManager.hapticsEnabled {
                Section {
                    Button("Test Placement Confirmation") {
                        hapticManager.placementConfirmed()
                    }
                    Button("Test Success") {
                        hapticManager.success()
                    }
                    Button("Test Warning") {
                        hapticManager.warning()
                    }
                    Button("Test Streak Milestone") {
                        hapticManager.streakMilestone()
                    }
                } header: {
                    Text("Test Haptics")
                }
            }
        }
        .navigationTitle("Haptics")
    }
}

extension View {
    func withHapticFeedback(_ type: HapticType = .impact) -> some View {
        self.simultaneousGesture(TapGesture().onEnded { _ in
            switch type {
            case .impact: HapticFeedbackManager.shared.impact()
            case .success: HapticFeedbackManager.shared.success()
            case .warning: HapticFeedbackManager.shared.warning()
            case .error: HapticFeedbackManager.shared.error()
            case .selection: HapticFeedbackManager.shared.selection()
            }
        })
    }
}

enum HapticType {
    case impact, success, warning, error, selection
}

#Preview {
    NavigationStack {
        HapticSettingsView()
    }
}
