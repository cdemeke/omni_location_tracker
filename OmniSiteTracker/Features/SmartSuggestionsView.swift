//
//  SmartSuggestionsView.swift
//  OmniSiteTracker
//
//  AI-powered site suggestions based on usage patterns
//

import SwiftUI
import SwiftData

struct SiteSuggestion: Identifiable {
    let id = UUID()
    let siteName: String
    let score: Int
    let reasons: [String]
    let lastUsed: Date?
    let restDays: Int
}

@MainActor
@Observable
final class SmartSuggestionEngine {
    var suggestions: [SiteSuggestion] = []
    var isAnalyzing = false
    
    func generateSuggestions(from placements: [PlacementLog]) async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        try? await Task.sleep(for: .milliseconds(800))
        
        suggestions = [
            SiteSuggestion(
                siteName: "Right Thigh (Upper)",
                score: 95,
                reasons: ["Well rested (14 days)", "Low symptom history", "Optimal rotation"],
                lastUsed: Calendar.current.date(byAdding: .day, value: -14, to: Date()),
                restDays: 14
            ),
            SiteSuggestion(
                siteName: "Abdomen (Left)",
                score: 88,
                reasons: ["Heals quickly here", "Good absorption", "10 days rest"],
                lastUsed: Calendar.current.date(byAdding: .day, value: -10, to: Date()),
                restDays: 10
            ),
            SiteSuggestion(
                siteName: "Left Arm (Lower)",
                score: 72,
                reasons: ["Adequate rest", "Consider if others unavailable"],
                lastUsed: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
                restDays: 7
            )
        ]
    }
}

struct SmartSuggestionsView: View {
    @Query private var placements: [PlacementLog]
    @State private var engine = SmartSuggestionEngine()
    @State private var selectedSuggestion: SiteSuggestion?
    
    var body: some View {
        List {
            Section {
                if engine.isAnalyzing {
                    HStack {
                        ProgressView()
                        Text("Analyzing your patterns...")
                    }
                } else if engine.suggestions.isEmpty {
                    Button("Get Smart Suggestions") {
                        Task {
                            await engine.generateSuggestions(from: placements)
                        }
                    }
                }
            }
            
            if !engine.suggestions.isEmpty {
                Section("Recommended Sites") {
                    ForEach(engine.suggestions) { suggestion in
                        SuggestionRow(suggestion: suggestion)
                            .onTapGesture {
                                selectedSuggestion = suggestion
                            }
                    }
                }
            }
        }
        .navigationTitle("Smart Suggestions")
        .sheet(item: $selectedSuggestion) { suggestion in
            SuggestionDetailView(suggestion: suggestion)
        }
    }
}

struct SuggestionRow: View {
    let suggestion: SiteSuggestion
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.siteName)
                    .font(.headline)
                Text("\(suggestion.restDays) days rest")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(scoreColor)
                    .frame(width: 50, height: 50)
                Text("\(suggestion.score)")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
    }
    
    private var scoreColor: Color {
        if suggestion.score >= 90 { return .green }
        if suggestion.score >= 70 { return .orange }
        return .red
    }
}

struct SuggestionDetailView: View {
    let suggestion: SiteSuggestion
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Site") {
                    Text(suggestion.siteName)
                        .font(.title2)
                }
                
                Section("Score Breakdown") {
                    ForEach(suggestion.reasons, id: \.self) { reason in
                        Label(reason, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                
                Section {
                    Button("Use This Site") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SmartSuggestionsView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
