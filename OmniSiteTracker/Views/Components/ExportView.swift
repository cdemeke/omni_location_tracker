//
//  ExportView.swift
//  OmniSiteTracker
//
//  UI for exporting and importing placement data.
//  Provides format selection, date range filtering, and sharing.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// View for exporting placement data
struct ExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \PlacementLog.placedAt, order: .reverse) private var allPlacements: [PlacementLog]

    @State private var selectedFormat: DataExporter.ExportFormat = .csv
    @State private var selectedRange: DataExporter.DateRange = .allTime
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var customEndDate: Date = .now
    @State private var includeNotes: Bool = true
    @State private var includeMetadata: Bool = false

    @State private var isExporting: Bool = false
    @State private var exportResult: DataExporter.ExportResult?
    @State private var showingShareSheet: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""

    private var filteredPlacements: [PlacementLog] {
        let startDate: Date?
        let endDate: Date = .now

        if selectedRange == .custom {
            startDate = customStartDate
        } else {
            startDate = selectedRange.startDate
        }

        return allPlacements.filter { placement in
            if let start = startDate {
                return placement.placedAt >= start && placement.placedAt <= endDate
            }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Export Format Section
                Section {
                    ForEach(DataExporter.ExportFormat.allCases) { format in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(format.rawValue)
                                    .font(.body)
                                Text(format.description)
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }

                            Spacer()

                            if selectedFormat == format {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.appAccent)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedFormat = format
                        }
                    }
                } header: {
                    Text("Export Format")
                }

                // Date Range Section
                Section {
                    ForEach(DataExporter.DateRange.allCases) { range in
                        HStack {
                            Text(range.rawValue)

                            Spacer()

                            if selectedRange == range {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.appAccent)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedRange = range
                        }
                    }

                    if selectedRange == .custom {
                        DatePicker(
                            "Start Date",
                            selection: $customStartDate,
                            displayedComponents: .date
                        )

                        DatePicker(
                            "End Date",
                            selection: $customEndDate,
                            displayedComponents: .date
                        )
                    }
                } header: {
                    Text("Date Range")
                } footer: {
                    Text("\(filteredPlacements.count) placements will be exported")
                }

                // Options Section
                Section {
                    Toggle("Include Notes", isOn: $includeNotes)

                    if selectedFormat == .json {
                        Toggle("Include Metadata", isOn: $includeMetadata)
                    }
                } header: {
                    Text("Options")
                }

                // Export Button
                Section {
                    Button(action: performExport) {
                        HStack {
                            Spacer()

                            if isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }

                            Text(isExporting ? "Exporting..." : "Export Data")
                                .fontWeight(.semibold)

                            Spacer()
                        }
                    }
                    .disabled(isExporting || filteredPlacements.isEmpty)
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let result = exportResult, let url = result.url {
                    ShareSheet(items: [url])
                }
            }
            .alert("Export Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func performExport() {
        isExporting = true

        Task {
            do {
                let result = try DataExporter.export(
                    placements: filteredPlacements,
                    format: selectedFormat,
                    includeNotes: includeNotes,
                    includeMetadata: includeMetadata
                )

                await MainActor.run {
                    exportResult = result
                    isExporting = false
                    showingShareSheet = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isExporting = false
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Import View

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isImporting: Bool = false
    @State private var showingFilePicker: Bool = false
    @State private var importedCount: Int = 0
    @State private var showingResult: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 60))
                    .foregroundColor(.appAccent)

                // Title
                Text("Import Placement Data")
                    .font(.title2)
                    .fontWeight(.bold)

                // Description
                Text("Import placements from a JSON backup file. Duplicate entries will be skipped.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                // Import Button
                Button(action: { showingFilePicker = true }) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Select File")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appAccent)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .disabled(isImporting)
            }
            .padding()
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .alert("Import Complete", isPresented: $showingResult) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Successfully imported \(importedCount) placements.")
            }
            .alert("Import Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            isImporting = true

            Task {
                do {
                    // Get access to the file
                    guard url.startAccessingSecurityScopedResource() else {
                        throw ExportError.importFailed("Cannot access file")
                    }
                    defer { url.stopAccessingSecurityScopedResource() }

                    let data = try Data(contentsOf: url)
                    let count = try await MainActor.run {
                        try DataExporter.importFromJSON(data: data, modelContext: modelContext)
                    }

                    await MainActor.run {
                        importedCount = count
                        isImporting = false
                        showingResult = true
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        isImporting = false
                        showingError = true
                    }
                }
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Export/Import Settings Section

struct DataManagementSection: View {
    @State private var showingExport = false
    @State private var showingImport = false

    var body: some View {
        Section {
            Button(action: { showingExport = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.appAccent)
                    Text("Export Data")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .foregroundColor(.textPrimary)

            Button(action: { showingImport = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.appAccent)
                    Text("Import Data")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .foregroundColor(.textPrimary)
        } header: {
            Text("Data Management")
        } footer: {
            Text("Export your placement history to backup or share with healthcare providers.")
        }
        .sheet(isPresented: $showingExport) {
            ExportView()
        }
        .sheet(isPresented: $showingImport) {
            ImportView()
        }
    }
}

// MARK: - Preview

#Preview {
    ExportView()
}
