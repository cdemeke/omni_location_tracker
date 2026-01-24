//
//  ExportSchedulerView.swift
//  OmniSiteTracker
//
//  Schedule automatic data exports
//

import SwiftUI

struct ExportSchedule: Identifiable {
    let id = UUID()
    var frequency: Frequency
    var format: ExportFormat
    var destination: Destination
    var isEnabled: Bool
    var lastExport: Date?
    
    enum Frequency: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
        case pdf = "PDF"
    }
    
    enum Destination: String, CaseIterable {
        case files = "Files App"
        case icloud = "iCloud Drive"
        case email = "Email"
    }
}

@MainActor
@Observable
final class ExportSchedulerManager {
    var schedules: [ExportSchedule] = []
    
    func add(_ schedule: ExportSchedule) {
        schedules.append(schedule)
    }
    
    func runExport(_ schedule: ExportSchedule) async {
        // Perform export
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index].lastExport = Date()
        }
    }
}

struct ExportSchedulerView: View {
    @State private var manager = ExportSchedulerManager()
    @State private var showingAdd = false
    
    var body: some View {
        List {
            Section {
                if manager.schedules.isEmpty {
                    Text("No scheduled exports")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach($manager.schedules) { $schedule in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(schedule.frequency.rawValue) \(schedule.format.rawValue)")
                                        .font(.headline)
                                    Text("To: \(schedule.destination.rawValue)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Toggle("", isOn: $schedule.isEnabled)
                            }
                            
                            if let lastExport = schedule.lastExport {
                                Text("Last: \(lastExport.formatted())")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            Section {
                Button {
                    showingAdd = true
                } label: {
                    Label("Add Schedule", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Export Scheduler")
        .sheet(isPresented: $showingAdd) {
            AddScheduleView(manager: manager)
        }
    }
}

struct AddScheduleView: View {
    @Bindable var manager: ExportSchedulerManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var frequency: ExportSchedule.Frequency = .weekly
    @State private var format: ExportSchedule.ExportFormat = .csv
    @State private var destination: ExportSchedule.Destination = .icloud
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Frequency", selection: $frequency) {
                    ForEach(ExportSchedule.Frequency.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                
                Picker("Format", selection: $format) {
                    ForEach(ExportSchedule.ExportFormat.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                
                Picker("Destination", selection: $destination) {
                    ForEach(ExportSchedule.Destination.allCases, id: \.self) { d in
                        Text(d.rawValue).tag(d)
                    }
                }
            }
            .navigationTitle("New Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let schedule = ExportSchedule(
                            frequency: frequency,
                            format: format,
                            destination: destination,
                            isEnabled: true
                        )
                        manager.add(schedule)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExportSchedulerView()
    }
}
