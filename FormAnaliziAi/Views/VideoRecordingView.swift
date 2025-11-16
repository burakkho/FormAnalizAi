//
//  VideoRecordingView.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import SwiftUI
import PhotosUI
import AVKit
import UniformTypeIdentifiers

struct VideoRecordingView: View {
    let exercise: Exercise
    @Binding var navigationPath: NavigationPath
    @Environment(VideoProcessingService.self) private var videoProcessingService

    @State private var viewModel: VideoRecordingViewModel?
    @State private var showImagePicker = false
    @State private var showCamera = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel?.showPreview == true, let videoURL = viewModel?.selectedVideoURL {
                // Video Preview Screen
                VideoPreviewScreen(
                    videoURL: videoURL,
                    exerciseName: exercise.localizedName,
                    onConfirm: {
                        // Navigate to analysis
                        viewModel?.confirmSelection()
                        navigationPath.append(AppRoute.analysis(exercise, videoURL))
                    },
                    onCancel: {
                        // Reset selection
                        viewModel?.cancelSelection()
                    }
                )
            } else {
                // Selection Screen
                VStack(spacing: Constants.UI.largeSpacing) {
                    Spacer()

                    // Exercise Info
                    VStack(spacing: Constants.UI.smallPadding) {
                        Image(systemName: exercise.icon)
                            .font(.iconMedium)
                            .foregroundStyle(.white)

                        Text(exercise.localizedName)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("Video kaydet veya galeriden video seç")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

                    // Action Buttons
                    VStack(spacing: Constants.UI.mediumSpacing) {
                        // Camera Button
                        Button {
                            showCamera = true
                        } label: {
                            HStack(spacing: Constants.UI.smallPadding) {
                                Image(systemName: "video.fill")
                                Text("Kamera ile Kaydet")
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(.primary)

                        // Gallery Button
                        Button {
                            showImagePicker = true
                        } label: {
                            HStack(spacing: Constants.UI.smallPadding) {
                                Image(systemName: "photo.on.rectangle")
                                Text("Galeriden Seç")
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(.secondary)
                    }
                    .padding(.horizontal, Constants.UI.horizontalPadding)

                    Spacer()
                }
            }
        }
        .navigationTitle(exercise.localizedName)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(videoURL: Binding(
                get: { viewModel?.selectedVideoURL },
                set: { if let url = $0 { viewModel?.handleVideoRecorded(at: url) } }
            ))
        }
        .sheet(isPresented: $showImagePicker) {
            if let viewModel = viewModel {
                VideoPicker(viewModel: viewModel, isPresented: $showImagePicker)
            }
        }
        .task {
            // Initialize ViewModel lazily (only once)
            if viewModel == nil {
                viewModel = VideoRecordingViewModel(videoProcessingService: videoProcessingService)
            }
        }
        .onChange(of: viewModel?.showPreview) { oldValue, newValue in
            // Close picker when video is ready for preview
            if newValue == true {
                showImagePicker = false
            }
        }
    }
}

// MARK: - Video Picker (PHPickerViewController wrapper)
struct VideoPicker: UIViewControllerRepresentable {
    let viewModel: VideoRecordingViewModel
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self, viewModel: viewModel)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoPicker
        let viewModel: VideoRecordingViewModel

        init(_ parent: VideoPicker, viewModel: VideoRecordingViewModel) {
            self.parent = parent
            self.viewModel = viewModel
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Only dismiss if user cancelled (no results)
            guard let provider = results.first?.itemProvider else {
                Task { @MainActor in
                    self.parent.isPresented = false
                }
                return
            }

            if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                    guard let url = url else {
                        // Error - close picker
                        Task { @MainActor in
                            self.parent.isPresented = false
                        }
                        return
                    }

                    // IMPORTANT: Must handle video selection synchronously before this handler returns
                    // iOS deletes the temporary file when handler completes
                    // ViewModel handles file copy synchronously, then updates state on main actor
                    // Picker will be closed by onChange handler when showPreview becomes true
                    self.viewModel.handleVideoSelected(from: url)
                }
            } else {
                // Not a video - close picker
                Task { @MainActor in
                    self.parent.isPresented = false
                }
            }
        }
    }
}

// MARK: - Video Preview Screen
struct VideoPreviewScreen: View {
    let videoURL: URL
    let exerciseName: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var player: AVPlayer?

    var body: some View {
        VStack(spacing: 0) {
            // Video Player
            if let player = player {
                VideoPlayer(player: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
            } else {
                Color.black
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Bottom Controls
            VStack(spacing: Constants.UI.mediumSpacing) {
                // Exercise Name
                Text(exerciseName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                // Buttons
                VStack(spacing: Constants.UI.smallPadding) {
                    // Confirm Button
                    Button {
                        onConfirm()
                    } label: {
                        HStack(spacing: Constants.UI.smallPadding) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Analize Başla")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.primary)

                    // Change Button
                    Button {
                        onCancel()
                    } label: {
                        HStack(spacing: Constants.UI.smallPadding) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Değiştir")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.secondary)
                }
                .padding(.horizontal, Constants.UI.horizontalPadding)
            }
            .padding(.vertical, Constants.UI.sectionSpacing)
            .background(
                Color.black.opacity(0.95)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .background(Color.black.ignoresSafeArea())
        .task {
            // Create player asynchronously to avoid blocking UI
            if player == nil {
                await Task.detached(priority: .userInitiated) {
                    let newPlayer = AVPlayer(url: videoURL)
                    await MainActor.run {
                        player = newPlayer
                    }
                }.value
            }
        }
        .onDisappear {
            // Cleanup player when view disappears
            player?.pause()
            player = nil
        }
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()

    NavigationStack(path: $path) {
        VideoRecordingView(
            exercise: .squat,
            navigationPath: $path
        )
    }
}
