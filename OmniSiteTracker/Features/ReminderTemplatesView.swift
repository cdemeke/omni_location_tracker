//
//  ReminderTemplatesView.swift
//  OmniSiteTracker
//
//  Pre-configured reminder templates
//

import SwiftUI

struct ReminderTemplate: Identifiable {
    let id = UUID()
    var name: String
    var frequency: Frequency
    var time: Date
    var message: String
    var isEnabled: Bool
    
    enum Frequency: String, CaseIterable {
        case daily = "Daily"
        case everyOtherDay = "Every Other Day"
        case weekly = "Weekly"
        case custom = "Custom"
    }
}

@MainActor
@Observable
final class ReminderTemplateManager {
    var templates: [ReminderTemplate] = [
        ReminderTemplate(
            name: "Morning Check",
            frequency: .daily,
            time: Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(),
            message: "Time for your morning site check!",
            isEnabled: true
        )
    ]
}

struct ReminderTemplatesView: View {
    @State private var manager = ReminderTemplateManager()
    
    var body: some View {
        List {
            ForEach($manager.templates) { $template in
                HStack {
                    VStack(alignment: .leading) {
                        Text(template.name)
                            .font(.headline)
                        Text(template.frequency.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $template.isEnabled)
                }
            }
        }
        .navigationTitle("Reminder Templates")
    }
}

#Preview {
    NavigationStack {
        ReminderTemplatesView()
    }
}
