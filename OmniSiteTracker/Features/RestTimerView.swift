//
//  RestTimerView.swift
//  OmniSiteTracker
//
//  Track rest time for each site
//

import SwiftUI
import SwiftData

struct SiteRestStatus: Identifiable {
    let id = UUID()
    let siteName: String
    let lastUsed: Date?
    let recommendedRestDays: Int
    
    var daysRested: Int {
        guard let lastUsed = lastUsed else { return 999 }
        return Calendar.current.dateComponents([.day], from: lastUsed, to: Date()).day ?? 0
    }
    
    var isRested: Bool {
        daysRested >= recommendedRestDays
    }
    
    var restProgress: Double {
        guard recommendedRestDays > 0, let _ = lastUsed else { return 1.0 }
        return min(1.0, Double(daysRested) / Double(recommendedRestDays))
    }
}

struct RestTimerView: View {
    @Query private var placements: [PlacementLog]
    @State private var recommendedRestDays = 7
    
    private var siteStatuses: [SiteRestStatus] {
        let sites = ["Left Arm", "Right Arm", "Left Thigh", "Right Thigh", "Abdomen Left", "Abdomen Right"]
        
        return sites.map { site in
            let lastUsed = placements
                .filter { $0.site == site }
                .max(by: { $0.placedAt < $1.placedAt })?.placedAt
            
            return SiteRestStatus(
                siteName: site,
                lastUsed: lastUsed,
                recommendedRestDays: recommendedRestDays
            )
        }
    }
    
    var body: some View {
        List {
            Section {
                Stepper("Recommended Rest: \(recommendedRestDays) days", value: $recommendedRestDays, in: 1...30)
            }
            
            Section("Site Status") {
                ForEach(siteStatuses) { status in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(status.siteName)
                                .font(.headline)
                            
                            Spacer()
                            
                            if status.isRested {
                                Label("Ready", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                            } else {
                                Text("\(status.recommendedRestDays - status.daysRested) days left")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        
                        ProgressView(value: status.restProgress)
                            .tint(status.isRested ? .green : .orange)
                        
                        if let lastUsed = status.lastUsed {
                            Text("Last used: \(lastUsed.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Never used")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Rest Timer")
    }
}

#Preview {
    NavigationStack {
        RestTimerView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
