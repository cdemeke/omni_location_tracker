//
//  HealthExportView.swift
//  OmniSiteTracker
//
//  Export data to Apple Health
//

import SwiftUI
import HealthKit

@MainActor
@Observable
final class HealthExportManager {
    var isAuthorized = false
    var isExporting = false
    var lastExport: Date?
    var exportedCount = 0
    
    private let healthStore = HKHealthStore()
    
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization() async {
        // In production, request HealthKit authorization
        try? await Task.sleep(for: .milliseconds(500))
        isAuthorized = true
    }
    
    func exportToHealth(recordCount: Int) async {
        isExporting = true
        
        for i in 1...5 {
            try? await Task.sleep(for: .milliseconds(300))
        }
        
        exportedCount = recordCount
        lastExport = Date()
        isExporting = false
    }
}

struct HealthExportView: View {
    @State private var manager = HealthExportManager()
    @State private var recordsToExport = 30
    
    var body: some View {
        List {
            if !manager.isHealthKitAvailable {
                Section {
                    Label("Health data is not available on this device", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            } else if !manager.isAuthorized {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.red)
                        
                        Text("Connect to Health")
                            .font(.headline)
                        
                        Text("Export your site data to Apple Health for comprehensive health tracking.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        
                        Button("Authorize Health Access") {
                            Task {
                                await manager.requestAuthorization()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            } else {
                Section("Export Settings") {
                    Stepper("Last \(recordsToExport) records", value: $recordsToExport, in: 7...365, step: 7)
                    
                    Toggle("Include Notes", isOn: .constant(true))
                    Toggle("Include Photos", isOn: .constant(false))
                }
                
                Section {
                    Button {
                        Task {
                            await manager.exportToHealth(recordCount: recordsToExport)
                        }
                    } label: {
                        HStack {
                            if manager.isExporting {
                                ProgressView()
                            }
                            Text("Export to Health")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(manager.isExporting)
                }
                
                if let lastExport = manager.lastExport {
                    Section("Last Export") {
                        LabeledContent("Date", value: lastExport.formatted())
                        LabeledContent("Records", value: "\(manager.exportedCount)")
                    }
                }
            }
        }
        .navigationTitle("Health Export")
    }
}

#Preview {
    NavigationStack {
        HealthExportView()
    }
}
