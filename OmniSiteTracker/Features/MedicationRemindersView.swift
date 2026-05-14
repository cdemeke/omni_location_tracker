//
//  MedicationRemindersView.swift
//  OmniSiteTracker
//
//  Medication reminder integration
//

import SwiftUI
import UserNotifications

struct MedicationReminder: Identifiable {
    let id = UUID()
    var name: String
    var dosage: String
    var time: Date
    var frequency: Frequency
    var isEnabled: Bool
    
    enum Frequency: String, CaseIterable {
        case daily = "Daily"
        case twiceDaily = "Twice Daily"
        case weekly = "Weekly"
        case asNeeded = "As Needed"
    }
}

@MainActor
@Observable
final class MedicationReminderManager {
    var reminders: [MedicationReminder] = []
    
    func add(_ reminder: MedicationReminder) {
        reminders.append(reminder)
        scheduleNotification(for: reminder)
    }
    
    func remove(_ reminder: MedicationReminder) {
        reminders.removeAll { $0.id == reminder.id }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
    }
    
    private func scheduleNotification(for reminder: MedicationReminder) {
        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder"
        content.body = "\(reminder.name) - \(reminder.dosage)"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminder.time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

struct MedicationRemindersView: View {
    @State private var manager = MedicationReminderManager()
    @State private var showingAdd = false
    
    var body: some View {
        List {
            ForEach(manager.reminders) { reminder in
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.name)
                        .font(.headline)
                    Text(reminder.dosage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text(reminder.time.formatted(date: .omitted, time: .shortened))
                        Text("•")
                        Text(reminder.frequency.rawValue)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    manager.remove(manager.reminders[index])
                }
            }
        }
        .navigationTitle("Medications")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddMedicationView(manager: manager)
        }
    }
}

struct AddMedicationView: View {
    @Bindable var manager: MedicationReminderManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var dosage = ""
    @State private var time = Date()
    @State private var frequency: MedicationReminder.Frequency = .daily
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Medication Name", text: $name)
                    TextField("Dosage", text: $dosage)
                }
                
                Section {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    Picker("Frequency", selection: $frequency) {
                        ForEach(MedicationReminder.Frequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let reminder = MedicationReminder(
                            name: name, dosage: dosage,
                            time: time, frequency: frequency, isEnabled: true
                        )
                        manager.add(reminder)
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
        MedicationRemindersView()
    }
}
