//
//  CustomFieldsView.swift
//  OmniSiteTracker
//
//  Add custom fields to log entries
//

import SwiftUI

struct CustomField: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: FieldType
    var isRequired: Bool
    var options: [String]?
    
    init(name: String, type: FieldType, isRequired: Bool = false, options: [String]? = nil) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.isRequired = isRequired
        self.options = options
    }
    
    enum FieldType: String, Codable, CaseIterable {
        case text = "Text"
        case number = "Number"
        case toggle = "Yes/No"
        case picker = "Selection"
        case date = "Date"
    }
}

@MainActor
@Observable
final class CustomFieldsManager {
    var fields: [CustomField] = [
        CustomField(name: "Pain Level", type: .number, isRequired: false),
        CustomField(name: "Took Medication", type: .toggle, isRequired: false)
    ]
    
    func add(_ field: CustomField) {
        fields.append(field)
    }
    
    func delete(_ field: CustomField) {
        fields.removeAll { $0.id == field.id }
    }
}

struct CustomFieldsView: View {
    @State private var manager = CustomFieldsManager()
    @State private var showingAddField = false
    
    var body: some View {
        List {
            Section {
                ForEach(manager.fields) { field in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(field.name)
                                .font(.headline)
                            
                            HStack {
                                Text(field.type.rawValue)
                                if field.isRequired {
                                    Text("• Required")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: iconFor(field.type))
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        manager.delete(manager.fields[index])
                    }
                }
                .onMove { from, to in
                    manager.fields.move(fromOffsets: from, toOffset: to)
                }
            }
            
            Section {
                Button {
                    showingAddField = true
                } label: {
                    Label("Add Custom Field", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Custom Fields")
        .toolbar {
            EditButton()
        }
        .sheet(isPresented: $showingAddField) {
            AddCustomFieldView(manager: manager)
        }
    }
    
    private func iconFor(_ type: CustomField.FieldType) -> String {
        switch type {
        case .text: return "text.alignleft"
        case .number: return "number"
        case .toggle: return "switch.2"
        case .picker: return "list.bullet"
        case .date: return "calendar"
        }
    }
}

struct AddCustomFieldView: View {
    @Bindable var manager: CustomFieldsManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var type: CustomField.FieldType = .text
    @State private var isRequired = false
    @State private var options = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Field Name", text: $name)
                
                Picker("Field Type", selection: $type) {
                    ForEach(CustomField.FieldType.allCases, id: \.self) { fieldType in
                        Text(fieldType.rawValue).tag(fieldType)
                    }
                }
                
                Toggle("Required", isOn: $isRequired)
                
                if type == .picker {
                    Section("Options (comma separated)") {
                        TextField("Option 1, Option 2, Option 3", text: $options)
                    }
                }
            }
            .navigationTitle("Add Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let optionsArray = type == .picker ? options.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) } : nil
                        let field = CustomField(name: name, type: type, isRequired: isRequired, options: optionsArray)
                        manager.add(field)
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
        CustomFieldsView()
    }
}
