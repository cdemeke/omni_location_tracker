//
//  RotationTipCalculatorView.swift
//  OmniSiteTracker
//
//  Calculate optimal rotation intervals
//

import SwiftUI

struct RotationTipCalculatorView: View {
    @State private var siteCount = 6
    @State private var daysPerSite = 3
    @State private var includeRest = true
    @State private var restDays = 1
    
    private var cycleLength: Int {
        let baseCycle = siteCount * daysPerSite
        return includeRest ? baseCycle + (siteCount * restDays) : baseCycle
    }
    
    private var yearlyRotations: Int {
        365 / cycleLength
    }
    
    var body: some View {
        List {
            Section("Configuration") {
                Stepper("Available Sites: \(siteCount)", value: $siteCount, in: 2...12)
                Stepper("Days per Site: \(daysPerSite)", value: $daysPerSite, in: 1...14)
                
                Toggle("Include Rest Days", isOn: $includeRest)
                
                if includeRest {
                    Stepper("Rest Days between Sites: \(restDays)", value: $restDays, in: 0...7)
                }
            }
            
            Section("Calculation") {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Full Cycle")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(cycleLength) days")
                            .font(.title2)
                            .bold()
                    }
                    
                    HStack {
                        Text("Cycles per Year")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(yearlyRotations)")
                            .font(.title2)
                    }
                    
                    Divider()
                    
                    Text("Each site will be used approximately \(yearlyRotations) times per year")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section("Recommendations") {
                Label("Consistent rotation promotes even healing", systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
                
                if daysPerSite > 7 {
                    Label("Consider shorter intervals for better absorption", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
                
                if !includeRest {
                    Label("Adding rest days can improve site recovery", systemImage: "info.circle")
                        .foregroundStyle(.blue)
                }
            }
        }
        .navigationTitle("Rotation Calculator")
    }
}

#Preview {
    NavigationStack {
        RotationTipCalculatorView()
    }
}
