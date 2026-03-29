//
//  SearchFiltersView.swift
//  OmniSiteTracker
//
//  Advanced search and filtering capabilities
//

import SwiftUI
import SwiftData

struct SearchFilter {
    var searchText = ""
    var dateRange: DateRange = .all
    var sites: Set<String> = []
    var hasSymptoms: Bool? = nil
    var hasPhotos: Bool? = nil
    
    enum DateRange: String, CaseIterable {
        case all = "All Time"
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case year = "This Year"
        case custom = "Custom"
    }
}

struct SearchFiltersView: View {
    @Query private var placements: [PlacementLog]
    @State private var filter = SearchFilter()
    @State private var showingFilters = false
    
    private var allSites: [String] {
        Array(Set(placements.map { $0.site })).sorted()
    }
    
    private var filteredPlacements: [PlacementLog] {
        placements.filter { placement in
            if !filter.searchText.isEmpty {
                let searchLower = filter.searchText.lowercased()
                guard placement.site.lowercased().contains(searchLower) ||
                      (placement.notes?.lowercased().contains(searchLower) ?? false) else {
                    return false
                }
            }
            
            if !filter.sites.isEmpty {
                guard filter.sites.contains(placement.site) else {
                    return false
                }
            }
            
            if let hasPhotos = filter.hasPhotos {
                if hasPhotos && placement.photoFileName == nil { return false }
                if !hasPhotos && placement.photoFileName != nil { return false }
            }
            
            return true
        }
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search sites, notes...", text: $filter.searchText)
                }
                
                Button {
                    showingFilters = true
                } label: {
                    HStack {
                        Text("Filters")
                        Spacer()
                        if hasActiveFilters {
                            Text("\(activeFilterCount)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            
            Section("Results (\(filteredPlacements.count))") {
                ForEach(filteredPlacements) { placement in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(placement.site)
                                .font(.headline)
                            Spacer()
                            Text(placement.placedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let notes = placement.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Search")
        .sheet(isPresented: $showingFilters) {
            FilterOptionsView(filter: $filter, allSites: allSites)
        }
    }
    
    private var hasActiveFilters: Bool {
        filter.dateRange != .all || !filter.sites.isEmpty || filter.hasSymptoms != nil || filter.hasPhotos != nil
    }
    
    private var activeFilterCount: Int {
        var count = 0
        if filter.dateRange != .all { count += 1 }
        if !filter.sites.isEmpty { count += 1 }
        if filter.hasSymptoms != nil { count += 1 }
        if filter.hasPhotos != nil { count += 1 }
        return count
    }
}

struct FilterOptionsView: View {
    @Binding var filter: SearchFilter
    let allSites: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Date Range") {
                    ForEach(SearchFilter.DateRange.allCases, id: \.self) { range in
                        Button {
                            filter.dateRange = range
                        } label: {
                            HStack {
                                Text(range.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if filter.dateRange == range {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Sites") {
                    ForEach(allSites, id: \.self) { site in
                        Button {
                            if filter.sites.contains(site) {
                                filter.sites.remove(site)
                            } else {
                                filter.sites.insert(site)
                            }
                        } label: {
                            HStack {
                                Text(site)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if filter.sites.contains(site) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button("Clear All Filters", role: .destructive) {
                        filter = SearchFilter()
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SearchFiltersView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
