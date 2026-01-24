//
//  SymptomCorrelationView.swift
//  OmniSiteTracker
//
//  Analyze correlations between sites and symptoms
//

import SwiftUI
import SwiftData

struct SymptomCorrelation: Identifiable {
    let id = UUID()
    let siteName: String
    let symptom: String
    let occurrences: Int
    let percentage: Double
    let trend: Trend
    
    enum Trend: String {
        case increasing = "arrow.up.right"
        case decreasing = "arrow.down.right"
        case stable = "arrow.right"
    }
}

@MainActor
@Observable
final class SymptomCorrelationAnalyzer {
    var correlations: [SymptomCorrelation] = []
    var isAnalyzing = false
    
    func analyze(placements: [PlacementLog]) async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        // Simulate analysis
        try? await Task.sleep(for: .seconds(1))
        
        // Generate sample correlations
        correlations = [
            SymptomCorrelation(siteName: "Left Arm", symptom: "Mild Irritation", occurrences: 3, percentage: 15.0, trend: .decreasing),
            SymptomCorrelation(siteName: "Right Thigh", symptom: "Redness", occurrences: 2, percentage: 10.0, trend: .stable),
            SymptomCorrelation(siteName: "Abdomen Left", symptom: "Bruising", occurrences: 1, percentage: 5.0, trend: .decreasing)
        ]
    }
}

struct SymptomCorrelationView: View {
    @Query private var placements: [PlacementLog]
    @State private var analyzer = SymptomCorrelationAnalyzer()
    
    var body: some View {
        List {
            Section {
                if analyzer.isAnalyzing {
                    HStack {
                        ProgressView()
                        Text("Analyzing patterns...")
                    }
                } else {
                    Button("Run Analysis") {
                        Task {
                            await analyzer.analyze(placements: placements)
                        }
                    }
                }
            }
            
            if !analyzer.correlations.isEmpty {
                Section("Findings") {
                    ForEach(analyzer.correlations) { correlation in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(correlation.siteName)
                                    .font(.headline)
                                Spacer()
                                Image(systemName: correlation.trend.rawValue)
                                    .foregroundStyle(correlation.trend == .decreasing ? .green : .orange)
                            }
                            
                            HStack {
                                Text(correlation.symptom)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(correlation.occurrences) times (\(String(format: "%.0f", correlation.percentage))%)")
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Recommendations") {
                    Label("Consider avoiding Left Arm for 2 weeks", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Label("Right Thigh showing good tolerance", systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle("Symptom Correlation")
    }
}

#Preview {
    NavigationStack {
        SymptomCorrelationView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
