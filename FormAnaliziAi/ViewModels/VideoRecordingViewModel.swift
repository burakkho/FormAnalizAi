//
//  VideoRecordingViewModel.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import Foundation
import Observation

@Observable
@MainActor
class VideoRecordingViewModel {
    // Dependencies
    private let videoProcessingService: VideoProcessingService

    // Published State
    var selectedVideoURL: URL?
    var showPreview: Bool = false
    var error: AppError?

    init(videoProcessingService: VideoProcessingService) {
        self.videoProcessingService = videoProcessingService
    }

    // MARK: - Video Selection from Gallery
    nonisolated func handleVideoSelected(from sourceURL: URL) {
        Configuration.log("Handling video selection", category: .video, level: .debug)

        do {
            // Copy video to temp directory (synchronous operation - must happen before handler returns)
            let tempURL = try videoProcessingService.copyVideoToTempDirectory(from: sourceURL)

            // Update state on main actor
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.selectedVideoURL = tempURL
                self.showPreview = true
                Configuration.log("Video selected successfully: \(tempURL.lastPathComponent)", category: .video, level: .info)
            }
        } catch {
            Configuration.log("Failed to handle video selection: \(error)", category: .video, level: .error)
            Task { @MainActor [weak self] in
                self?.error = .videoProcessingFailed
            }
        }
    }

    // MARK: - Video Recording from Camera
    func handleVideoRecorded(at url: URL) {
        Configuration.log("Handling recorded video", category: .video, level: .debug)

        // Camera already saves to temp directory, just update state
        selectedVideoURL = url
        showPreview = true

        Configuration.log("Recorded video ready: \(url.lastPathComponent)", category: .video, level: .info)
    }

    // MARK: - Preview Actions
    func cancelSelection() {
        selectedVideoURL = nil
        showPreview = false
        Configuration.log("Video selection cancelled", category: .video, level: .debug)
    }

    func confirmSelection() {
        // Selection confirmed, navigate to analysis
        // Navigation handled by View
        Configuration.log("Video selection confirmed", category: .video, level: .debug)
    }
}
