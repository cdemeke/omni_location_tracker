//
//  SitePreferencesView.swift
//  OmniSiteTracker
//
//  Individual site preference settings
//

import SwiftUI

struct SitePreference: Identifiable {
    let id = UUID()
    var siteName: String
    var isEnabled: Bool
    var preferenceLevel: PreferenceLevel
    var notes: String
    var avoidUntil: Date?
    
    enum PreferenceLevel: String, CaseIterable {
        case preferred = "Preferred"
        case neutral = "Neutral"
        case avoid = "Avoid"
    }
}

@MainActor
@Observable
final class SitePreferencesManager {
    var preferences: [SitePreference] = [
        SitePreference(siteName: "Left Arm", isEnabled: true, preferenceLevel: .preferred, notes: "", avoidUntil: nil),
        SitePreference(siteName: "Right Arm", isEnabled: true, preferenceLevel: .neutral, notes: "", avoidUntil: nil),
        SitePreference(siteName: "Left Thigh", isEnabled: true, preferenceLevel: .preferred, notes: "", avoidUntil: nil),
        SitePreference(siteName: "Right Thigh", isEnabled: true, preferenceLevel: .neutral, notes: "", avoidUntil: nil),
        SitePreference(siteName: "Abdomen Left", isEnabled: false, preferenceLevel: .avoid, notes: "Healing from bruise", avoidUntil: Date().addingTimeInterval(604800)),
        SitePreference(siteName: "Abdomen Right", isEnabled: true, preferenceLevel: .neutral, notes: "", avoidUntil: nil)
    ]
}

struct SitePreferencesView: View {
    @State private var manager = SitePreferencesManager()
    @State private var selectedSite: SitePreference?
    
    var body: some View {
        List {
            ForEach($manager.preferences) { $pref in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pref.siteName)
                            .font(.headline)
                            .strikethrough(!pref.isEnabled)
                        
                        HStack {
                            Text(pref.preferenceLevel.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(colorFor(pref.preferenceLevel).opacity(0.2))
                                .foregroundStyle(colorFor(pref.preferenceLevel))
                                .clipShape(Capsule())
                            
                            if let until = pref.avoidUntil, until > Date() {
                                Text("Until \(until.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $pref.isEnabled)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedSite = pref
                }
            }
        }
        .navigationTitle("Site Preferences")
        .sheet(item: $selectedSite) { site in
            EditSitePreferenceView(preference: site, manager: manager)
        }
    }
    
    private func colorFor(_ level: SitePreference.PreferenceLevel) -> Color {
        switch level {
        case .preferred: return .green
        case .neutral: return .secondary
        case .avoid: return .red
        }
    }
}

struct EditSitePreferenceView: View {
    let preference: SitePreference
    @Bindable var manager: SitePreferencesManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var level: SitePreference.PreferenceLevel = .neutral
    @State private var notes = ""
    @State private var hasAvoidDate = false
    @State private var avoidUntil = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(preference.siteName)
                        .font(.title2)
                }
                
                Section("Preference") {
                    Picker("Level", selection: $level) {
                        ForEach(SitePreference.PreferenceLevel.allCases, id: \.self) { lvl in
                            Text(lvl.rawValue).tag(lvl)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                if level == .avoid {
                    Section("Avoid Period") {
                        Toggle("Set End Date", isOn: $hasAvoidDate)
                        if hasAvoidDate {
                            DatePicker("Until", selection: $avoidUntil, displayedComponents: .date)
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle("Edit Preference")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Save changes
                        dismiss()
                    }
                }
            }
            .onAppear {
                level = preference.preferenceLevel
                notes = preference.notes
                if let until = preference.avoidUntil {
                    hasAvoidDate = true
                    avoidUntil = until
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SitePreferencesView()
    }
}
