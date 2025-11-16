//
//  CameraViewModel.swift
//  FormAnaliziAi
//
//  Created by Claude Code
//

import Foundation
import Observation

@Observable
@MainActor
class CameraViewModel {
    // Recording State
    private(set) var recordingDuration: TimeInterval = 0
    private(set) var isRecording = false
    private(set) var maxDurationReached = false
    private var recordingTask: Task<Void, Never>?

    // Configuration
    let maxRecordingDuration: TimeInterval = Constants.Video.maxRecordingDuration

    // Computed property for timer display
    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Actions
    func startRecording() {
        guard !isRecording else { return }

        isRecording = true
        recordingDuration = 0
        maxDurationReached = false

        // Start async timer using Task.sleep
        recordingTask = Task { @MainActor in
            while isRecording {
                try? await Task.sleep(nanoseconds: Constants.Timing.timerUpdateInterval)

                guard !Task.isCancelled else { break }

                recordingDuration += 0.1

                // Auto-stop at max duration
                if recordingDuration >= maxRecordingDuration {
                    maxDurationReached = true
                    break
                }
            }
        }
    }

    func stopRecording() {
        recordingTask?.cancel()
        recordingTask = nil
        isRecording = false
    }

    func reset() {
        stopRecording()
        recordingDuration = 0
        maxDurationReached = false
    }
}
