//
//  AnalysisViewModel.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import Foundation
import Observation

enum AnalysisStep: String {
    case validating = "Video doğrulanıyor..."
    case processing = "Video optimize ediliyor..."
    case analyzing = "AI analiz yapıyor..."
    case saving = "Sonuçlar kaydediliyor..."
    case completed = "Tamamlandı!"
}

@Observable
@MainActor
class AnalysisViewModel {
    // Dependencies
    private let videoProcessingService: VideoProcessingService
    private let geminiService: GeminiService
    private let storageService: StorageService
    private let subscriptionService: SubscriptionService

    // Published State (UI state on main thread)
    var currentStep: AnalysisStep = .validating
    var progress: Double = 0.0
    var error: AppError?
    var showError = false
    var analysisSession: AnalysisSession?
    var isAnalyzing = false

    init(
        videoProcessingService: VideoProcessingService,
        geminiService: GeminiService,
        storageService: StorageService,
        subscriptionService: SubscriptionService
    ) {
        self.videoProcessingService = videoProcessingService
        self.geminiService = geminiService
        self.storageService = storageService
        self.subscriptionService = subscriptionService
    }

    // MARK: - Analysis Flow
    func analyzeVideo(exercise: Exercise, videoURL: URL) async {
        isAnalyzing = true
        defer {
            isAnalyzing = false
        }

        do {
            // Step 1: Validate & Process Video
            currentStep = .validating
            progress = 0.1

            let (videoData, thumbnailData, metadata) = try await videoProcessingService.processVideo(url: videoURL)

            Configuration.log("Video processed: \(metadata.duration)s, \(videoData.count) bytes", category: .video, level: .info)

            // Step 2: Analyze with Gemini
            currentStep = .analyzing
            progress = 0.5

            let analysisResult = try await geminiService.analyzeVideo(
                videoData: videoData,
                exercise: exercise
            )

            Configuration.log("Analysis completed: score \(analysisResult.score)", category: .network, level: .info)

            // Step 3: Save everything
            currentStep = .saving
            progress = 0.8

            // Save video
            let videoSavedURL = try await storageService.saveVideo(videoData, id: analysisResult.id)

            // Save thumbnail
            let thumbnailSavedURL = try await storageService.saveThumbnail(thumbnailData, id: analysisResult.id)

            // Update analysis result with paths
            let updatedResult = AnalysisResult(
                id: analysisResult.id,
                exerciseId: analysisResult.exerciseId,
                exerciseName: analysisResult.exerciseName,
                score: analysisResult.score,
                feedback: analysisResult.feedback,
                correctPoints: analysisResult.correctPoints,
                errors: analysisResult.errors,
                suggestions: analysisResult.suggestions,
                timestamp: analysisResult.timestamp,
                videoThumbnailPath: thumbnailSavedURL.path,
                videoPath: videoSavedURL.path
            )

            // Create session
            let session = AnalysisSession(
                exerciseId: exercise.id,
                exerciseName: exercise.localizedName,
                analysisResult: updatedResult
            )

            // Save session
            try await storageService.saveSession(session)

            // Increment daily count
            subscriptionService.incrementDailyCount()

            // Step 4: Complete
            currentStep = .completed
            progress = 1.0

            // Success haptic
            HapticManager.shared.notification(.success)

            analysisSession = session

        } catch let appError as AppError {
            error = appError
            showError = true
            HapticManager.shared.notification(.error)
        } catch {
            self.error = .unknown(error.localizedDescription)
            showError = true
            HapticManager.shared.notification(.error)
        }
    }
}
