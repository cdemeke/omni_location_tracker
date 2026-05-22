//
//  AppClipView.swift
//  OmniSiteTracker
//
//  App Clip lightweight experience for quick site logging
//

import SwiftUI
import AppClip
import CoreLocation

@MainActor
@Observable
final class AppClipManager {
    static let shared = AppClipManager()
    
    private(set) var invocationURL: URL?
    private(set) var suggestedSite: String?
    private(set) var isAppClip: Bool = false
    
    init() {
        #if APPCLIP
        isAppClip = true
        #endif
    }
    
    func handleInvocation(_ userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL else { return }
        invocationURL = url
        
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            suggestedSite = components.queryItems?.first(where: { $0.name == "site" })?.value
        }
    }
    
    func promptForFullApp() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        
        let config = SKOverlay.AppClipConfiguration(position: .bottom)
        let overlay = SKOverlay(configuration: config)
        overlay.present(in: scene)
    }
}

struct AppClipView: View {
    @State private var manager = AppClipManager.shared
    @State private var selectedSite = "Abdomen - Left"
    @State private var showConfirmation = false
    @State private var isLogging = false
    
    let sites = [
        "Abdomen - Left",
        "Abdomen - Right", 
        "Upper Arm - Left",
        "Upper Arm - Right",
        "Thigh - Left",
        "Thigh - Right",
        "Lower Back - Left",
        "Lower Back - Right"
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                Text("OmniSite Tracker")
                    .font(.title.bold())
                
                Text("Quick Site Log")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)
            
            // Site Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Injection Site")
                    .font(.headline)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(sites, id: \.self) { site in
                        SiteButton(site: site, isSelected: selectedSite == site) {
                            selectedSite = site
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal)
            
            Spacer()
            
            // Log Button
            Button {
                logSite()
            } label: {
                HStack {
                    if isLogging {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text("Log Site")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            .disabled(isLogging)
            .padding(.horizontal)
            
            // Get Full App
            Button {
                manager.promptForFullApp()
            } label: {
                HStack {
                    Image(systemName: "arrow.down.app")
                    Text("Get Full App for More Features")
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
            }
            .padding(.bottom, 24)
        }
        .alert("Site Logged", isPresented: $showConfirmation) {
            Button("OK") {}
            Button("Get Full App") {
                manager.promptForFullApp()
            }
        } message: {
            Text("\(selectedSite) has been logged successfully.")
        }
        .onAppear {
            if let suggested = manager.suggestedSite, sites.contains(suggested) {
                selectedSite = suggested
            }
        }
    }
    
    private func logSite() {
        isLogging = true
        
        // Simulate logging delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLogging = false
            showConfirmation = true
        }
    }
}

struct SiteButton: View {
    let site: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(site)
                .font(.subheadline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .background(isSelected ? Color.blue : Color(.systemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// App Clip Card for location-based invocation
struct AppClipLocationView: View {
    let locationName: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.green)
            
            Text("You're at \(locationName)")
                .font(.headline)
            
            Text("Log your site rotation with one tap")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 8)
    }
}

// Preview for full app showing App Clip features
struct AppClipFeaturesView: View {
    @State private var manager = AppClipManager.shared
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "app.badge")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading) {
                        Text("App Clip")
                            .font(.headline)
                        Text("Lightweight instant experience")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Features") {
                Label("NFC Tag Support", systemImage: "wave.3.right")
                Label("QR Code Scanning", systemImage: "qrcode")
                Label("Location-Based Triggers", systemImage: "location.fill")
                Label("Safari Smart Banner", systemImage: "safari")
                Label("Messages Integration", systemImage: "message")
            }
            
            Section("Invocation URL") {
                if let url = manager.invocationURL {
                    Text(url.absoluteString)
                        .font(.system(.caption, design: .monospaced))
                } else {
                    Text("No invocation URL")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Testing") {
                Link("Test App Clip URL", destination: URL(string: "https://omnitracker.app/clip?site=Abdomen%20-%20Left")!)
            }
        }
        .navigationTitle("App Clip")
    }
}

#Preview("App Clip") {
    AppClipView()
}

#Preview("App Clip Features") {
    NavigationStack {
        AppClipFeaturesView()
    }
}
