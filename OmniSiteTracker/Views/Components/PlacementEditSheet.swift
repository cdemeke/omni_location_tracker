//
//  PlacementEditSheet.swift
//  OmniSiteTracker
//
//  Sheet for editing or deleting an existing placement record.
//

import SwiftUI

/// Sheet for editing a placement log entry
struct PlacementEditSheet: View {
    let placement: PlacementLog
    let onSave: (BodyLocation, Date, String?) -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    @State private var selectedLocation: BodyLocation
    @State private var selectedDate: Date
    @State private var note: String
    @State private var showingDeleteConfirmation = false

    init(
        placement: PlacementLog,
        onSave: @escaping (BodyLocation, Date, String?) -> Void,
        onDelete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.placement = placement
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        self._selectedLocation = State(initialValue: placement.location ?? .abdomenRight)
        self._selectedDate = State(initialValue: placement.placedAt)
        self._note = State(initialValue: placement.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                // Location picker
                Section("Placement Location") {
                    Picker("Location", selection: $selectedLocation) {
                        ForEach(BodyLocation.allCases) { location in
                            Text(location.displayName)
                                .tag(location)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                // Date picker
                Section("Date & Time") {
                    DatePicker(
                        "Placed At",
                        selection: $selectedDate,
                        in: ...Date.now,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                // Note
                Section("Note (Optional)") {
                    TextField("e.g., Site felt tender", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Delete button
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Placement")
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Edit Placement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(selectedLocation, selectedDate, note.isEmpty ? nil : note)
                    }
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog(
                "Delete Placement",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    onDelete()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this placement record? This action cannot be undone.")
            }
        }
    }
}

#Preview {
    PlacementEditSheet(
        placement: PlacementLog(location: .abdomenLeft, placedAt: .now, note: "Test note"),
        onSave: { _, _, _ in },
        onDelete: {},
        onCancel: {}
    )
}
