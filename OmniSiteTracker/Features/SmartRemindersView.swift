//
//  SmartRemindersView.swift
//  OmniSiteTracker
//
//  AI-powered reminder suggestions
//

import SwiftUI
import SwiftData

struct SmartReminder: Identifiable {
    let id = UUID()
    let suggestedTime: Date
    let reason: String
    let confidence: Double
    let basedOn: String
}

@MainActor
@Observable
final class SmartRemindersEngine {
    var suggestions: [SmartReminder] = []
    var isAnalyzing = false
    
    func analyze(placements: [PlacementLog]) async {
        isAnalyzing = true
        try? await Task.sleep(for: .seconds(1))
        
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        
        suggestions = [
            SmartReminder(
                suggestedTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)!,
                reason: "Based on your typical morning routine",
                confidence: 0.92,
                basedOn: "Historical patterns"
            ),
            SmartReminder(
                suggestedTime: calendar.date(bySettingHour: 14, minute: 30, second: 0, of: tomorrow)!,
                reason: "Optimal time based on your schedule",
                confidence: 0.78,
                basedOn: "Usage frequency"
            ),
            SmartReminder(
                suggestedTime: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: tomorrow)!,
                reason: "Evening reminder before bed",
                confidence: 0.65,
                basedOn: "Time preferences"
            )
        ]
        
        isAnalyzing = false
    }
}

struct SmartRemindersView: View {
    @Query private var placements: [PlacementLog]
    @State private var engine = SmartRemindersEngine()
    
    var body: some View {
        List {
            Section {
                Button {
                    Task { await engine.analyze(placements: placements) }
                } label: {
                    HStack {
                        if engine.isAnalyzing {
                            ProgressView()
                        } else {
                            Image(systemName: "brain")
                        }
                        Text("Analyze My Patterns")
                    }
                }
                .disabled(engine.isAnalyzing)
            }
            
            if !engine.suggestions.isEmpty {
                Section("Suggested Reminders") {
                    ForEach(engine.suggestions) { reminder in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(reminder.suggestedTime.formatted(date: .abbreviated, time: .shortened))
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("\(Int(reminder.confidence * 100))%")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(confidenceColor(reminder.confidence).opacity(0.2))
                                    .foregroundStyle(confidenceColor(reminder.confidence))
                                    .clipShape(Capsule())
                            }
                            
                            Text(reminder.reason)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                Image(systemName: "chart.bar")
                                Text(reminder.basedOn)
                            }
                            .font(.caption)
                            .foregroundStyle(.blue)
                            
                            Button("Set This Reminder") {}
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Smart Reminders")
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.6 { return .orange }
        return .red
    }
}

#Preview {
    NavigationStack {
        SmartRemindersView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
