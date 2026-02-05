//
//  FeatureFlagsManager.swift
//  OmniSiteTracker
//
//  Feature flags for gradual rollout and A/B testing
//

import SwiftUI

enum FeatureFlag: String, CaseIterable, Identifiable {
    case darkModeSupport = "dark_mode_support"
    case healthKitSync = "healthkit_sync"
    case cloudBackup = "cloud_backup"
    case advancedCharts = "advanced_charts"
    case voiceCommands = "voice_commands"
    case widgetSupport = "widget_support"
    case notifications = "notifications"
    case biometricLock = "biometric_lock"
    case exportPDF = "export_pdf"
    case multiProfile = "multi_profile"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .darkModeSupport: return "Dark Mode"
        case .healthKitSync: return "HealthKit Sync"
        case .cloudBackup: return "Cloud Backup"
        case .advancedCharts: return "Advanced Charts"
        case .voiceCommands: return "Voice Commands"
        case .widgetSupport: return "Widget Support"
        case .notifications: return "Notifications"
        case .biometricLock: return "Biometric Lock"
        case .exportPDF: return "Export PDF"
        case .multiProfile: return "Multi Profile"
        }
    }
    
    var description: String {
        switch self {
        case .darkModeSupport: return "Enable dark mode theme support"
        case .healthKitSync: return "Sync data with Apple Health"
        case .cloudBackup: return "Backup data to iCloud"
        case .advancedCharts: return "Show advanced analytics charts"
        case .voiceCommands: return "Enable Siri voice commands"
        case .widgetSupport: return "Enable home screen widgets"
        case .notifications: return "Push notification reminders"
        case .biometricLock: return "Face ID / Touch ID protection"
        case .exportPDF: return "Export reports as PDF"
        case .multiProfile: return "Support multiple user profiles"
        }
    }
    
    var defaultValue: Bool {
        switch self {
        case .darkModeSupport, .notifications, .widgetSupport:
            return true
        default:
            return false
        }
    }
}

@MainActor
@Observable
final class FeatureFlagsManager {
    static let shared = FeatureFlagsManager()
    
    private let defaults = UserDefaults.standard
    private let prefix = "feature_flag_"
    
    private(set) var overrides: [FeatureFlag: Bool] = [:]
    
    init() {
        loadOverrides()
    }
    
    func isEnabled(_ flag: FeatureFlag) -> Bool {
        if let override = overrides[flag] {
            return override
        }
        return defaults.object(forKey: prefix + flag.rawValue) as? Bool ?? flag.defaultValue
    }
    
    func setEnabled(_ flag: FeatureFlag, enabled: Bool) {
        defaults.set(enabled, forKey: prefix + flag.rawValue)
        overrides[flag] = enabled
    }
    
    func reset(_ flag: FeatureFlag) {
        defaults.removeObject(forKey: prefix + flag.rawValue)
        overrides.removeValue(forKey: flag)
    }
    
    func resetAll() {
        for flag in FeatureFlag.allCases {
            reset(flag)
        }
    }
    
    private func loadOverrides() {
        for flag in FeatureFlag.allCases {
            if let value = defaults.object(forKey: prefix + flag.rawValue) as? Bool {
                overrides[flag] = value
            }
        }
    }
}

struct FeatureFlagsView: View {
    @State private var manager = FeatureFlagsManager.shared
    @State private var showResetAlert = false
    
    var body: some View {
        List {
            Section {
                ForEach(FeatureFlag.allCases) { flag in
                    FeatureFlagRow(flag: flag, manager: manager)
                }
            } header: {
                Text("Features")
            } footer: {
                Text("Enable or disable experimental features")
            }
            
            Section {
                Button("Reset All to Defaults", role: .destructive) {
                    showResetAlert = true
                }
            }
        }
        .navigationTitle("Feature Flags")
        .alert("Reset Features", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                manager.resetAll()
            }
        } message: {
            Text("This will reset all feature flags to their default values.")
        }
    }
}

struct FeatureFlagRow: View {
    let flag: FeatureFlag
    let manager: FeatureFlagsManager
    @State private var isEnabled: Bool = false
    
    var body: some View {
        Toggle(isOn: $isEnabled) {
            VStack(alignment: .leading) {
                Text(flag.displayName)
                    .font(.headline)
                Text(flag.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            isEnabled = manager.isEnabled(flag)
        }
        .onChange(of: isEnabled) { _, newValue in
            manager.setEnabled(flag, enabled: newValue)
        }
    }
}

// Helper view modifier for feature flags
struct FeatureFlagModifier: ViewModifier {
    let flag: FeatureFlag
    @State private var manager = FeatureFlagsManager.shared
    
    func body(content: Content) -> some View {
        if manager.isEnabled(flag) {
            content
        }
    }
}

extension View {
    func featureFlag(_ flag: FeatureFlag) -> some View {
        modifier(FeatureFlagModifier(flag: flag))
    }
}

#Preview {
    NavigationStack {
        FeatureFlagsView()
    }
}
