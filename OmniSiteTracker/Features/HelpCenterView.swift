//
//  HelpCenterView.swift
//  OmniSiteTracker
//
//  In-app help and documentation
//

import SwiftUI

struct HelpArticle: Identifiable {
    let id = UUID()
    let title: String
    let category: String
    let content: String
    let relatedArticles: [String]
}

struct HelpCenterView: View {
    @State private var searchText = ""
    
    private let categories = ["Getting Started", "Features", "Troubleshooting", "Account"]
    
    private let articles: [HelpArticle] = [
        HelpArticle(
            title: "How to Log a Site",
            category: "Getting Started",
            content: "Tap the + button to log a new site placement...",
            relatedArticles: ["Setting Up Reminders", "Site Suggestions"]
        ),
        HelpArticle(
            title: "Understanding Site Suggestions",
            category: "Features",
            content: "The app uses your history to suggest optimal sites...",
            relatedArticles: ["How to Log a Site"]
        ),
        HelpArticle(
            title: "Syncing Issues",
            category: "Troubleshooting",
            content: "If your data isnt syncing, try these steps...",
            relatedArticles: ["iCloud Setup"]
        ),
        HelpArticle(
            title: "Exporting Your Data",
            category: "Account",
            content: "You can export your data in various formats...",
            relatedArticles: ["Privacy Settings"]
        )
    ]
    
    private var filteredArticles: [HelpArticle] {
        if searchText.isEmpty {
            return articles
        }
        return articles.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List {
            Section {
                TextField("Search help articles...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
            
            ForEach(categories, id: \.self) { category in
                let categoryArticles = filteredArticles.filter { $0.category == category }
                
                if !categoryArticles.isEmpty {
                    Section(category) {
                        ForEach(categoryArticles) { article in
                            NavigationLink {
                                ArticleDetailView(article: article)
                            } label: {
                                Text(article.title)
                            }
                        }
                    }
                }
            }
            
            Section("Contact Us") {
                Link(destination: URL(string: "mailto:support@omnisitetracker.com")!) {
                    Label("Email Support", systemImage: "envelope")
                }
                
                NavigationLink {
                    SupportChatView()
                } label: {
                    Label("Live Chat", systemImage: "bubble.left.and.bubble.right")
                }
            }
        }
        .navigationTitle("Help Center")
    }
}

struct ArticleDetailView: View {
    let article: HelpArticle
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(article.title)
                    .font(.title)
                    .bold()
                
                Text(article.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.2))
                    .clipShape(Capsule())
                
                Divider()
                
                Text(article.content)
                
                if !article.relatedArticles.isEmpty {
                    Divider()
                    
                    Text("Related Articles")
                        .font(.headline)
                    
                    ForEach(article.relatedArticles, id: \.self) { related in
                        Text("• \(related)")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        HelpCenterView()
    }
}
