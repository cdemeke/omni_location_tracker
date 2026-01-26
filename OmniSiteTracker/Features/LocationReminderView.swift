//
//  LocationReminderView.swift
//  OmniSiteTracker
//
//  Location-based reminder system
//

import SwiftUI
import CoreLocation
import UserNotifications

struct LocationReminder: Identifiable, Codable {
    let id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var radius: Double
    var triggerOnEntry: Bool
    var triggerOnExit: Bool
    var message: String
    var isEnabled: Bool
    var createdAt: Date
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

@MainActor
@Observable
final class LocationReminderManager: NSObject {
    static let shared = LocationReminderManager()
    
    private(set) var reminders: [LocationReminder] = []
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var isMonitoring = false
    
    private let locationManager = CLLocationManager()
    private let storageKey = "location_reminders"
    
    override init() {
        super.init()
        locationManager.delegate = self
        loadReminders()
    }
    
    func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func addReminder(_ reminder: LocationReminder) {
        reminders.append(reminder)
        saveReminders()
        if reminder.isEnabled { startMonitoring(reminder) }
    }
    
    func deleteReminder(_ reminder: LocationReminder) {
        stopMonitoring(reminder)
        reminders.removeAll { $0.id == reminder.id }
        saveReminders()
    }
    
    func toggleReminder(_ reminder: LocationReminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index].isEnabled.toggle()
            saveReminders()
            if reminders[index].isEnabled {
                startMonitoring(reminders[index])
            } else {
                stopMonitoring(reminders[index])
            }
        }
    }
    
    private func startMonitoring(_ reminder: LocationReminder) {
        let region = CLCircularRegion(center: reminder.coordinate, radius: reminder.radius, identifier: reminder.id.uuidString)
        region.notifyOnEntry = reminder.triggerOnEntry
        region.notifyOnExit = reminder.triggerOnExit
        locationManager.startMonitoring(for: region)
        isMonitoring = true
    }
    
    private func stopMonitoring(_ reminder: LocationReminder) {
        for region in locationManager.monitoredRegions where region.identifier == reminder.id.uuidString {
            locationManager.stopMonitoring(for: region)
        }
    }
    
    private func triggerNotification(for reminder: LocationReminder) {
        let content = UNMutableNotificationContent()
        content.title = "Site Reminder"
        content.body = reminder.message
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func loadReminders() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([LocationReminder].self, from: data) {
            reminders = decoded
        }
    }
    
    private func saveReminders() {
        if let data = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

extension LocationReminderManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in self.authorizationStatus = manager.authorizationStatus }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            if let reminder = reminders.first(where: { $0.id.uuidString == region.identifier }) {
                triggerNotification(for: reminder)
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Task { @MainActor in
            if let reminder = reminders.first(where: { $0.id.uuidString == region.identifier }) {
                triggerNotification(for: reminder)
            }
        }
    }
}

struct LocationReminderListView: View {
    @State private var manager = LocationReminderManager.shared
    @State private var showAddSheet = false
    
    var body: some View {
        List {
            if manager.authorizationStatus != .authorizedAlways {
                Section {
                    Button("Enable Location Access") { manager.requestAuthorization() }
                    Text("Always-on location is required for geofence reminders")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            
            Section("Reminders") {
                if manager.reminders.isEmpty {
                    Text("No location reminders").foregroundStyle(.secondary)
                } else {
                    ForEach(manager.reminders) { reminder in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(reminder.name).font(.headline)
                                Text(reminder.message).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { reminder.isEnabled },
                                set: { _ in manager.toggleReminder(reminder) }
                            ))
                        }
                        .swipeActions { Button(role: .destructive) { manager.deleteReminder(reminder) } label: { Label("Delete", systemImage: "trash") } }
                    }
                }
            }
        }
        .navigationTitle("Location Reminders")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddSheet = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddLocationReminderView(manager: manager)
        }
    }
}

struct AddLocationReminderView: View {
    let manager: LocationReminderManager
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var message = "Time to check your site!"
    @State private var radius = 100.0
    @State private var triggerOnEntry = true
    @State private var triggerOnExit = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    TextField("Name", text: $name)
                    Slider(value: $radius, in: 50...500, step: 25)
                    Text("Radius: \(Int(radius))m").font(.caption)
                }
                Section("Trigger") {
                    Toggle("On Arrival", isOn: $triggerOnEntry)
                    Toggle("On Departure", isOn: $triggerOnExit)
                }
                Section("Message") { TextField("Message", text: $message) }
                Section {
                    Button("Save") {
                        let reminder = LocationReminder(id: UUID(), name: name, latitude: 0, longitude: 0, radius: radius, triggerOnEntry: triggerOnEntry, triggerOnExit: triggerOnExit, message: message, isEnabled: true, createdAt: Date())
                        manager.addReminder(reminder)
                        dismiss()
                    }.disabled(name.isEmpty)
                }
            }
            .navigationTitle("New Reminder")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}

#Preview { NavigationStack { LocationReminderListView() } }
