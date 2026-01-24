//
//  SiteGroupsView.swift
//  OmniSiteTracker
//
//  Group sites for easier management
//

import SwiftUI

struct SiteGroup: Identifiable {
    let id = UUID()
    var name: String
    var sites: [String]
    var color: String
    var isActive: Bool
}

@MainActor
@Observable
final class SiteGroupManager {
    var groups: [SiteGroup] = [
        SiteGroup(name: "Arms", sites: ["Left Arm", "Right Arm"], color: "blue", isActive: true),
        SiteGroup(name: "Thighs", sites: ["Left Thigh", "Right Thigh"], color: "green", isActive: true),
        SiteGroup(name: "Abdomen", sites: ["Abdomen Left", "Abdomen Right"], color: "orange", isActive: true)
    ]
    
    func add(_ group: SiteGroup) {
        groups.append(group)
    }
    
    func delete(_ group: SiteGroup) {
        groups.removeAll { $0.id == group.id }
    }
    
    func toggleActive(_ group: SiteGroup) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index].isActive.toggle()
        }
    }
}

struct SiteGroupsView: View {
    @State private var manager = SiteGroupManager()
    @State private var showingAddGroup = false
    
    var body: some View {
        List {
            ForEach(manager.groups) { group in
                HStack {
                    Circle()
                        .fill(colorFor(group.color))
                        .frame(width: 12, height: 12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.name)
                            .font(.headline)
                        
                        Text(group.sites.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { group.isActive },
                        set: { _ in manager.toggleActive(group) }
                    ))
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    manager.delete(manager.groups[index])
                }
            }
        }
        .navigationTitle("Site Groups")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddGroup = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddGroup) {
            AddGroupView(manager: manager)
        }
    }
    
    private func colorFor(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        default: return .gray
        }
    }
}

struct AddGroupView: View {
    @Bindable var manager: SiteGroupManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedSites: Set<String> = []
    @State private var color = "blue"
    
    private let allSites = ["Left Arm", "Right Arm", "Left Thigh", "Right Thigh", "Abdomen Left", "Abdomen Right", "Lower Back Left", "Lower Back Right"]
    private let colors = ["blue", "green", "orange", "purple", "red"]
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Group Name", text: $name)
                
                Section("Color") {
                    HStack {
                        ForEach(colors, id: \.self) { colorName in
                            Circle()
                                .fill(colorFor(colorName))
                                .frame(width: 30, height: 30)
                                .overlay {
                                    if color == colorName {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    color = colorName
                                }
                        }
                    }
                }
                
                Section("Sites") {
                    ForEach(allSites, id: \.self) { site in
                        Button {
                            if selectedSites.contains(site) {
                                selectedSites.remove(site)
                            } else {
                                selectedSites.insert(site)
                            }
                        } label: {
                            HStack {
                                Text(site)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedSites.contains(site) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let group = SiteGroup(
                            name: name,
                            sites: Array(selectedSites),
                            color: color,
                            isActive: true
                        )
                        manager.add(group)
                        dismiss()
                    }
                    .disabled(name.isEmpty || selectedSites.isEmpty)
                }
            }
        }
    }
    
    private func colorFor(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        default: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        SiteGroupsView()
    }
}
