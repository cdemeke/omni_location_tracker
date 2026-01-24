//
//  LocationReminderManager.swift
//  OmniSiteTracker
//
//  Location-based reminders using CoreLocation.
//

import Foundation
import CoreLocation
import UserNotifications
import SwiftUI

@MainActor
@Observable
final class LocationReminderManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationReminderManager()
    
    private let locationManager = CLLocationManager()
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var savedLocations: [SavedLocation] = []
    
    struct SavedLocation: Identifiable, Codable {
        let id: UUID
        var name: String
        var latitude: Double
        var longitude: Double
        var radius: Double
        var triggerOnEntry: Bool
        var reminderMessage: String
    }
    
    private override init() {
        super.init()
        locationManager.delegate = self
        loadLocations()
    }
    
    func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func addLocation(_ location: SavedLocation) {
        savedLocations.append(location)
        saveLocations()
        startMonitoring(location)
    }
    
    func removeLocation(_ location: SavedLocation) {
        savedLocations.removeAll { $0.id == location.id }
        saveLocations()
        stopMonitoring(location)
    }
    
    private func startMonitoring(_ location: SavedLocation) {
        let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let region = CLCircularRegion(center: center, radius: location.radius, identifier: location.id.uuidString)
        region.notifyOnEntry = location.triggerOnEntry
        region.notifyOnExit = !location.triggerOnEntry
        locationManager.startMonitoring(for: region)
    }
    
    private func stopMonitoring(_ location: SavedLocation) {
        for region in locationManager.monitoredRegions {
            if region.identifier == location.id.uuidString {
                locationManager.stopMonitoring(for: region)
                break
            }
        }
    }
    
    private func loadLocations() {
        if let data = UserDefaults.standard.data(forKey: "savedLocations"),
           let locations = try? JSONDecoder().decode([SavedLocation].self, from: data) {
            savedLocations = locations
        }
    }
    
    private func saveLocations() {
        if let data = try? JSONEncoder().encode(savedLocations) {
            UserDefaults.standard.set(data, forKey: "savedLocations")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            if let location = savedLocations.first(where: { $0.id.uuidString == region.identifier }) {
                sendNotification(for: location)
            }
        }
    }
    
    private func sendNotification(for location: SavedLocation) {
        let content = UNMutableNotificationContent()
        content.title = "Pump Site Reminder"
        content.body = location.reminderMessage
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }
}

struct LocationRemindersView: View {
    @State private var locationManager = LocationReminderManager.shared
    @State private var showingAddLocation = false
    
    var body: some View {
        List {
            Section {
                if locationManager.authorizationStatus != .authorizedAlways {
                    Button("Enable Location Access") {
                        locationManager.requestAuthorization()
                    }
                }
            }
            
            Section {
                ForEach(locationManager.savedLocations) { location in
                    VStack(alignment: .leading) {
                        Text(location.name)
                            .font(.headline)
                        Text(location.reminderMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        locationManager.removeLocation(locationManager.savedLocations[index])
                    }
                }
                
                Button("Add Location") {
                    showingAddLocation = true
                }
            } header: {
                Text("Saved Locations")
            }
        }
        .navigationTitle("Location Reminders")
        .sheet(isPresented: $showingAddLocation) {
            AddLocationView()
        }
    }
}

struct AddLocationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var message = "Time to check your pump site!"
    @State private var triggerOnEntry = true
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Location Name", text: $name)
                TextField("Reminder Message", text: $message)
                Toggle("Trigger on Arrival", isOn: $triggerOnEntry)
                
                Text("Note: Use current location or enter coordinates manually")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Add Location")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Save with default coordinates
                        let location = LocationReminderManager.SavedLocation(
                            id: UUID(),
                            name: name,
                            latitude: 37.7749,
                            longitude: -122.4194,
                            radius: 100,
                            triggerOnEntry: triggerOnEntry,
                            reminderMessage: message
                        )
                        LocationReminderManager.shared.addLocation(location)
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
        LocationRemindersView()
    }
}
