//
//  SiteTemplatesView.swift
//  OmniSiteTracker
//
//  Pre-configured site rotation templates
//

import SwiftUI

struct SiteTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let sites: [String]
    let rotationDays: Int
    let icon: String
}

struct SiteTemplatesView: View {
    @State private var selectedTemplate: SiteTemplate?
    @State private var showingApplyConfirmation = false
    
    private let templates: [SiteTemplate] = [
        SiteTemplate(
            name: "Standard 6-Site",
            description: "Classic rotation using arms, thighs, and abdomen",
            sites: ["Left Arm", "Right Arm", "Left Thigh", "Right Thigh", "Abdomen Left", "Abdomen Right"],
            rotationDays: 3,
            icon: "person.fill"
        ),
        SiteTemplate(
            name: "Arms Only",
            description: "Rotation limited to arm sites",
            sites: ["Left Arm Upper", "Left Arm Lower", "Right Arm Upper", "Right Arm Lower"],
            rotationDays: 2,
            icon: "figure.arms.open"
        ),
        SiteTemplate(
            name: "Extended 8-Site",
            description: "Maximum rotation variety",
            sites: ["Left Arm", "Right Arm", "Left Thigh Outer", "Left Thigh Inner", "Right Thigh Outer", "Right Thigh Inner", "Abdomen Left", "Abdomen Right"],
            rotationDays: 4,
            icon: "star.fill"
        ),
        SiteTemplate(
            name: "Quick 4-Site",
            description: "Simplified rotation for beginners",
            sites: ["Left Arm", "Right Arm", "Left Thigh", "Right Thigh"],
            rotationDays: 2,
            icon: "hare.fill"
        )
    ]
    
    var body: some View {
        List {
            Section {
                Text("Choose a template to quickly set up your site rotation pattern")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Section("Available Templates") {
                ForEach(templates) { template in
                    Button {
                        selectedTemplate = template
                        showingApplyConfirmation = true
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: template.icon)
                                .font(.title2)
                                .foregroundStyle(.blue)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text(template.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text("\(template.sites.count) sites • \(template.rotationDays) days each")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Site Templates")
        .alert("Apply Template?", isPresented: $showingApplyConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Apply") {
                // Apply the template
            }
        } message: {
            if let template = selectedTemplate {
                Text("This will set up \(template.name) with \(template.sites.count) sites.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        SiteTemplatesView()
    }
}
