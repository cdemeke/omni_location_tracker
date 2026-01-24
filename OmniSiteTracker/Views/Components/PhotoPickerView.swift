//
//  PhotoPickerView.swift
//  OmniSiteTracker
//
//  Photo picker component for documenting pump site placements.
//  Supports both camera capture and photo library selection.
//

import SwiftUI
import PhotosUI
import UIKit

/// A component for selecting or capturing photos for placements
struct PhotoPickerView: View {
    @Binding var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingActionSheet = false
    @State private var photosPickerItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 12) {
            if let image = selectedImage {
                // Show selected image
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Remove button
                    Button {
                        withAnimation {
                            selectedImage = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                    .padding(8)
                }
            } else {
                // Show add photo button
                Button {
                    showingActionSheet = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.title)
                            .foregroundStyle(.appAccent)

                        Text("Add Photo")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.textPrimary)

                        Text("Document your placement site")
                            .font(.caption)
                            .foregroundStyle(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.appAccent.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .confirmationDialog("Add Photo", isPresented: $showingActionSheet) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") {
                    showingCamera = true
                }
            }

            Button("Choose from Library") {
                showingImagePicker = true
            }

            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(image: $selectedImage)
                .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $photosPickerItem, matching: .images)
        .onChange(of: photosPickerItem) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = uiImage
                    }
                }
            }
        }
    }
}

/// Camera capture view using UIImagePickerController
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Placement Photo View

/// Displays a photo attached to a placement
struct PlacementPhotoView: View {
    let placement: PlacementLog
    @State private var showingFullScreen = false
    @State private var loadedImage: UIImage?

    var body: some View {
        Group {
            if let image = loadedImage {
                Button {
                    showingFullScreen = true
                } label: {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .fullScreenCover(isPresented: $showingFullScreen) {
                    FullScreenPhotoView(image: image)
                }
            } else if placement.hasPhoto {
                // Loading placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.cardBackground)
                    .frame(width: 60, height: 60)
                    .overlay {
                        ProgressView()
                    }
            }
        }
        .task {
            if let fileName = placement.photoFileName {
                loadedImage = PhotoManager.shared.loadPhoto(fileName: fileName)
            }
        }
    }
}

/// Full screen photo viewer
struct FullScreenPhotoView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width * scale, height: geometry.size.height * scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1), 4)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                }
                        )
                        .gesture(
                            TapGesture(count: 2)
                                .onEnded {
                                    withAnimation {
                                        scale = scale > 1 ? 1 : 2
                                    }
                                }
                        )
                }
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }

                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: Image(uiImage: image), preview: SharePreview("Placement Photo", image: Image(uiImage: image)))
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        PhotoPickerView(selectedImage: .constant(nil))
            .padding()
    }
    .background(Color.appBackground)
}
