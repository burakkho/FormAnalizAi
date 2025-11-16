//
//  AnalysisResult.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import Foundation
import SwiftUI

// MARK: - Analysis Result Model
struct AnalysisResult: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let exerciseId: UUID
    let exerciseName: String // Stored for display purposes
    let score: Int // 0-100
    let feedback: String // General assessment
    let correctPoints: [String] // Correct technique points
    let errors: [String] // Errors identified
    let suggestions: [String] // Specific recommendations
    let timestamp: Date
    let videoThumbnailPath: String? // Path to thumbnail image
    let videoPath: String? // Path to original video

    init(
        id: UUID = UUID(),
        exerciseId: UUID,
        exerciseName: String,
        score: Int,
        feedback: String,
        correctPoints: [String],
        errors: [String],
        suggestions: [String],
        timestamp: Date = Date(),
        videoThumbnailPath: String? = nil,
        videoPath: String? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.score = score
        self.feedback = feedback
        self.correctPoints = correctPoints
        self.errors = errors
        self.suggestions = suggestions
        self.timestamp = timestamp
        self.videoThumbnailPath = videoThumbnailPath
        self.videoPath = videoPath
    }

    // Score level computed property
    var scoreLevel: ScoreLevel {
        switch score {
        case 0..<50:
            return .poor
        case 50..<70:
            return .needsImprovement
        case 70..<85:
            return .good
        case 85...100:
            return .excellent
        default:
            return .needsImprovement
        }
    }

    var scoreLevelColor: String {
        switch scoreLevel {
        case .poor:
            return "red"
        case .needsImprovement:
            return "orange"
        case .good:
            return "blue"
        case .excellent:
            return "green"
        }
    }

    // SwiftUI Color for score display
    var scoreColor: Color {
        switch score {
        case 0..<50:
            return AppColors.errorRed
        case 50..<70:
            return AppColors.warningOrange
        case 70..<85:
            return AppColors.primaryBlue
        default:
            return AppColors.successGreen
        }
    }
}

// MARK: - Score Level
enum ScoreLevel: String, Codable, Sendable {
    case poor = "poor"
    case needsImprovement = "needsImprovement"
    case good = "good"
    case excellent = "excellent"

    var displayName: String {
        switch self {
        case .poor:
            return "Zayıf"
        case .needsImprovement:
            return "Geliştirilmeli"
        case .good:
            return "İyi"
        case .excellent:
            return "Mükemmel"
        }
    }
}

// MARK: - Mock Data for Previews
extension AnalysisResult {
    static let mock = AnalysisResult(
        exerciseId: Exercise.squat.id,
        exerciseName: "Squat",
        score: 78,
        feedback: "Form genel olarak iyi ancak birkaç düzeltme yapılabilir.",
        correctPoints: [
            "Dizler ayak parmak uçları hizasında",
            "Sırt düz ve nötr pozisyonda",
            "Göğüs dik"
        ],
        errors: [
            "Derinlik yetersiz - tam paralel yapın",
            "Topuklar yerden hafif kalktı"
        ],
        suggestions: [
            "Mobility çalışmaları yapın",
            "Daha ağır yük eklemeden önce formu düzeltin",
            "Topuk altına plaka koyabilirsiniz"
        ]
    )
}
