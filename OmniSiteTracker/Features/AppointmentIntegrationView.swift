//
//  AppointmentIntegrationView.swift
//  OmniSiteTracker
//
//  Sync with doctor appointments
//

import SwiftUI
import EventKit

struct Appointment: Identifiable {
    let id = UUID()
    var title: String
    var date: Date
    var doctor: String
    var notes: String?
    var reminderSet: Bool
}

@MainActor
@Observable
final class AppointmentManager {
    var appointments: [Appointment] = []
    var hasCalendarAccess = false
    
    func requestAccess() async {
        let store = EKEventStore()
        do {
            hasCalendarAccess = try await store.requestFullAccessToEvents()
        } catch {
            hasCalendarAccess = false
        }
    }
    
    func add(_ appointment: Appointment) {
        appointments.append(appointment)
        appointments.sort { $0.date < $1.date }
    }
    
    func delete(_ appointment: Appointment) {
        appointments.removeAll { $0.id == appointment.id }
    }
}

struct AppointmentIntegrationView: View {
    @State private var manager = AppointmentManager()
    @State private var showingAddAppointment = false
    
    private var upcomingAppointments: [Appointment] {
        manager.appointments.filter { $0.date >= Date() }
    }
    
    private var pastAppointments: [Appointment] {
        manager.appointments.filter { $0.date < Date() }
    }
    
    var body: some View {
        List {
            if !manager.hasCalendarAccess {
                Section {
                    Button {
                        Task {
                            await manager.requestAccess()
                        }
                    } label: {
                        Label("Connect Calendar", systemImage: "calendar.badge.plus")
                    }
                }
            }
            
            Section("Upcoming") {
                if upcomingAppointments.isEmpty {
                    Text("No upcoming appointments")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(upcomingAppointments) { appointment in
                        AppointmentRow(appointment: appointment)
                    }
                }
            }
            
            if !pastAppointments.isEmpty {
                Section("Past") {
                    ForEach(pastAppointments) { appointment in
                        AppointmentRow(appointment: appointment)
                    }
                }
            }
        }
        .navigationTitle("Appointments")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddAppointment = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddAppointment) {
            AddAppointmentView(manager: manager)
        }
    }
}

struct AppointmentRow: View {
    let appointment: Appointment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(appointment.title)
                .font(.headline)
            
            HStack {
                Image(systemName: "person")
                Text(appointment.doctor)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            
            HStack {
                Image(systemName: "calendar")
                Text(appointment.date.formatted(date: .abbreviated, time: .shortened))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AddAppointmentView: View {
    @Bindable var manager: AppointmentManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var date = Date()
    @State private var doctor = ""
    @State private var notes = ""
    @State private var setReminder = true
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Appointment Title", text: $title)
                TextField("Doctor Name", text: $doctor)
                DatePicker("Date & Time", selection: $date)
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
                
                Toggle("Set Reminder", isOn: $setReminder)
            }
            .navigationTitle("New Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let appointment = Appointment(
                            title: title,
                            date: date,
                            doctor: doctor,
                            notes: notes.isEmpty ? nil : notes,
                            reminderSet: setReminder
                        )
                        manager.add(appointment)
                        dismiss()
                    }
                    .disabled(title.isEmpty || doctor.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AppointmentIntegrationView()
    }
}
