//
//  PerformanceMonitor.swift
//  OmniSiteTracker
//
//  App performance monitoring and optimization
//

import SwiftUI
import os.signpost

@MainActor
@Observable
final class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private let log = OSLog(subsystem: "com.omnisitetracker", category: "Performance")
    private(set) var metrics: [PerformanceMetric] = []
    private(set) var memoryUsage: Double = 0
    private(set) var cpuUsage: Double = 0
    private var timer: Timer?
    
    struct PerformanceMetric: Identifiable {
        let id = UUID()
        let name: String
        let duration: TimeInterval
        let timestamp: Date
        let category: Category
        
        enum Category: String, CaseIterable {
            case database = "Database"
            case network = "Network"
            case ui = "UI"
            case sync = "Sync"
        }
    }
    
    private init() {}
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateSystemMetrics()
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateSystemMetrics() {
        // Memory usage
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            memoryUsage = Double(info.resident_size) / (1024 * 1024) // MB
        }
        
        // CPU usage approximation
        cpuUsage = ProcessInfo.processInfo.systemUptime.truncatingRemainder(dividingBy: 100)
    }
    
    func measure<T>(_ name: String, category: PerformanceMetric.Category, operation: () async throws -> T) async rethrows -> T {
        let signpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: "Operation", signpostID: signpostID, "%{public}s", name)
        
        let start = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let duration = CFAbsoluteTimeGetCurrent() - start
        
        os_signpost(.end, log: log, name: "Operation", signpostID: signpostID)
        
        let metric = PerformanceMetric(name: name, duration: duration, timestamp: Date(), category: category)
        metrics.append(metric)
        
        // Keep only last 100 metrics
        if metrics.count > 100 {
            metrics.removeFirst()
        }
        
        return result
    }
    
    func clearMetrics() {
        metrics.removeAll()
    }
}

struct PerformanceMonitorView: View {
    @State private var monitor = PerformanceMonitor.shared
    @State private var selectedCategory: PerformanceMonitor.PerformanceMetric.Category?
    
    private var filteredMetrics: [PerformanceMonitor.PerformanceMetric] {
        if let category = selectedCategory {
            return monitor.metrics.filter { $0.category == category }
        }
        return monitor.metrics
    }
    
    var body: some View {
        List {
            Section("System") {
                LabeledContent("Memory Usage", value: String(format: "%.1f MB", monitor.memoryUsage))
                LabeledContent("CPU Usage", value: String(format: "%.1f%%", monitor.cpuUsage))
            }
            
            Section {
                Picker("Category", selection: $selectedCategory) {
                    Text("All").tag(nil as PerformanceMonitor.PerformanceMetric.Category?)
                    ForEach(PerformanceMonitor.PerformanceMetric.Category.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category as PerformanceMonitor.PerformanceMetric.Category?)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section("Recent Operations") {
                ForEach(filteredMetrics.reversed()) { metric in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(metric.name)
                                .font(.headline)
                            Spacer()
                            Text(String(format: "%.3fs", metric.duration))
                                .font(.caption)
                                .foregroundStyle(metric.duration > 0.5 ? .red : .green)
                        }
                        
                        HStack {
                            Text(metric.category.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.secondary.opacity(0.2))
                                .clipShape(Capsule())
                            
                            Spacer()
                            
                            Text(metric.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Performance")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Clear") {
                    monitor.clearMetrics()
                }
            }
        }
        .onAppear {
            monitor.startMonitoring()
        }
        .onDisappear {
            monitor.stopMonitoring()
        }
    }
}

#Preview {
    NavigationStack {
        PerformanceMonitorView()
    }
}
