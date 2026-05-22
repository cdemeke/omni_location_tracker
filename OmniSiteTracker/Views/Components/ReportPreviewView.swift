//
//  ReportPreviewView.swift
//  OmniSiteTracker
//
//  UI for generating and previewing medical reports.
//  Allows users to configure report parameters and share with healthcare providers.
//

import SwiftUI
import SwiftData
import PDFKit

/// View for configuring and generating medical reports
struct ReportConfigurationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PlacementLog.placedAt, order: .reverse) private var placements: [PlacementLog]

    @State private var patientName: String = ""
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -3, to: .now) ?? .now
    @State private var endDate: Date = .now
    @State private var isGenerating = false
    @State private var generatedPDF: Data?
    @State private var showingPreview = false
    @State private var showingShareSheet = false
    @State private var errorMessage: String?

    private let reportGenerator = MedicalReportGenerator()

    var body: some View {
        NavigationStack {
            Form {
                // Patient Information
                Section {
                    TextField("Patient Name (Optional)", text: $patientName)
                } header: {
                    Text("Patient Information")
                } footer: {
                    Text("Leave blank to exclude from report")
                }

                // Date Range
                Section("Report Period") {
                    DatePicker("Start Date", selection: $startDate, in: ...endDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }

                // Report Summary
                Section("Report Preview") {
                    let filteredCount = placements.filter { $0.placedAt >= startDate && $0.placedAt <= endDate }.count

                    LabeledContent("Placements in Range", value: "\(filteredCount)")

                    if filteredCount == 0 {
                        Text("No placements found in the selected date range")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }

                // Generate Button
                Section {
                    Button {
                        generateReport()
                    } label: {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(isGenerating ? "Generating..." : "Generate Report")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isGenerating || placements.filter { $0.placedAt >= startDate && $0.placedAt <= endDate }.isEmpty)
                }

                // Error Message
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Medical Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPreview) {
                if let pdfData = generatedPDF {
                    ReportPreviewSheet(pdfData: pdfData, patientName: patientName, onShare: {
                        showingPreview = false
                        showingShareSheet = true
                    })
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let pdfData = generatedPDF {
                    let filename = generateFilename()
                    ReportShareSheet(data: pdfData, filename: filename)
                }
            }
        }
    }

    private func generateReport() {
        isGenerating = true
        errorMessage = nil

        Task {
            let settings = UserSettings.getOrCreate(context: modelContext)

            if let pdfData = await reportGenerator.generateReport(
                placements: placements,
                settings: settings,
                patientName: patientName.isEmpty ? nil : patientName,
                startDate: startDate,
                endDate: endDate
            ) {
                generatedPDF = pdfData
                showingPreview = true
            } else {
                errorMessage = "Failed to generate report. Please try again."
            }

            isGenerating = false
        }
    }

    private func generateFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: .now)
        let nameComponent = patientName.isEmpty ? "" : "_\(patientName.replacingOccurrences(of: " ", with: "_"))"
        return "PumpSiteReport\(nameComponent)_\(dateStr).pdf"
    }
}

/// Preview sheet for the generated PDF
struct ReportPreviewSheet: View {
    let pdfData: Data
    let patientName: String
    let onShare: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PDFPreviewView(data: pdfData)
                .navigationTitle("Report Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            onShare()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
        }
    }
}

/// PDF preview using PDFKit
struct PDFPreviewView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        if let document = PDFDocument(data: data) {
            pdfView.document = document
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = PDFDocument(data: data) {
            uiView.document = document
        }
    }
}

// MARK: - Settings Integration

/// Button for accessing medical reports from Settings
struct MedicalReportButton: View {
    @State private var showingReportConfig = false

    var body: some View {
        Button {
            showingReportConfig = true
        } label: {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.appAccent)

                Text("Generate Medical Report")
                    .foregroundColor(.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .sheet(isPresented: $showingReportConfig) {
            ReportConfigurationView()
        }
    }
}

// MARK: - Preview

#Preview {
    ReportConfigurationView()
        .modelContainer(for: PlacementLog.self, inMemory: true)
}
