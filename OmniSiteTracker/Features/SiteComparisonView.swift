//
//  SiteComparisonView.swift
//  OmniSiteTracker
//
//  Compare metrics between different sites
//

import SwiftUI
import SwiftData

struct SiteMetrics {
    let site: String
    let totalUses: Int
    let avgRestDays: Double
    let symptomRate: Double
    let healingScore: Int
}

struct SiteComparisonView: View {
    @Query private var placements: [PlacementLog]
    @State private var selectedSites: Set<String> = []
    @State private var comparisonMetrics: [SiteMetrics] = []
    
    private var availableSites: [String] {
        Array(Set(placements.map { $0.site })).sorted()
    }
    
    var body: some View {
        List {
            Section("Select Sites to Compare") {
                ForEach(availableSites, id: \.self) { site in
                    Button {
                        if selectedSites.contains(site) {
                            selectedSites.remove(site)
                        } else if selectedSites.count < 4 {
                            selectedSites.insert(site)
                        }
                    } label: {
                        HStack {
                            Text(site)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedSites.contains(site) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            
            if selectedSites.count >= 2 {
                Section("Comparison") {
                    ComparisonChart(sites: Array(selectedSites))
                }
                
                Section("Details") {
                    ForEach(Array(selectedSites), id: \.self) { site in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(site)
                                .font(.headline)
                            
                            HStack {
                                MetricPill(label: "Uses", value: "\(placements.filter { $0.site == site }.count)")
                                MetricPill(label: "Symptoms", value: "2")
                                MetricPill(label: "Score", value: "85")
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                Section {
                    Text("Select at least 2 sites to compare")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Compare Sites")
    }
}

struct ComparisonChart: View {
    let sites: [String]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            ForEach(sites, id: \.self) { site in
                VStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.blue.gradient)
                        .frame(width: 40, height: CGFloat.random(in: 50...150))
                    
                    Text(site.prefix(8))
                        .font(.caption2)
                        .lineLimit(1)
                }
            }
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct MetricPill: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        SiteComparisonView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
