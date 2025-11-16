//
//  VideoProcessingService.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import Foundation
import Observation

// MARK: - Video Processing Service
@Observable
@MainActor
class VideoProcessingService {
    // State (only UI state on main thread)
    var isProcessing = false
    var processingProgress: Double = 0.0
    var error: AppError?

    // Dependencies
    private let videoOptimizer = VideoOptimizer()

    // MARK: - Copy Video to Temporary Directory
    nonisolated func copyVideoToTempDirectory(from sourceURL: URL) throws -> URL {
        Configuration.log("Copying video to temp directory", category: .video, level: .debug)

        // Create temp file URL
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(sourceURL.pathExtension)

        do {
            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }

            // Copy file
            try FileManager.default.copyItem(at: sourceURL, to: tempURL)

            Configuration.log("Video copied to temp directory: \(tempURL.lastPathComponent)", category: .video, level: .debug)

            return tempURL
        } catch {
            Configuration.log("Failed to copy video: \(error.localizedDescription)", category: .video, level: .error)
            throw AppError.videoProcessingFailed
        }
    }

    // MARK: - Validate Video
    func validateVideo(url: URL) async throws -> VideoMetadata {
        Configuration.log("Validating video: \(url.lastPathComponent)", category: .video)

        do {
            let metadata = try await videoOptimizer.validate(url: url)
            return metadata
        } catch {
            let appError = error as? AppError ?? AppError.videoProcessingFailed
            self.error = appError
            throw appError
        }
    }

    // MARK: - Optimize Video
    func optimizeVideo(url: URL) async throws -> Data {
        isProcessing = true
        processingProgress = 0.0
        error = nil

        defer {
            isProcessing = false
            processingProgress = 0.0
        }

        Configuration.log("Optimizing video: \(url.lastPathComponent)", category: .video)

        do {
            // Simulate progress updates (real progress tracking would require more complex implementation)
            processingProgress = 0.3

            let optimizedData = try await videoOptimizer.optimize(url: url)

            processingProgress = 1.0

            return optimizedData
        } catch {
            let appError = error as? AppError ?? AppError.videoProcessingFailed
            self.error = appError
            throw appError
        }
    }

    // MARK: - Generate Thumbnail
    func generateThumbnail(url: URL, atTime time: TimeInterval = 1.0) async throws -> Data {
        Configuration.log("Generating thumbnail", category: .video)

        do {
            let thumbnailData = try await videoOptimizer.generateThumbnail(url: url, atTime: time)
            return thumbnailData
        } catch {
            let appError = error as? AppError ?? AppError.thumbnailGenerationFailed
            self.error = appError
            throw appError
        }
    }

    // MARK: - Process Complete Video (validate + optimize + thumbnail)
    func processVideo(url: URL) async throws -> (videoData: Data, thumbnailData: Data, metadata: VideoMetadata) {
        isProcessing = true
        processingProgress = 0.0
        error = nil

        defer {
            isProcessing = false
            processingProgress = 0.0
        }

        Configuration.log("Processing complete video pipeline", category: .video)

        do {
            // Step 1: Validate
            processingProgress = 0.1
            let metadata = try await videoOptimizer.validate(url: url)

            // Step 2: Optimize
            processingProgress = 0.3
            let videoData = try await videoOptimizer.optimize(url: url)

            // Step 3: Generate thumbnail
            processingProgress = 0.8
            let thumbnailData = try await videoOptimizer.generateThumbnail(url: url)

            processingProgress = 1.0

            Configuration.log("Video processing completed successfully", category: .video)

            return (videoData, thumbnailData, metadata)
        } catch {
            let appError = error as? AppError ?? AppError.videoProcessingFailed
            self.error = appError
            throw appError
        }
    }
}
