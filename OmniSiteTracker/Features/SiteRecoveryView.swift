//
//  SiteRecoveryView.swift
//  OmniSiteTracker
//
//  Track site recovery and healing progress
//

import SwiftUI
import SwiftData

struct SiteRecoveryStatus: Identifiable {
    let id = UUID()
    let siteName: String
    let lastUsed: Date?
    let recoveryStage: RecoveryStage
    let estimatedFullRecovery: Date?
    let notes: String?
    
    enum RecoveryStage: String, CaseIterable {
        case active = "Active"
        case healing = "Healing"
        case recovered = "Recovered"
        case ready = "Ready"
        
        var color: Color {
            switch self {
            case .active: return .red
            case .healing: return .orange
            case .recovered: return .green
            case .ready: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .active: return "circle.fill"
            case .healing: return "bandage.fill"
            case .recovered: return "checkmark.circle.fill"
            case .ready: return "star.fill"
            }
        }
    }
}

struct SiteRecoveryView: View {
    @Query private var placements: [PlacementLog]
    
    private var recoveryStatuses: [SiteRecoveryStatus] {
        let sites = ["Left Arm", "Right Arm", "Left Thigh", "Right Thigh", "Abdomen Left", "Abdomen Right"]
        let calendar = Calendar.current
        
        return sites.map { site in
            let lastPlacement = placements
                .filter { $0.site == site }
                .max(by: { $0.placedAt < $1.placedAt })
            
            let daysSince = lastPlacement.map {
                calendar.dateComponents([.day], from: $0.placedAt, to: Date()).day ?? 0
            } ?? 999
            
            let stage: SiteRecoveryStatus.RecoveryStage
            if daysSince < 2 {
                stage = .active
            } else if daysSince < 5 {
                stage = .healing
            } else if daysSince < 7 {
                stage = .recovered
            } else {
                stage = .ready
            }
            
            return SiteRecoveryStatus(
                siteName: site,
                lastUsed: lastPlacement?.placedAt,
                recoveryStage: stage,
                estimatedFullRecovery: lastPlacement.map { calendar.date(byAdding: .day, value: 7, to: $0.placedAt) } ?? nil,
                notes: nil
            )
        }
    }
    
    var body: some View {
        List {
            Section {
                ForEach(SiteRecoveryStatus.RecoveryStage.allCases, id: \.self) { stage in
                    HStack {
                        Image(systemName: stage.icon)
                            .foregroundStyle(stage.color)
                        Text(stage.rawValue)
                        Spacer()
                        Text("\(recoveryStatuses.filter { $0.recoveryStage == stage }.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Legend")
            }
            
            Section("All Sites") {
                ForEach(recoveryStatuses) { status in
                    HStack {
                        Image(systemName: status.recoveryStage.icon)
                            .foregroundStyle(status.recoveryStage.color)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(status.siteName)
                                .font(.headline)
                            
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
                        
                        Spacer()
                        
                        Text(status.recoveryStage.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(status.recoveryStage.color.opacity(0.2))
                            .foregroundStyle(status.recoveryStage.color)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .navigationTitle("Site Recovery")
    }
}

#Preview {
    NavigationStack {
        SiteRecoveryView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
