//
//  TestFlightFeedbackView.swift
//  OmniSiteTracker
//
//  In-app feedback collection for TestFlight builds
//

import SwiftUI
import StoreKit

struct FeedbackEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let type: FeedbackType
    let title: String
    let description: String
    let rating: Int?
    var isSubmitted: Bool
    
    enum FeedbackType: String, Codable, CaseIterable {
        case bug = "Bug Report"
        case feature = "Feature Request"
        case improvement = "Improvement"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .bug: return "ladybug"
            case .feature: return "star"
            case .improvement: return "arrow.up.circle"
            case .other: return "ellipsis.circle"
            }
        }
    }
}

@MainActor
@Observable
final class FeedbackManager {
    static let shared = FeedbackManager()
    
    private(set) var feedbackEntries: [FeedbackEntry] = []
    private(set) var isSubmitting = false
    
    var isTestFlightBuild: Bool {
        guard let path = Bundle.main.appStoreReceiptURL?.path else { return false }
        return path.contains("sandboxReceipt")
    }
    
    private let storageKey = "feedback_entries"
    
    init() {
        loadEntries()
    }
    
    func submitFeedback(type: FeedbackEntry.FeedbackType, title: String, description: String, rating: Int?) async {
        let entry = FeedbackEntry(
            id: UUID(),
            date: Date(),
            type: type,
            title: title,
            description: description,
            rating: rating,
            isSubmitted: false
        )
        
        feedbackEntries.append(entry)
        saveEntries()
        
        isSubmitting = true
        // Simulate network submission
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        if let index = feedbackEntries.firstIndex(where: { $0.id == entry.id }) {
            feedbackEntries[index].isSubmitted = true
            saveEntries()
        }
        isSubmitting = false
    }
    
    func deleteFeedback(_ entry: FeedbackEntry) {
        feedbackEntries.removeAll { $0.id == entry.id }
        saveEntries()
    }
    
    func requestAppStoreReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([FeedbackEntry].self, from: data) {
            feedbackEntries = decoded
        }
    }
    
    private func saveEntries() {
        if let data = try? JSONEncoder().encode(feedbackEntries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

struct TestFlightFeedbackView: View {
    @State private var manager = FeedbackManager.shared
    @State private var showFeedbackForm = false
    
    var body: some View {
        List {
            if manager.isTestFlightBuild {
                Section {
                    HStack {
                        Image(systemName: "airplane.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text("TestFlight Build")
                                .font(.headline)
                            Text("Thank you for beta testing!")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section {
                Button {
                    showFeedbackForm = true
                } label: {
                    Label("Submit Feedback", systemImage: "square.and.pencil")
                }
                
                Button {
                    manager.requestAppStoreReview()
                } label: {
                    Label("Rate on App Store", systemImage: "star.fill")
                }
            }
            
            Section("Previous Feedback") {
                if manager.feedbackEntries.isEmpty {
                    Text("No feedback submitted yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(manager.feedbackEntries.reversed()) { entry in
                        FeedbackEntryRow(entry: entry)
                    }
                    .onDelete { indexSet in
                        let reversed = manager.feedbackEntries.reversed()
                        for index in indexSet {
                            let entry = Array(reversed)[index]
                            manager.deleteFeedback(entry)
                        }
                    }
                }
            }
        }
        .navigationTitle("Feedback")
        .sheet(isPresented: $showFeedbackForm) {
            FeedbackFormView(manager: manager)
        }
    }
}

struct FeedbackEntryRow: View {
    let entry: FeedbackEntry
    
    var body: some View {
        HStack {
            Image(systemName: entry.type.icon)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading) {
                Text(entry.title)
                    .font(.headline)
                HStack {
                    Text(entry.type.rawValue)
                    Text("•")
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if entry.isSubmitted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.orange)
            }
        }
    }
}

struct FeedbackFormView: View {
    let manager: FeedbackManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var feedbackType: FeedbackEntry.FeedbackType = .bug
    @State private var title = ""
    @State private var description = ""
    @State private var rating: Int = 3
    @State private var includeRating = false
    
    var isValid: Bool {
        !title.isEmpty && !description.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Feedback Type", selection: $feedbackType) {
                        ForEach(FeedbackEntry.FeedbackType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Details") {
                    TextField("Title", text: $title)
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Toggle("Include Rating", isOn: $includeRating)
                    
                    if includeRating {
                        HStack {
                            Text("Rating")
                            Spacer()
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    rating = star
                                } label: {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .foregroundStyle(star <= rating ? .yellow : .gray)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Submit Feedback") {
                        Task {
                            await manager.submitFeedback(
                                type: feedbackType,
                                title: title,
                                description: description,
                                rating: includeRating ? rating : nil
                            )
                            dismiss()
                        }
                    }
                    .disabled(!isValid || manager.isSubmitting)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("New Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if manager.isSubmitting {
                    ProgressView("Submitting...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TestFlightFeedbackView()
    }
}
