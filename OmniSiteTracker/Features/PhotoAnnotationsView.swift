//
//  PhotoAnnotationsView.swift
//  OmniSiteTracker
//
//  Add annotations to site photos
//

import SwiftUI

struct Annotation: Identifiable {
    let id = UUID()
    var position: CGPoint
    var text: String
    var color: Color
}

struct PhotoAnnotationsView: View {
    @State private var annotations: [Annotation] = []
    @State private var selectedAnnotation: Annotation?
    @State private var isAddingAnnotation = false
    @State private var newAnnotationText = ""
    @State private var selectedColor: Color = .red
    
    private let colors: [Color] = [.red, .blue, .green, .orange, .purple]
    
    var body: some View {
        VStack(spacing: 0) {
            // Image area with annotations
            GeometryReader { geometry in
                ZStack {
                    Rectangle()
                        .fill(.secondary.opacity(0.2))
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                        }
                    
                    ForEach(annotations) { annotation in
                        AnnotationMarker(annotation: annotation)
                            .position(annotation.position)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    if isAddingAnnotation {
                        let annotation = Annotation(position: location, text: newAnnotationText, color: selectedColor)
                        annotations.append(annotation)
                        isAddingAnnotation = false
                        newAnnotationText = ""
                    }
                }
            }
            .frame(height: 300)
            
            Divider()
            
            // Controls
            List {
                Section {
                    if isAddingAnnotation {
                        TextField("Annotation text", text: $newAnnotationText)
                        
                        HStack {
                            Text("Color")
                            Spacer()
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 24, height: 24)
                                    .overlay {
                                        if selectedColor == color {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.white)
                                                .font(.caption)
                                        }
                                    }
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                        
                        Text("Tap on the image to place annotation")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Button {
                            isAddingAnnotation = true
                        } label: {
                            Label("Add Annotation", systemImage: "plus.circle")
                        }
                    }
                }
                
                Section("Annotations (\(annotations.count))") {
                    ForEach(annotations) { annotation in
                        HStack {
                            Circle()
                                .fill(annotation.color)
                                .frame(width: 12, height: 12)
                            Text(annotation.text)
                        }
                    }
                    .onDelete { indexSet in
                        annotations.remove(atOffsets: indexSet)
                    }
                }
            }
        }
        .navigationTitle("Annotations")
    }
}

struct AnnotationMarker: View {
    let annotation: Annotation
    
    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(annotation.color)
                .frame(width: 20, height: 20)
                .overlay {
                    Circle()
                        .stroke(.white, lineWidth: 2)
                }
            
            if !annotation.text.isEmpty {
                Text(annotation.text)
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(annotation.color.opacity(0.8))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }
}

#Preview {
    NavigationStack {
        PhotoAnnotationsView()
    }
}
