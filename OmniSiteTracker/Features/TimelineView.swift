//
//  TimelineView.swift
//  OmniSiteTracker
//
//  Visual timeline of site history
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    @Query(sort: \PlacementLog.placedAt, order: .reverse) private var placements: [PlacementLog]
    @State private var selectedMonth = Date()
    
    private var groupedByDate: [Date: [PlacementLog]] {
        Dictionary(grouping: placements) { placement in
            Calendar.current.startOfDay(for: placement.placedAt)
        }
    }
    
    private var sortedDates: [Date] {
        groupedByDate.keys.sorted(by: >)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(sortedDates, id: \.self) { date in
                    TimelineDateSection(date: date, placements: groupedByDate[date] ?? [])
                }
            }
            .padding()
        }
        .navigationTitle("Timeline")
    }
}

struct TimelineDateSection: View {
    let date: Date
    let placements: [PlacementLog]
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Date column
            VStack {
                Text(date.formatted(.dateTime.day()))
                    .font(.title2.bold())
                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 50)
            
            // Timeline line
            VStack(spacing: 0) {
                Circle()
                    .fill(.blue)
                    .frame(width: 12, height: 12)
                
                Rectangle()
                    .fill(.secondary.opacity(0.3))
                    .frame(width: 2)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                ForEach(placements) { placement in
                    TimelineCard(placement: placement)
                }
            }
            .padding(.bottom, 24)
        }
    }
}

struct TimelineCard: View {
    let placement: PlacementLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(placement.site)
                    .font(.headline)
                
                Spacer()
                
                Text(placement.placedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let notes = placement.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if placement.photoFileName != nil {
                HStack {
                    Image(systemName: "photo")
                    Text("Photo attached")
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        TimelineView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
