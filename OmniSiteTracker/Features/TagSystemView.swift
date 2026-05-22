//
//  TagSystemView.swift
//  OmniSiteTracker
//
//  Custom tagging for logs
//

import SwiftUI
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var color: String
    var createdAt: Date
    
    init(name: String, color: String = "blue") {
        self.id = UUID()
        self.name = name
        self.color = color
        self.createdAt = Date()
    }
}

struct TagSystemView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tags: [Tag]
    @State private var newTagName = ""
    @State private var selectedColor = "blue"
    
    private let colors = ["blue", "green", "orange", "purple", "pink", "red"]
    
    var body: some View {
        List {
            Section("Create Tag") {
                TextField("Tag name", text: $newTagName)
                
                HStack {
                    ForEach(colors, id: \.self) { color in
                        Circle()
                            .fill(colorFor(color))
                            .frame(width: 30, height: 30)
                            .overlay {
                                if selectedColor == color {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.white)
                                        .font(.caption)
                                }
                            }
                            .onTapGesture { selectedColor = color }
                    }
                }
                
                Button("Add Tag") {
                    let tag = Tag(name: newTagName, color: selectedColor)
                    modelContext.insert(tag)
                    newTagName = ""
                }
                .disabled(newTagName.isEmpty)
            }
            
            Section("Your Tags") {
                ForEach(tags) { tag in
                    HStack {
                        Circle()
                            .fill(colorFor(tag.color))
                            .frame(width: 12, height: 12)
                        Text(tag.name)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(tags[index])
                    }
                }
            }
        }
        .navigationTitle("Tags")
    }
    
    private func colorFor(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        default: return .blue
        }
    }
}

#Preview {
    NavigationStack {
        TagSystemView()
    }
    .modelContainer(for: Tag.self, inMemory: true)
}
