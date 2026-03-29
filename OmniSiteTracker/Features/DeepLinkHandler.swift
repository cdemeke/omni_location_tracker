//
//  DeepLinkHandler.swift
//  OmniSiteTracker
//
//  Universal links and deep link handling
//

import SwiftUI

enum DeepLink: Equatable {
    case home
    case logSite
    case history
    case settings
    case siteDetail(siteId: String)
    case profile(profileId: String)
    case export
    case reminder
    case unknown(String)
    
    init(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            self = .unknown(url.absoluteString)
            return
        }
        
        let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let queryItems = components.queryItems ?? []
        
        switch path {
        case "", "home":
            self = .home
        case "log", "logsite":
            self = .logSite
        case "history":
            self = .history
        case "settings":
            self = .settings
        case "site":
            if let siteId = queryItems.first(where: { $0.name == "id" })?.value {
                self = .siteDetail(siteId: siteId)
            } else {
                self = .unknown(url.absoluteString)
            }
        case "profile":
            if let profileId = queryItems.first(where: { $0.name == "id" })?.value {
                self = .profile(profileId: profileId)
            } else {
                self = .unknown(url.absoluteString)
            }
        case "export":
            self = .export
        case "reminder":
            self = .reminder
        default:
            self = .unknown(url.absoluteString)
        }
    }
    
    var displayName: String {
        switch self {
        case .home: return "Home"
        case .logSite: return "Log Site"
        case .history: return "History"
        case .settings: return "Settings"
        case .siteDetail: return "Site Detail"
        case .profile: return "Profile"
        case .export: return "Export"
        case .reminder: return "Reminder"
        case .unknown(let path): return "Unknown: \(path)"
        }
    }
}

@MainActor
@Observable
final class DeepLinkHandler {
    static let shared = DeepLinkHandler()
    
    private(set) var currentLink: DeepLink?
    private(set) var linkHistory: [DeepLink] = []
    private(set) var pendingLink: DeepLink?
    
    var hasUnhandledLink: Bool {
        pendingLink != nil
    }
    
    func handle(_ url: URL) {
        let link = DeepLink(url: url)
        pendingLink = link
        linkHistory.append(link)
    }
    
    func handleUniversalLink(_ userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return
        }
        handle(url)
    }
    
    func consumePendingLink() -> DeepLink? {
        let link = pendingLink
        pendingLink = nil
        currentLink = link
        return link
    }
    
    func clearHistory() {
        linkHistory.removeAll()
    }
    
    // Generate shareable URLs
    static func createURL(for link: DeepLink) -> URL? {
        let baseURL = "omnitracker://"
        
        var urlString: String
        switch link {
        case .home:
            urlString = baseURL + "home"
        case .logSite:
            urlString = baseURL + "logsite"
        case .history:
            urlString = baseURL + "history"
        case .settings:
            urlString = baseURL + "settings"
        case .siteDetail(let siteId):
            urlString = baseURL + "site?id=\(siteId)"
        case .profile(let profileId):
            urlString = baseURL + "profile?id=\(profileId)"
        case .export:
            urlString = baseURL + "export"
        case .reminder:
            urlString = baseURL + "reminder"
        case .unknown:
            return nil
        }
        
        return URL(string: urlString)
    }
}

struct DeepLinkDebugView: View {
    @State private var handler = DeepLinkHandler.shared
    @State private var testURL = ""
    
    var body: some View {
        List {
            Section("Test Deep Link") {
                TextField("URL (e.g., omnitracker://history)", text: $testURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                Button("Test Link") {
                    if let url = URL(string: testURL) {
                        handler.handle(url)
                    }
                }
                .disabled(testURL.isEmpty)
            }
            
            Section("Pending Link") {
                if let pending = handler.pendingLink {
                    Text(pending.displayName)
                        .foregroundStyle(.orange)
                } else {
                    Text("None")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Current Link") {
                if let current = handler.currentLink {
                    Text(current.displayName)
                } else {
                    Text("None")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Supported Links") {
                ForEach(supportedLinks, id: \.0) { name, url in
                    Button {
                        testURL = url
                    } label: {
                        VStack(alignment: .leading) {
                            Text(name)
                                .font(.headline)
                            Text(url)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Section("Link History") {
                if handler.linkHistory.isEmpty {
                    Text("No links handled")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(handler.linkHistory.indices, id: \.self) { index in
                        Text(handler.linkHistory[index].displayName)
                    }
                    
                    Button("Clear History", role: .destructive) {
                        handler.clearHistory()
                    }
                }
            }
        }
        .navigationTitle("Deep Links")
    }
    
    var supportedLinks: [(String, String)] {
        [
            ("Home", "omnitracker://home"),
            ("Log Site", "omnitracker://logsite"),
            ("History", "omnitracker://history"),
            ("Settings", "omnitracker://settings"),
            ("Site Detail", "omnitracker://site?id=123"),
            ("Profile", "omnitracker://profile?id=456"),
            ("Export", "omnitracker://export"),
            ("Reminder", "omnitracker://reminder")
        ]
    }
}

// View modifier for handling deep links
struct DeepLinkNavigationModifier: ViewModifier {
    @State private var handler = DeepLinkHandler.shared
    let onLink: (DeepLink) -> Void
    
    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                handler.handle(url)
            }
            .onChange(of: handler.pendingLink) { _, newValue in
                if let link = handler.consumePendingLink() {
                    onLink(link)
                }
            }
    }
}

extension View {
    func handleDeepLinks(_ handler: @escaping (DeepLink) -> Void) -> some View {
        modifier(DeepLinkNavigationModifier(onLink: handler))
    }
}

#Preview {
    NavigationStack {
        DeepLinkDebugView()
    }
}
