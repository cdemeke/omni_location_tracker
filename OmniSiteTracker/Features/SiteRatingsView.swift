//
//  SiteRatingsView.swift
//  OmniSiteTracker
//
//  Rate and review site experiences
//

import SwiftUI
import SwiftData

@Model
final class SiteRating {
    var id: UUID
    var siteName: String
    var rating: Int
    var comfort: Int
    var healing: Int
    var notes: String?
    var createdAt: Date
    
    init(siteName: String, rating: Int, comfort: Int, healing: Int, notes: String? = nil) {
        self.id = UUID()
        self.siteName = siteName
        self.rating = rating
        self.comfort = comfort
        self.healing = healing
        self.notes = notes
        self.createdAt = Date()
    }
}

struct SiteRatingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SiteRating.createdAt, order: .reverse) private var ratings: [SiteRating]
    @State private var showingAddRating = false
    
    private var siteAverages: [(String, Double)] {
        var siteScores: [String: [Int]] = [:]
        for rating in ratings {
            siteScores[rating.siteName, default: []].append(rating.rating)
        }
        return siteScores.map { site, scores in
            (site, Double(scores.reduce(0, +)) / Double(scores.count))
        }.sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        List {
            Section("Site Rankings") {
                ForEach(siteAverages, id: \.0) { site, average in
                    HStack {
                        Text(site)
                        Spacer()
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= Int(average.rounded()) ? "star.fill" : "star")
                                    .foregroundStyle(.yellow)
                                    .font(.caption)
                            }
                        }
                        Text(String(format: "%.1f", average))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Recent Ratings") {
                ForEach(ratings.prefix(10)) { rating in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(rating.siteName)
                                .font(.headline)
                            Spacer()
                            StarRatingDisplay(rating: rating.rating)
                        }
                        
                        HStack {
                            Label("Comfort: \(rating.comfort)", systemImage: "hand.thumbsup")
                            Spacer()
                            Label("Healing: \(rating.healing)", systemImage: "heart")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        
                        if let notes = rating.notes {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Site Ratings")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddRating = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddRating) {
            AddRatingView()
        }
    }
}

struct StarRatingDisplay: View {
    let rating: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundStyle(.yellow)
            }
        }
    }
}

struct AddRatingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSite = "Left Arm"
    @State private var rating = 3
    @State private var comfort = 3
    @State private var healing = 3
    @State private var notes = ""
    
    private let sites = ["Left Arm", "Right Arm", "Left Thigh", "Right Thigh", "Abdomen Left", "Abdomen Right"]
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Site", selection: $selectedSite) {
                    ForEach(sites, id: \.self) { site in
                        Text(site).tag(site)
                    }
                }
                
                Section("Overall Rating") {
                    StarRatingPicker(rating: $rating)
                }
                
                Section("Details") {
                    Stepper("Comfort: \(comfort)/5", value: $comfort, in: 1...5)
                    Stepper("Healing: \(healing)/5", value: $healing, in: 1...5)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle("Rate Site")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newRating = SiteRating(
                            siteName: selectedSite,
                            rating: rating,
                            comfort: comfort,
                            healing: healing,
                            notes: notes.isEmpty ? nil : notes
                        )
                        modelContext.insert(newRating)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StarRatingPicker: View {
    @Binding var rating: Int
    
    var body: some View {
        HStack {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundStyle(.yellow)
                    .font(.title)
                    .onTapGesture {
                        rating = star
                    }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        SiteRatingsView()
    }
    .modelContainer(for: SiteRating.self, inMemory: true)
}
