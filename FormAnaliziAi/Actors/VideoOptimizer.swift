//
//  VideoOptimizer.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import Foundation
import AVFoundation
import UIKit

// MARK: - Video Metadata
struct VideoMetadata: Sendable {
    let duration: TimeInterval
    let fileSize: Int64
    let resolution: CGSize
    let frameRate: Float
}

// MARK: - Video Optimizer Actor
actor VideoOptimizer {

    // MARK: - Validate Video
    func validate(url: URL) async throws -> VideoMetadata {
        Configuration.log("Validating video at: \(url.lastPathComponent)", category: .video, level: .debug)

        let asset = AVURLAsset(url: url)

        // Get duration
        let duration = try await asset.load(.duration).seconds

        // Validate duration
        guard duration.isFinite else {
            Configuration.log("Invalid video duration: NaN or Infinity", category: .video, level: .error)
            throw AppError.videoProcessingFailed
        }

        guard duration > 0 else {
            Configuration.log("Invalid video duration: \(duration) (must be positive)", category: .video, level: .error)
            throw AppError.videoProcessingFailed
        }

        // Check for excessively long videos (>1 hour is likely a mistake or too large to process)
        let maxReasonableDuration: TimeInterval = 3600.0 // 1 hour
        if duration > maxReasonableDuration {
            Configuration.log("Video too long: \(duration)s (max reasonable: \(maxReasonableDuration)s)", category: .video, level: .error)
            throw AppError.videoTooLarge
        }

        // Get file size
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0

        // Get video track
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw AppError.videoFormatNotSupported
        }

        // Get resolution
        let naturalSize = try await videoTrack.load(.naturalSize)

        // Get frame rate
        let frameRate = try await videoTrack.load(.nominalFrameRate)

        // Validate constraints
        if duration < Constants.Video.minDuration {
            throw AppError.videoTooShort
        }

        if fileSize > Constants.Video.maxFileSize {
            throw AppError.videoTooLarge
        }

        let metadata = VideoMetadata(
            duration: duration,
            fileSize: fileSize,
            resolution: naturalSize,
            frameRate: frameRate
        )

        Configuration.log("Video validated: \(duration)s, \(fileSize) bytes, \(naturalSize)", category: .video, level: .info)

        return metadata
    }

    // MARK: - Optimize Video
    func optimize(url: URL) async throws -> Data {
        Configuration.log("Starting video optimization", category: .video, level: .debug)

        let asset = AVURLAsset(url: url)

        // Create export session
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPreset1280x720
        ) else {
            throw AppError.videoProcessingFailed
        }

        // Create temporary output URL
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        exportSession.shouldOptimizeForNetworkUse = true

        // Trim to first 30 seconds if needed
        let duration = try await asset.load(.duration)

        // Validate duration
        guard duration.seconds.isFinite, duration.seconds > 0 else {
            Configuration.log("Invalid video duration during optimization", category: .video, level: .error)
            throw AppError.videoProcessingFailed
        }

        if duration.seconds > Constants.Video.maxDuration {
            let endTime = CMTime(seconds: Constants.Video.maxDuration, preferredTimescale: 600)
            exportSession.timeRange = CMTimeRange(start: .zero, end: endTime)
            Configuration.log("Trimming video to \(Constants.Video.maxDuration)s", category: .video, level: .info)
        }

        // Export using iOS 18+ modern API
        do {
            try await exportSession.export(to: outputURL, as: .mp4)

            Configuration.log("Video optimization completed", category: .video, level: .info)

            // Read optimized video data
            let data = try Data(contentsOf: outputURL)

            // Clean up temporary file
            do {
                try FileManager.default.removeItem(at: outputURL)
            } catch {
                // Log but don't fail - cleanup is best effort
                Configuration.log("Failed to cleanup temporary file: \(error.localizedDescription)",
                                category: .video,
                                level: .debug)
            }

            Configuration.log("Optimized video size: \(data.count) bytes", category: .video, level: .debug)
            return data
        } catch {
            Configuration.log("Video optimization failed: \(error.localizedDescription)", category: .video, level: .error)
            throw AppError.videoProcessingFailed
        }
    }

    // MARK: - Generate Thumbnail
    func generateThumbnail(url: URL, atTime time: TimeInterval = 1.0) async throws -> Data {
        Configuration.log("Generating thumbnail at \(time)s", category: .video, level: .debug)

        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero

        let cmTime = CMTime(seconds: time, preferredTimescale: 600)

        do {
            let cgImage = try await imageGenerator.image(at: cmTime).image
            let uiImage = UIImage(cgImage: cgImage)

            guard let jpegData = uiImage.jpegData(compressionQuality: 0.8) else {
                throw AppError.thumbnailGenerationFailed
            }

            Configuration.log("Thumbnail generated: \(jpegData.count) bytes", category: .video, level: .debug)
            return jpegData

        } catch {
            Configuration.log("Thumbnail generation failed: \(error)", category: .video, level: .error)
            throw AppError.thumbnailGenerationFailed
        }
    }
}
