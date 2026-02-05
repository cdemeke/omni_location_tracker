//
//  RotationRulesView.swift
//  OmniSiteTracker
//
//  Custom rotation rules and constraints
//

import SwiftUI

struct RotationRule: Identifiable {
    let id = UUID()
    var name: String
    var type: RuleType
    var isEnabled: Bool
    var value: Int
    
    enum RuleType: String, CaseIterable {
        case minDays = "Minimum Days Between Use"
        case maxDays = "Maximum Days Without Use"
        case avoidSite = "Avoid Specific Site"
        case preferSite = "Prefer Specific Site"
        case sequenceOrder = "Use Specific Sequence"
    }
}

@MainActor
@Observable
final class RotationRulesManager {
    var rules: [RotationRule] = [
        RotationRule(name: "Minimum Rest", type: .minDays, isEnabled: true, value: 3),
        RotationRule(name: "Max Gap", type: .maxDays, isEnabled: true, value: 14),
        RotationRule(name: "Prefer Thighs", type: .preferSite, isEnabled: false, value: 0)
    ]
    
    func add(_ rule: RotationRule) {
        rules.append(rule)
    }
    
    func delete(_ rule: RotationRule) {
        rules.removeAll { $0.id == rule.id }
    }
}

struct RotationRulesView: View {
    @State private var manager = RotationRulesManager()
    @State private var showingAddRule = false
    
    var body: some View {
        List {
            Section {
                ForEach($manager.rules) { $rule in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(rule.name)
                                .font(.headline)
                            Text(rule.type.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if rule.type == .minDays || rule.type == .maxDays {
                                Text("\(rule.value) days")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $rule.isEnabled)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        manager.delete(manager.rules[index])
                    }
                }
            }
            
            Section {
                Button {
                    showingAddRule = true
                } label: {
                    Label("Add Rule", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Rotation Rules")
        .sheet(isPresented: $showingAddRule) {
            AddRuleView(manager: manager)
        }
    }
}

struct AddRuleView: View {
    @Bindable var manager: RotationRulesManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var type: RotationRule.RuleType = .minDays
    @State private var value = 3
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Rule Name", text: $name)
                
                Picker("Rule Type", selection: $type) {
                    ForEach(RotationRule.RuleType.allCases, id: \.self) { ruleType in
                        Text(ruleType.rawValue).tag(ruleType)
                    }
                }
                
                if type == .minDays || type == .maxDays {
                    Stepper("Days: \(value)", value: $value, in: 1...30)
                }
            }
            .navigationTitle("Add Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let rule = RotationRule(name: name, type: type, isEnabled: true, value: value)
                        manager.add(rule)
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
        RotationRulesView()
    }
}
