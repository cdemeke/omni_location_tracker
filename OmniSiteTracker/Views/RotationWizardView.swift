//
//  RotationWizardView.swift
//  OmniSiteTracker
//
//  Interactive wizard to help users set up optimal site rotation.
//

import SwiftUI

struct RotationWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var selectedPattern: RotationPattern = .clockwise
    @State private var selectedSites: Set<String> = []
    @State private var restDays = 18
    @State private var showingCompletion = false
    
    let allSites = ["Abdomen Left", "Abdomen Right", "Left Thigh", "Right Thigh", "Left Arm", "Right Arm", "Left Hip", "Right Hip"]
    
    enum RotationPattern: String, CaseIterable {
        case clockwise = "Clockwise"
        case alternating = "Alternating"
        case random = "Smart Random"
        case custom = "Custom Order"
        
        var description: String {
            switch self {
            case .clockwise: return "Move systematically around your body"
            case .alternating: return "Switch between left and right sides"
            case .random: return "Algorithm picks the best available site"
            case .custom: return "Define your own rotation order"
            }
        }
        
        var icon: String {
            switch self {
            case .clockwise: return "arrow.clockwise"
            case .alternating: return "arrow.left.arrow.right"
            case .random: return "sparkles"
            case .custom: return "slider.horizontal.3"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep), total: 3)
                    .padding()
                
                // Content
                TabView(selection: $currentStep) {
                    welcomeStep.tag(0)
                    patternStep.tag(1)
                    sitesStep.tag(2)
                    restDaysStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation { currentStep -= 1 }
                        }
                    }
                    
                    Spacer()
                    
                    Button(currentStep < 3 ? "Next" : "Finish") {
                        if currentStep < 3 {
                            withAnimation { currentStep += 1 }
                        } else {
                            showingCompletion = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(currentStep == 2 && selectedSites.count < 3)
                }
                .padding()
            }
            .navigationTitle("Rotation Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { dismiss() }
                }
            }
            .alert("Setup Complete!", isPresented: $showingCompletion) {
                Button("Get Started") { dismiss() }
            } message: {
                Text("Your rotation pattern is configured. Start logging placements to build your history.")
            }
        }
    }
    
    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.walk")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Let's Set Up Your Rotation")
                .font(.title)
                .fontWeight(.bold)
            
            Text("A good rotation pattern helps prevent tissue damage and ensures consistent absorption.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    private var patternStep: some View {
        VStack(spacing: 16) {
            Text("Choose Your Pattern")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(RotationPattern.allCases, id: \.self) { pattern in
                Button(action: { selectedPattern = pattern }) {
                    HStack {
                        Image(systemName: pattern.icon)
                            .font(.title2)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading) {
                            Text(pattern.rawValue)
                                .font(.headline)
                            Text(pattern.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedPattern == pattern {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(selectedPattern == pattern ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var sitesStep: some View {
        VStack(spacing: 16) {
            Text("Select Your Sites")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Choose at least 3 sites to include in your rotation")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(allSites, id: \.self) { site in
                    Button(action: { toggleSite(site) }) {
                        VStack {
                            Image(systemName: selectedSites.contains(site) ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                            Text(site)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedSites.contains(site) ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text("\(selectedSites.count) sites selected")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
    
    private var restDaysStep: some View {
        VStack(spacing: 24) {
            Text("Rest Period")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("How many days should a site rest before reuse?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack {
                Text("\(restDays)")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.blue)
                
                Text("days")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            Slider(value: Binding(get: { Double(restDays) }, set: { restDays = Int($0) }), in: 7...30, step: 1)
                .padding(.horizontal)
            
            Text("Recommended: 14-21 days")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
    
    private func toggleSite(_ site: String) {
        if selectedSites.contains(site) {
            selectedSites.remove(site)
        } else {
            selectedSites.insert(site)
        }
    }
}

#Preview {
    RotationWizardView()
}
