//
//  ABTestingManager.swift
//  OmniSiteTracker
//
//  A/B testing framework for feature experimentation
//

import SwiftUI

struct ABExperiment: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let variants: [Variant]
    var assignedVariant: String?
    let startDate: Date
    let endDate: Date?
    
    struct Variant: Codable {
        let id: String
        let name: String
        let weight: Double
    }
    
    var isActive: Bool {
        let now = Date()
        if now < startDate { return false }
        if let end = endDate, now > end { return false }
        return true
    }
}

@MainActor
@Observable
final class ABTestingManager {
    static let shared = ABTestingManager()
    
    private(set) var experiments: [ABExperiment] = []
    private(set) var eventLog: [(experiment: String, event: String, date: Date)] = []
    
    private let assignmentsKey = "ab_assignments"
    private var assignments: [String: String] = [:]
    
    init() {
        loadAssignments()
        setupDefaultExperiments()
    }
    
    private func setupDefaultExperiments() {
        experiments = [
            ABExperiment(
                id: "onboarding_flow",
                name: "Onboarding Flow",
                description: "Test different onboarding experiences",
                variants: [
                    .init(id: "control", name: "Standard", weight: 0.5),
                    .init(id: "simplified", name: "Simplified", weight: 0.5)
                ],
                assignedVariant: nil,
                startDate: Date().addingTimeInterval(-86400 * 30),
                endDate: nil
            ),
            ABExperiment(
                id: "reminder_style",
                name: "Reminder Style",
                description: "Test reminder notification formats",
                variants: [
                    .init(id: "minimal", name: "Minimal", weight: 0.33),
                    .init(id: "detailed", name: "Detailed", weight: 0.33),
                    .init(id: "actionable", name: "Actionable", weight: 0.34)
                ],
                assignedVariant: nil,
                startDate: Date().addingTimeInterval(-86400 * 7),
                endDate: nil
            ),
            ABExperiment(
                id: "chart_type",
                name: "Chart Visualization",
                description: "Test different chart presentations",
                variants: [
                    .init(id: "bar", name: "Bar Chart", weight: 0.5),
                    .init(id: "pie", name: "Pie Chart", weight: 0.5)
                ],
                assignedVariant: nil,
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 30)
            )
        ]
        
        // Apply saved assignments
        for i in experiments.indices {
            if let assigned = assignments[experiments[i].id] {
                experiments[i].assignedVariant = assigned
            }
        }
    }
    
    func getVariant(for experimentId: String) -> String? {
        guard let index = experiments.firstIndex(where: { $0.id == experimentId }) else {
            return nil
        }
        
        let experiment = experiments[index]
        
        if !experiment.isActive {
            return nil
        }
        
        if let assigned = experiment.assignedVariant {
            return assigned
        }
        
        // Randomly assign variant based on weights
        let random = Double.random(in: 0...1)
        var cumulative = 0.0
        
        for variant in experiment.variants {
            cumulative += variant.weight
            if random <= cumulative {
                experiments[index].assignedVariant = variant.id
                assignments[experimentId] = variant.id
                saveAssignments()
                return variant.id
            }
        }
        
        return experiment.variants.last?.id
    }
    
    func trackEvent(experiment: String, event: String) {
        eventLog.append((experiment: experiment, event: event, date: Date()))
    }
    
    func resetExperiment(_ experimentId: String) {
        if let index = experiments.firstIndex(where: { $0.id == experimentId }) {
            experiments[index].assignedVariant = nil
            assignments.removeValue(forKey: experimentId)
            saveAssignments()
        }
    }
    
    func resetAllExperiments() {
        for i in experiments.indices {
            experiments[i].assignedVariant = nil
        }
        assignments.removeAll()
        saveAssignments()
    }
    
    private func loadAssignments() {
        if let data = UserDefaults.standard.data(forKey: assignmentsKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            assignments = decoded
        }
    }
    
    private func saveAssignments() {
        if let data = try? JSONEncoder().encode(assignments) {
            UserDefaults.standard.set(data, forKey: assignmentsKey)
        }
    }
}

struct ABTestingView: View {
    @State private var manager = ABTestingManager.shared
    @State private var showResetAlert = false
    
    var body: some View {
        List {
            Section("Active Experiments") {
                ForEach(manager.experiments.filter { $0.isActive }) { experiment in
                    ExperimentRow(experiment: experiment, manager: manager)
                }
            }
            
            Section("Inactive Experiments") {
                ForEach(manager.experiments.filter { !$0.isActive }) { experiment in
                    ExperimentRow(experiment: experiment, manager: manager)
                }
            }
            
            Section("Event Log") {
                if manager.eventLog.isEmpty {
                    Text("No events tracked")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(manager.eventLog.indices, id: \.self) { index in
                        let log = manager.eventLog[index]
                        VStack(alignment: .leading) {
                            Text(log.event)
                                .font(.headline)
                            Text("\(log.experiment) • \(log.date.formatted())")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section {
                Button("Reset All Experiments", role: .destructive) {
                    showResetAlert = true
                }
            }
        }
        .navigationTitle("A/B Testing")
        .alert("Reset Experiments", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                manager.resetAllExperiments()
            }
        } message: {
            Text("This will reset all experiment assignments.")
        }
    }
}

struct ExperimentRow: View {
    let experiment: ABExperiment
    let manager: ABTestingManager
    @State private var showDetail = false
    
    var body: some View {
        Button {
            showDetail = true
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(experiment.name)
                        .font(.headline)
                    Text(experiment.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if let variant = experiment.assignedVariant {
                    Text(variant)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Image(systemName: experiment.isActive ? "circle.fill" : "circle")
                    .foregroundStyle(experiment.isActive ? .green : .gray)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            ExperimentDetailView(experiment: experiment, manager: manager)
        }
    }
}

struct ExperimentDetailView: View {
    let experiment: ABExperiment
    let manager: ABTestingManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Info") {
                    LabeledContent("ID", value: experiment.id)
                    LabeledContent("Status", value: experiment.isActive ? "Active" : "Inactive")
                    LabeledContent("Start", value: experiment.startDate.formatted())
                    if let end = experiment.endDate {
                        LabeledContent("End", value: end.formatted())
                    }
                }
                
                Section("Variants") {
                    ForEach(experiment.variants, id: \.id) { variant in
                        HStack {
                            Text(variant.name)
                            Spacer()
                            Text(String(format: "%.0f%%", variant.weight * 100))
                                .foregroundStyle(.secondary)
                            if experiment.assignedVariant == variant.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Get Variant") {
                        _ = manager.getVariant(for: experiment.id)
                    }
                    
                    Button("Track Conversion") {
                        manager.trackEvent(experiment: experiment.id, event: "conversion")
                    }
                    
                    Button("Reset Assignment", role: .destructive) {
                        manager.resetExperiment(experiment.id)
                    }
                }
            }
            .navigationTitle(experiment.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ABTestingView()
    }
}
