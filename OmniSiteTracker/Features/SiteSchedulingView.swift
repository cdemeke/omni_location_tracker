//
//  SiteSchedulingView.swift
//  OmniSiteTracker
//
//  Plan future site rotations
//

import SwiftUI

struct ScheduledSite: Identifiable {
    let id = UUID()
    var siteName: String
    var scheduledDate: Date
    var isCompleted: Bool
}

@MainActor
@Observable
final class SiteSchedulingManager {
    var scheduledSites: [ScheduledSite] = []
    
    func schedule(site: String, date: Date) {
        let scheduled = ScheduledSite(siteName: site, scheduledDate: date, isCompleted: false)
        scheduledSites.append(scheduled)
        scheduledSites.sort { $0.scheduledDate < $1.scheduledDate }
    }
    
    func markComplete(_ scheduled: ScheduledSite) {
        if let index = scheduledSites.firstIndex(where: { $0.id == scheduled.id }) {
            scheduledSites[index].isCompleted = true
        }
    }
    
    func delete(_ scheduled: ScheduledSite) {
        scheduledSites.removeAll { $0.id == scheduled.id }
    }
    
    func autoSchedule(days: Int, sites: [String]) {
        var currentDate = Date()
        let calendar = Calendar.current
        
        for i in 0..<days {
            let site = sites[i % sites.count]
            currentDate = calendar.date(byAdding: .day, value: i == 0 ? 0 : 1, to: currentDate)!
            schedule(site: site, date: currentDate)
        }
    }
}

struct SiteSchedulingView: View {
    @State private var manager = SiteSchedulingManager()
    @State private var showingAutoSchedule = false
    @State private var showingAddSchedule = false
    
    private var upcomingSites: [ScheduledSite] {
        manager.scheduledSites.filter { !$0.isCompleted && $0.scheduledDate >= Calendar.current.startOfDay(for: Date()) }
    }
    
    var body: some View {
        List {
            Section {
                Button {
                    showingAutoSchedule = true
                } label: {
                    Label("Auto-Schedule", systemImage: "wand.and.stars")
                }
                
                Button {
                    showingAddSchedule = true
                } label: {
                    Label("Add Manual", systemImage: "plus.circle")
                }
            }
            
            Section("Upcoming Schedule") {
                if upcomingSites.isEmpty {
                    Text("No sites scheduled")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(upcomingSites) { scheduled in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(scheduled.siteName)
                                    .font(.headline)
                                Text(scheduled.scheduledDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                manager.markComplete(scheduled)
                            } label: {
                                Image(systemName: scheduled.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(scheduled.isCompleted ? .green : .secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            manager.delete(upcomingSites[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("Site Schedule")
        .sheet(isPresented: $showingAutoSchedule) {
            AutoScheduleView(manager: manager)
        }
        .sheet(isPresented: $showingAddSchedule) {
            AddScheduleView(manager: manager)
        }
    }
}

struct AutoScheduleView: View {
    @Bindable var manager: SiteSchedulingManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var days = 7
    @State private var selectedSites: Set<String> = ["Left Arm", "Right Arm", "Left Thigh", "Right Thigh"]
    
    private let allSites = ["Left Arm", "Right Arm", "Left Thigh", "Right Thigh", "Abdomen Left", "Abdomen Right"]
    
    var body: some View {
        NavigationStack {
            Form {
                Stepper("Schedule for \(days) days", value: $days, in: 1...30)
                
                Section("Include Sites") {
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
            .navigationTitle("Auto Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        manager.autoSchedule(days: days, sites: Array(selectedSites))
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AddScheduleView: View {
    @Bindable var manager: SiteSchedulingManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSite = "Left Arm"
    @State private var date = Date()
    
    private let sites = ["Left Arm", "Right Arm", "Left Thigh", "Right Thigh", "Abdomen Left", "Abdomen Right"]
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Site", selection: $selectedSite) {
                    ForEach(sites, id: \.self) { site in
                        Text(site).tag(site)
                    }
                }
                
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
            .navigationTitle("Schedule Site")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        manager.schedule(site: selectedSite, date: date)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SiteSchedulingView()
    }
}
