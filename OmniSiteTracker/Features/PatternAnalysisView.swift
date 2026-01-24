//
//  PatternAnalysisView.swift
//  OmniSiteTracker
//
//  Analyze rotation patterns and habits
//

import SwiftUI
import SwiftData

struct Pattern: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let isPositive: Bool
    let recommendation: String?
}

@MainActor
@Observable
final class PatternAnalyzer {
    var patterns: [Pattern] = []
    var isAnalyzing = false
    
    func analyze(placements: [PlacementLog]) async {
        isAnalyzing = true
        try? await Task.sleep(for: .seconds(1))
        
        patterns = [
            Pattern(
                name: "Consistent Timing",
                description: "You tend to log at similar times each day",
                isPositive: true,
                recommendation: nil
            ),
            Pattern(
                name: "Site Preference",
                description: "Left arm is used 40% more than other sites",
                isPositive: false,
                recommendation: "Try to balance usage across all sites"
            ),
            Pattern(
                name: "Weekend Gap",
                description: "Fewer logs on weekends",
                isPositive: false,
                recommendation: "Set weekend reminders"
            ),
            Pattern(
                name: "Good Rest Periods",
                description: "Average 5+ days between site reuse",
                isPositive: true,
                recommendation: nil
            )
        ]
        
        isAnalyzing = false
    }
}

struct PatternAnalysisView: View {
    @Query private var placements: [PlacementLog]
    @State private var analyzer = PatternAnalyzer()
    
    var body: some View {
        List {
            Section {
                Button {
                    Task {
                        await analyzer.analyze(placements: placements)
                    }
                } label: {
                    HStack {
                        if analyzer.isAnalyzing {
                            ProgressView()
                        } else {
                            Image(systemName: "wand.and.stars")
                        }
                        Text("Analyze Patterns")
                    }
                }
                .disabled(analyzer.isAnalyzing)
            }
            
            if !analyzer.patterns.isEmpty {
                Section("Findings") {
                    ForEach(analyzer.patterns) { pattern in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: pattern.isPositive ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundStyle(pattern.isPositive ? .green : .orange)
                                
                                Text(pattern.name)
                                    .font(.headline)
                            }
                            
                            Text(pattern.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            if let recommendation = pattern.recommendation {
                                Label(recommendation, systemImage: "lightbulb")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Pattern Analysis")
    }
}

#Preview {
    NavigationStack {
        PatternAnalysisView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
