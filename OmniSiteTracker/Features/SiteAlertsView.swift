//
//  SiteAlertsView.swift
//  OmniSiteTracker
//
//  Configurable alerts for site conditions
//

import SwiftUI

struct SiteAlert: Identifiable {
    let id = UUID()
    var name: String
    var condition: AlertCondition
    var threshold: Int
    var isEnabled: Bool
    var notifyImmediately: Bool
    
    enum AlertCondition: String, CaseIterable {
        case daysWithoutUse = "Days without use exceeds"
        case consecutiveUses = "Consecutive uses exceeds"
        case symptomsReported = "Symptoms reported exceeds"
        case overdue = "Overdue for rotation"
    }
}

@MainActor
@Observable
final class SiteAlertsManager {
    var alerts: [SiteAlert] = [
        SiteAlert(name: "Long Rest", condition: .daysWithoutUse, threshold: 14, isEnabled: true, notifyImmediately: false),
        SiteAlert(name: "Overuse Warning", condition: .consecutiveUses, threshold: 3, isEnabled: true, notifyImmediately: true),
        SiteAlert(name: "Symptom Alert", condition: .symptomsReported, threshold: 2, isEnabled: false, notifyImmediately: true)
    ]
    
    func add(_ alert: SiteAlert) {
        alerts.append(alert)
    }
    
    func delete(_ alert: SiteAlert) {
        alerts.removeAll { $0.id == alert.id }
    }
}

struct SiteAlertsView: View {
    @State private var manager = SiteAlertsManager()
    @State private var showingAddAlert = false
    
    var body: some View {
        List {
            ForEach($manager.alerts) { $alert in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(alert.name)
                            .font(.headline)
                        
                        Spacer()
                        
                        Toggle("", isOn: $alert.isEnabled)
                    }
                    
                    Text("\(alert.condition.rawValue) \(alert.threshold)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if alert.notifyImmediately {
                        Label("Immediate notification", systemImage: "bell.badge")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    manager.delete(manager.alerts[index])
                }
            }
        }
        .navigationTitle("Site Alerts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddAlert = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddAlert) {
            AddAlertView(manager: manager)
        }
    }
}

struct AddAlertView: View {
    @Bindable var manager: SiteAlertsManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var condition: SiteAlert.AlertCondition = .daysWithoutUse
    @State private var threshold = 7
    @State private var notifyImmediately = false
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Alert Name", text: $name)
                
                Picker("Condition", selection: $condition) {
                    ForEach(SiteAlert.AlertCondition.allCases, id: \.self) { cond in
                        Text(cond.rawValue).tag(cond)
                    }
                }
                
                Stepper("Threshold: \(threshold)", value: $threshold, in: 1...30)
                
                Toggle("Notify Immediately", isOn: $notifyImmediately)
            }
            .navigationTitle("New Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let alert = SiteAlert(
                            name: name,
                            condition: condition,
                            threshold: threshold,
                            isEnabled: true,
                            notifyImmediately: notifyImmediately
                        )
                        manager.add(alert)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SiteAlertsView()
    }
}
