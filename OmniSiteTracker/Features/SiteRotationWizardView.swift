//
//  SiteRotationWizardView.swift
//  OmniSiteTracker
//
//  Step-by-step wizard for site rotation guidance
//

import SwiftUI

enum WizardStep: Int, CaseIterable {
    case selectSite = 0
    case prepareSite
    case applySensor
    case confirmPlacement
    case complete
    
    var title: String {
        switch self {
        case .selectSite: return "Select Site"
        case .prepareSite: return "Prepare Site"
        case .applySensor: return "Apply Sensor"
        case .confirmPlacement: return "Confirm Placement"
        case .complete: return "Complete"
        }
    }
    
    var description: String {
        switch self {
        case .selectSite: return "Choose your next injection site"
        case .prepareSite: return "Clean and prepare the area"
        case .applySensor: return "Apply the Omnipod sensor"
        case .confirmPlacement: return "Verify proper placement"
        case .complete: return "Site rotation logged successfully!"
        }
    }
    
    var icon: String {
        switch self {
        case .selectSite: return "mappin.circle"
        case .prepareSite: return "drop.circle"
        case .applySensor: return "plus.circle"
        case .confirmPlacement: return "checkmark.circle"
        case .complete: return "star.circle"
        }
    }
}

@MainActor
@Observable
final class SiteRotationWizard {
    static let shared = SiteRotationWizard()
    
    private(set) var currentStep: WizardStep = .selectSite
    private(set) var selectedSite: String?
    private(set) var isComplete = false
    
    let sites = ["Abdomen - Left", "Abdomen - Right", "Upper Arm - Left", "Upper Arm - Right", "Thigh - Left", "Thigh - Right", "Lower Back - Left", "Lower Back - Right"]
    
    func selectSite(_ site: String) {
        selectedSite = site
    }
    
    func nextStep() {
        guard let next = WizardStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
        if currentStep == .complete {
            isComplete = true
        }
    }
    
    func previousStep() {
        guard let prev = WizardStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prev
    }
    
    func reset() {
        currentStep = .selectSite
        selectedSite = nil
        isComplete = false
    }
    
    var canProceed: Bool {
        switch currentStep {
        case .selectSite: return selectedSite != nil
        default: return true
        }
    }
}

struct SiteRotationWizardView: View {
    @State private var wizard = SiteRotationWizard.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            ProgressView(value: Double(wizard.currentStep.rawValue), total: Double(WizardStep.allCases.count - 1))
                .padding()
            
            // Step indicator
            HStack {
                ForEach(WizardStep.allCases, id: \.rawValue) { step in
                    Circle()
                        .fill(step.rawValue <= wizard.currentStep.rawValue ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                    if step != WizardStep.allCases.last {
                        Rectangle()
                            .fill(step.rawValue < wizard.currentStep.rawValue ? Color.blue : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            .padding(.horizontal)
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: wizard.currentStep.icon)
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                        .padding(.top, 32)
                    
                    Text(wizard.currentStep.title)
                        .font(.title.bold())
                    
                    Text(wizard.currentStep.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    stepContent
                }
                .padding()
            }
            
            // Navigation buttons
            HStack(spacing: 16) {
                if wizard.currentStep != .selectSite && wizard.currentStep != .complete {
                    Button("Back") { wizard.previousStep() }
                        .buttonStyle(.bordered)
                }
                
                if wizard.currentStep == .complete {
                    Button("Done") {
                        wizard.reset()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(wizard.currentStep == .confirmPlacement ? "Complete" : "Next") { wizard.nextStep() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!wizard.canProceed)
                }
            }
            .padding()
        }
        .navigationTitle("Site Rotation")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    var stepContent: some View {
        switch wizard.currentStep {
        case .selectSite:
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(wizard.sites, id: \.self) { site in
                    Button { wizard.selectSite(site) } label: {
                        Text(site)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(wizard.selectedSite == site ? Color.blue : Color(.systemGray6))
                            .foregroundStyle(wizard.selectedSite == site ? .white : .primary)
                            .cornerRadius(12)
                    }
                }
            }
            
        case .prepareSite:
            VStack(alignment: .leading, spacing: 16) {
                ChecklistItem(text: "Wash hands thoroughly")
                ChecklistItem(text: "Clean the site with alcohol swab")
                ChecklistItem(text: "Let the area dry completely")
                ChecklistItem(text: "Ensure skin is free of lotions")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
        case .applySensor:
            VStack(alignment: .leading, spacing: 16) {
                ChecklistItem(text: "Remove sensor from packaging")
                ChecklistItem(text: "Align with prepared site")
                ChecklistItem(text: "Press firmly to apply")
                ChecklistItem(text: "Hold for 10 seconds")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
        case .confirmPlacement:
            VStack(spacing: 16) {
                if let site = wizard.selectedSite {
                    Text("Confirm: \(site)")
                        .font(.headline)
                }
                ChecklistItem(text: "Sensor is securely attached")
                ChecklistItem(text: "No air bubbles under adhesive")
                ChecklistItem(text: "Site feels comfortable")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
        case .complete:
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                if let site = wizard.selectedSite {
                    Text("Logged: \(site)")
                        .font(.headline)
                }
            }
        }
    }
}

struct ChecklistItem: View {
    let text: String
    @State private var isChecked = false
    
    var body: some View {
        Button { isChecked.toggle() } label: {
            HStack {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isChecked ? .green : .gray)
                Text(text)
                    .foregroundStyle(.primary)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SiteRotationWizardView()
    }
}
