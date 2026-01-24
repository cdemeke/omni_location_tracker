//
//  CrashReporterView.swift
//  OmniSiteTracker
//
//  Crash reporting and diagnostics
//

import SwiftUI

struct CrashReport: Identifiable, Codable {
    let id: UUID
    let date: Date
    let type: String
    let message: String
    let stackTrace: String
    let deviceInfo: DeviceInfo
    var isSubmitted: Bool
    
    struct DeviceInfo: Codable {
        let model: String
        let osVersion: String
        let appVersion: String
        let locale: String
        let memoryUsage: Double
    }
}

@MainActor
@Observable
final class CrashReporter {
    static let shared = CrashReporter()
    
    private(set) var reports: [CrashReport] = []
    private(set) var isSubmitting = false
    
    private let reportsKey = "crash_reports"
    
    init() {
        loadReports()
        setupExceptionHandler()
    }
    
    private func setupExceptionHandler() {
        NSSetUncaughtExceptionHandler { exception in
            Task { @MainActor in
                CrashReporter.shared.recordCrash(exception: exception)
            }
        }
    }
    
    func recordCrash(exception: NSException) {
        let report = CrashReport(
            id: UUID(),
            date: Date(),
            type: exception.name.rawValue,
            message: exception.reason ?? "Unknown",
            stackTrace: exception.callStackSymbols.joined(separator: "\n"),
            deviceInfo: getCurrentDeviceInfo(),
            isSubmitted: false
        )
        reports.append(report)
        saveReports()
    }
    
    func recordError(_ error: Error, context: String = "") {
        let report = CrashReport(
            id: UUID(),
            date: Date(),
            type: "Error",
            message: "\(context): \(error.localizedDescription)",
            stackTrace: Thread.callStackSymbols.joined(separator: "\n"),
            deviceInfo: getCurrentDeviceInfo(),
            isSubmitted: false
        )
        reports.append(report)
        saveReports()
    }
    
    func submitReport(_ report: CrashReport) async {
        isSubmitting = true
        // Simulate network submission
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        if let index = reports.firstIndex(where: { $0.id == report.id }) {
            reports[index].isSubmitted = true
            saveReports()
        }
        isSubmitting = false
    }
    
    func submitAllReports() async {
        for report in reports where !report.isSubmitted {
            await submitReport(report)
        }
    }
    
    func deleteReport(_ report: CrashReport) {
        reports.removeAll { $0.id == report.id }
        saveReports()
    }
    
    func clearAllReports() {
        reports.removeAll()
        saveReports()
    }
    
    private func getCurrentDeviceInfo() -> CrashReport.DeviceInfo {
        CrashReport.DeviceInfo(
            model: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            locale: Locale.current.identifier,
            memoryUsage: getMemoryUsage()
        )
    }
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Double(info.resident_size) / 1024 / 1024 : 0
    }
    
    private func loadReports() {
        if let data = UserDefaults.standard.data(forKey: reportsKey),
           let decoded = try? JSONDecoder().decode([CrashReport].self, from: data) {
            reports = decoded
        }
    }
    
    private func saveReports() {
        if let data = try? JSONEncoder().encode(reports) {
            UserDefaults.standard.set(data, forKey: reportsKey)
        }
    }
}

struct CrashReporterView: View {
    @State private var reporter = CrashReporter.shared
    @State private var showClearAlert = false
    
    var unsubmittedCount: Int {
        reporter.reports.filter { !$0.isSubmitted }.count
    }
    
    var body: some View {
        List {
            if !reporter.reports.isEmpty {
                Section {
                    if unsubmittedCount > 0 {
                        Button("Submit All Reports (\(unsubmittedCount))") {
                            Task {
                                await reporter.submitAllReports()
                            }
                        }
                        .disabled(reporter.isSubmitting)
                    }
                }
                
                Section("Reports") {
                    ForEach(reporter.reports) { report in
                        CrashReportRow(report: report, reporter: reporter)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            reporter.deleteReport(reporter.reports[index])
                        }
                    }
                }
                
                Section {
                    Button("Clear All Reports", role: .destructive) {
                        showClearAlert = true
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Crash Reports",
                    systemImage: "checkmark.shield",
                    description: Text("No crashes have been recorded")
                )
            }
        }
        .navigationTitle("Crash Reports")
        .overlay {
            if reporter.isSubmitting {
                ProgressView("Submitting...")
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
            }
        }
        .alert("Clear Reports", isPresented: $showClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                reporter.clearAllReports()
            }
        } message: {
            Text("This will delete all crash reports.")
        }
    }
}

struct CrashReportRow: View {
    let report: CrashReport
    let reporter: CrashReporter
    @State private var showDetail = false
    
    var body: some View {
        Button {
            showDetail = true
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(report.type)
                        .font(.headline)
                    Text(report.date.formatted())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if report.isSubmitted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            CrashReportDetailView(report: report, reporter: reporter)
        }
    }
}

struct CrashReportDetailView: View {
    let report: CrashReport
    let reporter: CrashReporter
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Details") {
                    LabeledContent("Type", value: report.type)
                    LabeledContent("Date", value: report.date.formatted())
                    LabeledContent("Status", value: report.isSubmitted ? "Submitted" : "Pending")
                }
                
                Section("Message") {
                    Text(report.message)
                        .font(.system(.body, design: .monospaced))
                }
                
                Section("Device Info") {
                    LabeledContent("Model", value: report.deviceInfo.model)
                    LabeledContent("OS Version", value: report.deviceInfo.osVersion)
                    LabeledContent("App Version", value: report.deviceInfo.appVersion)
                    LabeledContent("Memory", value: String(format: "%.1f MB", report.deviceInfo.memoryUsage))
                }
                
                Section("Stack Trace") {
                    Text(report.stackTrace)
                        .font(.system(.caption, design: .monospaced))
                }
                
                if !report.isSubmitted {
                    Section {
                        Button("Submit Report") {
                            Task {
                                await reporter.submitReport(report)
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Crash Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CrashReporterView()
    }
}
