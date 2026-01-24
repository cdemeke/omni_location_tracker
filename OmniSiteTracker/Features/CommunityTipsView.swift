//
//  CommunityTipsView.swift
//  OmniSiteTracker
//
//  Community-sourced tips and best practices
//

import SwiftUI
import SwiftData

@Model
final class CommunityTip {
    var id: UUID
    var title: String
    var content: String
    var authorName: String
    var category: String
    var upvotes: Int
    var createdAt: Date
    var isVerified: Bool
    
    init(title: String, content: String, authorName: String, category: String) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.authorName = authorName
        self.category = category
        self.upvotes = 0
        self.createdAt = Date()
        self.isVerified = false
    }
}

struct CommunityTipsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CommunityTip.upvotes, order: .reverse) private var tips: [CommunityTip]
    @State private var selectedCategory = "All"
    @State private var showingAddTip = false
    
    private let categories = ["All", "Site Selection", "Rotation", "Comfort", "Healing", "Equipment"]
    
    private var filteredTips: [CommunityTip] {
        if selectedCategory == "All" {
            return tips
        }
        return tips.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Text(category)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategory == category ? .blue : .secondary.opacity(0.2))
                                    .foregroundStyle(selectedCategory == category ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .listRowInsets(EdgeInsets())
            
            Section("Tips from the Community") {
                ForEach(filteredTips) { tip in
                    TipCard(tip: tip)
                }
            }
        }
        .navigationTitle("Community Tips")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddTip = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTip) {
            AddTipView()
        }
    }
}

struct TipCard: View {
    @Environment(\.modelContext) private var modelContext
    let tip: CommunityTip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(tip.title)
                    .font(.headline)
                
                if tip.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.blue)
                }
                
                Spacer()
                
                Text(tip.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            Text(tip.content)
                .font(.body)
                .foregroundStyle(.secondary)
            
            HStack {
                Text("by \(tip.authorName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    tip.upvotes += 1
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle")
                        Text("\(tip.upvotes)")
                    }
                    .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddTipView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var content = ""
    @State private var authorName = ""
    @State private var category = "Site Selection"
    
    private let categories = ["Site Selection", "Rotation", "Comfort", "Healing", "Equipment"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tip Details") {
                    TextField("Title", text: $title)
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                    TextField("Your Name", text: $authorName)
                }
                
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
            }
            .navigationTitle("Add Tip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        let tip = CommunityTip(
                            title: title,
                            content: content,
                            authorName: authorName,
                            category: category
                        )
                        modelContext.insert(tip)
                        dismiss()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CommunityTipsView()
    }
    .modelContainer(for: CommunityTip.self, inMemory: true)
}
