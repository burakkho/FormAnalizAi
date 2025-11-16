//
//  AnalysisSession.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import Foundation

// MARK: - Analysis Session Model
struct AnalysisSession: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let exerciseId: UUID
    let exerciseName: String
    var analysisResult: AnalysisResult
    var chatHistory: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        exerciseId: UUID,
        exerciseName: String,
        analysisResult: AnalysisResult,
        chatHistory: [ChatMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.analysisResult = analysisResult
        self.chatHistory = chatHistory
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Add chat message to session
    mutating func addChatMessage(_ message: ChatMessage) {
        chatHistory.append(message)
        updatedAt = Date()
    }

    // Computed properties
    var hasChatHistory: Bool {
        !chatHistory.isEmpty
    }

    var lastChatMessage: ChatMessage? {
        chatHistory.last
    }
}

// MARK: - Mock Data
extension AnalysisSession {
    static let mock = AnalysisSession(
        exerciseId: Exercise.squat.id,
        exerciseName: "Squat",
        analysisResult: .mock,
        chatHistory: ChatMessage.mockMessages
    )

    static let mockWithoutChat = AnalysisSession(
        exerciseId: Exercise.deadlift.id,
        exerciseName: "Deadlift",
        analysisResult: AnalysisResult(
            exerciseId: Exercise.deadlift.id,
            exerciseName: "Deadlift",
            score: 85,
            feedback: "Harika form! Sadece küçük iyileştirmeler yapılabilir.",
            correctPoints: [
                "Sırt düz",
                "Bar bacağa yakın",
                "Kalça ve omuz aynı anda yükseliyor"
            ],
            errors: [],
            suggestions: [
                "Kafa pozisyonu biraz daha nötr olabilir"
            ]
        ),
        chatHistory: []
    )
}
