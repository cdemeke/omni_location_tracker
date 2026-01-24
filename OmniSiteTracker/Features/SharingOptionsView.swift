//
//  SharingOptionsView.swift
//  OmniSiteTracker
//
//  Enhanced sharing capabilities
//

import SwiftUI

enum ShareDestination: String, CaseIterable {
    case messages = "Messages"
    case email = "Email"
    case airdrop = "AirDrop"
    case healthApp = "Health App"
    case clipboard = "Clipboard"
    case files = "Files"
    
    var icon: String {
        switch self {
        case .messages: return "message.fill"
        case .email: return "envelope.fill"
        case .airdrop: return "antenna.radiowaves.left.and.right"
        case .healthApp: return "heart.fill"
        case .clipboard: return "doc.on.clipboard"
        case .files: return "folder.fill"
        }
    }
}

struct SharingOptionsView: View {
    @State private var selectedRange: DateRange = .week
    @State private var includeCharts = true
    @State private var includePhotos = false
    @State private var isSharing = false
    
    enum DateRange: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
        case all = "All Time"
    }
    
    var body: some View {
        List {
            Section("Data Range") {
                Picker("Range", selection: $selectedRange) {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section("Options") {
                Toggle("Include Charts", isOn: $includeCharts)
                Toggle("Include Photos", isOn: $includePhotos)
            }
            
            Section("Share To") {
                ForEach(ShareDestination.allCases, id: \.self) { destination in
                    Button {
                        shareToDestination(destination)
                    } label: {
                        Label(destination.rawValue, systemImage: destination.icon)
                    }
                }
            }
        }
        .navigationTitle("Share Data")
        .overlay {
            if isSharing {
                ProgressView("Preparing...")
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func shareToDestination(_ destination: ShareDestination) {
        isSharing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSharing = false
            // Trigger share sheet or specific action
        }
    }
}

#Preview {
    NavigationStack {
        SharingOptionsView()
    }
}
