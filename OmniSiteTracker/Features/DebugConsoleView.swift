//
//  DebugConsoleView.swift
//  OmniSiteTracker
//
//  Developer debug console
//

import SwiftUI
import SwiftData
import os

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let message: String
    let source: String
    
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        
        var color: Color {
            switch self {
            case .debug: return .secondary
            case .info: return .blue
            case .warning: return .orange
            case .error: return .red
            }
        }
    }
}

@MainActor
@Observable
final class DebugConsole {
    static let shared = DebugConsole()
    var logs: [LogEntry] = []
    var isEnabled = false
    
    private init() {}
    
    func log(_ message: String, level: LogEntry.LogLevel = .info, source: String = "App") {
        guard isEnabled else { return }
        let entry = LogEntry(timestamp: Date(), level: level, message: message, source: source)
        logs.append(entry)
        
        // Keep only last 500 entries
        if logs.count > 500 {
            logs.removeFirst()
        }
    }
    
    func clear() {
        logs.removeAll()
    }
}

struct DebugConsoleView: View {
    @State private var console = DebugConsole.shared
    @State private var filterLevel: LogEntry.LogLevel? = nil
    @State private var searchText = ""
    @Environment(\.modelContext) private var modelContext
    
    private var filteredLogs: [LogEntry] {
        console.logs.filter { entry in
            if let level = filterLevel, entry.level != level {
                return false
            }
            if !searchText.isEmpty {
                return entry.message.localizedCaseInsensitiveContains(searchText)
            }
            return true
        }
    }
    
    var body: some View {
        List {
            Section {
                Toggle("Enable Logging", isOn: $console.isEnabled)
                
                HStack {
                    TextField("Filter logs...", text: $searchText)
                    
                    Menu {
                        Button("All") { filterLevel = nil }
                        ForEach([LogEntry.LogLevel.debug, .info, .warning, .error], id: \.self) { level in
                            Button(level.rawValue) { filterLevel = level }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            
            Section("Actions") {
                Button("Generate Test Data") {
                    generateTestData()
                }
                
                Button("Clear Logs") {
                    console.clear()
                }
            }
            
            Section("Logs (\(filteredLogs.count))") {
                ForEach(filteredLogs.reversed()) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.level.rawValue)
                                .font(.caption.bold())
                                .foregroundStyle(entry.level.color)
                            
                            Text(entry.source)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text(entry.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text(entry.message)
                            .font(.system(.caption, design: .monospaced))
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Debug Console")
    }
    
    private func generateTestData() {
        console.log("Starting test data generation", level: .info, source: "Debug")
        
        for i in 1...5 {
            let log = PlacementLog(site: "Test Site \(i)", placedAt: Date(), notes: "Test entry")
            modelContext.insert(log)
        }
        
        console.log("Generated 5 test entries", level: .debug, source: "Debug")
    }
}

#Preview {
    NavigationStack {
        DebugConsoleView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
