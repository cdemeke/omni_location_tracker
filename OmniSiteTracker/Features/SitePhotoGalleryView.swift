//
//  SitePhotoGalleryView.swift
//  OmniSiteTracker
//
//  Photo gallery organized by site
//

import SwiftUI
import SwiftData

struct SitePhotoGalleryView: View {
    @Query private var placements: [PlacementLog]
    @State private var selectedSite: String?
    
    private var sites: [String] {
        Array(Set(placements.map { $0.site })).sorted()
    }
    
    private var photosForSite: [PlacementLog] {
        placements.filter { 
            $0.site == (selectedSite ?? "") && $0.photoFileName != nil 
        }
    }
    
    var body: some View {
        List {
            Section("Sites") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(sites, id: \.self) { site in
                            Button {
                                selectedSite = site
                            } label: {
                                Text(site)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedSite == site ? .blue : .secondary.opacity(0.2))
                                    .foregroundStyle(selectedSite == site ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .listRowInsets(EdgeInsets())
            
            if let site = selectedSite {
                Section("\(site) Photos") {
                    if photosForSite.isEmpty {
                        Text("No photos for this site")
                            .foregroundStyle(.secondary)
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(photosForSite) { placement in
                                PhotoThumbnail(placement: placement)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Photo Gallery")
    }
}

struct PhotoThumbnail: View {
    let placement: PlacementLog
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.secondary.opacity(0.3))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                VStack {
                    Image(systemName: "photo")
                        .font(.title)
                    Text(placement.placedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
    }
}

#Preview {
    NavigationStack {
        SitePhotoGalleryView()
    }
    .modelContainer(for: PlacementLog.self, inMemory: true)
}
