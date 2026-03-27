//
//  LogTemplatesView.swift
//  OmniSiteTracker
//
//  Pre-filled log entry templates
//

import SwiftUI

struct LogTemplate: Identifiable {
    let id = UUID()
    var name: String
    var site: String
    var defaultNotes: String
    var includePainLevel: Bool
    var autoSetTime: Bool
}

@MainActor
@Observable
final class LogTemplatesManager {
    var templates: [LogTemplate] = [
        LogTemplate(name: "Morning Routine", site: "Left Arm", defaultNotes: "Morning placement", includePainLevel: true, autoSetTime: true),
        LogTemplate(name: "Evening Routine", site: "Right Thigh", defaultNotes: "Evening placement", includePainLevel: false, autoSetTime: true)
    ]
    
    func add(_ template: LogTemplate) {
        templates.append(template)
    }
    
    func delete(_ template: LogTemplate) {
        templates.removeAll { $0.id == template.id }
    }
}

struct LogTemplatesView: View {
    @State private var manager = LogTemplatesManager()
    @State private var showingAddTemplate = false
    
    var body: some View {
        List {
            ForEach(manager.templates) { template in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(template.name)
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Use") {
                            // Apply template
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Text("Site: \(template.site)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        if template.includePainLevel {
                            Label("Pain Level", systemImage: "gauge")
                        }
                        if template.autoSetTime {
                            Label("Auto Time", systemImage: "clock")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    manager.delete(manager.templates[index])
                }
            }
        }
        .navigationTitle("Log Templates")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddTemplate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTemplate) {
            AddTemplateFormView(manager: manager)
        }
    }
}

struct AddTemplateFormView: View {
    @Bindable var manager: LogTemplatesManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var site = "Left Arm"
    @State private var notes = ""
    @State private var includePainLevel = false
    @State private var autoSetTime = true
    
    private let sites = ["Left Arm", "Right Arm", "Left Thigh", "Right Thigh", "Abdomen Left", "Abdomen Right"]
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Template Name", text: $name)
                
                Picker("Default Site", selection: $site) {
                    ForEach(sites, id: \.self) { s in
                        Text(s).tag(s)
                    }
                }
                
                TextField("Default Notes", text: $notes)
                
                Section("Options") {
                    Toggle("Include Pain Level", isOn: $includePainLevel)
                    Toggle("Auto-set Current Time", isOn: $autoSetTime)
                }
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let template = LogTemplate(
                            name: name,
                            site: site,
                            defaultNotes: notes,
                            includePainLevel: includePainLevel,
                            autoSetTime: autoSetTime
                        )
                        manager.add(template)
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
        LogTemplatesView()
    }
}
