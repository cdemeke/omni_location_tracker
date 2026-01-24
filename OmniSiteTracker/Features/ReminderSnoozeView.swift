//
//  ReminderSnoozeView.swift
//  OmniSiteTracker
//
//  Snooze functionality for reminders
//

import SwiftUI

struct SnoozeOption: Identifiable {
    let id = UUID()
    let label: String
    let minutes: Int
    let icon: String
}

@MainActor
@Observable
final class ReminderSnoozeManager {
    var snoozedUntil: Date?
    var snoozeHistory: [(Date, Int)] = []
    
    private let snoozeOptions: [SnoozeOption] = [
        SnoozeOption(label: "5 minutes", minutes: 5, icon: "clock"),
        SnoozeOption(label: "15 minutes", minutes: 15, icon: "clock"),
        SnoozeOption(label: "30 minutes", minutes: 30, icon: "clock"),
        SnoozeOption(label: "1 hour", minutes: 60, icon: "clock.fill"),
        SnoozeOption(label: "2 hours", minutes: 120, icon: "clock.fill"),
        SnoozeOption(label: "Tomorrow", minutes: 1440, icon: "sun.max")
    ]
    
    var options: [SnoozeOption] { snoozeOptions }
    
    var isSnoozed: Bool {
        guard let until = snoozedUntil else { return false }
        return until > Date()
    }
    
    var remainingTime: String {
        guard let until = snoozedUntil, until > Date() else { return "" }
        let interval = until.timeIntervalSince(Date())
        let minutes = Int(interval / 60)
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }
    
    func snooze(minutes: Int) {
        snoozedUntil = Date().addingTimeInterval(Double(minutes * 60))
        snoozeHistory.append((Date(), minutes))
    }
    
    func cancelSnooze() {
        snoozedUntil = nil
    }
}

struct ReminderSnoozeView: View {
    @State private var manager = ReminderSnoozeManager()
    
    var body: some View {
        List {
            if manager.isSnoozed {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue)
                        
                        Text("Reminders Snoozed")
                            .font(.headline)
                        
                        Text("Resuming in \(manager.remainingTime)")
                            .foregroundStyle(.secondary)
                        
                        Button("Cancel Snooze") {
                            manager.cancelSnooze()
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
            }
            
            Section("Snooze For") {
                ForEach(manager.options) { option in
                    Button {
                        manager.snooze(minutes: option.minutes)
                    } label: {
                        Label(option.label, systemImage: option.icon)
                    }
                    .disabled(manager.isSnoozed)
                }
            }
            
            if !manager.snoozeHistory.isEmpty {
                Section("Recent Snoozes") {
                    ForEach(manager.snoozeHistory.suffix(5).reversed(), id: \.0) { entry in
                        HStack {
                            Text(entry.0.formatted(date: .abbreviated, time: .shortened))
                            Spacer()
                            Text("\(entry.1) min")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Snooze")
    }
}

#Preview {
    NavigationStack {
        ReminderSnoozeView()
    }
}
