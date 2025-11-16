//
//  Exercise.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import Foundation

// MARK: - Exercise Category
enum ExerciseCategory: String, Codable, Sendable, CaseIterable {
    case compound = "compound"
    case olympic = "olympic"
    case bodyweight = "bodyweight"

    var displayName: String {
        return String(localized: String.LocalizationValue("category.\(self.rawValue)"))
    }
}

// MARK: - Exercise Difficulty
enum ExerciseDifficulty: String, Codable, Sendable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"

    var displayName: String {
        return String(localized: String.LocalizationValue("difficulty.\(self.rawValue)"))
    }
}

// MARK: - Exercise Model
struct Exercise: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let nameKey: String // Localization key
    let category: ExerciseCategory
    let difficulty: ExerciseDifficulty
    let icon: String // SF Symbol name

    init(
        id: UUID = UUID(),
        nameKey: String,
        category: ExerciseCategory,
        difficulty: ExerciseDifficulty,
        icon: String
    ) {
        self.id = id
        self.nameKey = nameKey
        self.category = category
        self.difficulty = difficulty
        self.icon = icon
    }
}

// MARK: - Predefined Exercises
extension Exercise {
    static let all: [Exercise] = [
        // Compound Lifts
        .squat,
        .frontSquat,
        .deadlift,
        .romanianDeadlift,
        .benchPress,
        .overheadPress,
        .barbellRow,

        // Olympic Lifts
        .cleanAndJerk,
        .snatch,

        // Bodyweight
        .pushup,
        .pullup
    ]

    // Compound Lifts
    static let squat = Exercise(
        nameKey: "exercise.squat",
        category: .compound,
        difficulty: .intermediate,
        icon: "figure.strengthtraining.traditional"
    )

    static let frontSquat = Exercise(
        nameKey: "exercise.frontSquat",
        category: .compound,
        difficulty: .intermediate,
        icon: "figure.strengthtraining.traditional"
    )

    static let deadlift = Exercise(
        nameKey: "exercise.deadlift",
        category: .compound,
        difficulty: .intermediate,
        icon: "figure.strengthtraining.traditional"
    )

    static let romanianDeadlift = Exercise(
        nameKey: "exercise.romanianDeadlift",
        category: .compound,
        difficulty: .intermediate,
        icon: "figure.strengthtraining.traditional"
    )

    static let benchPress = Exercise(
        nameKey: "exercise.benchPress",
        category: .compound,
        difficulty: .intermediate,
        icon: "figure.strengthtraining.traditional"
    )

    static let overheadPress = Exercise(
        nameKey: "exercise.overheadPress",
        category: .compound,
        difficulty: .intermediate,
        icon: "figure.strengthtraining.traditional"
    )

    static let barbellRow = Exercise(
        nameKey: "exercise.barbellRow",
        category: .compound,
        difficulty: .intermediate,
        icon: "figure.strengthtraining.traditional"
    )

    // Olympic Lifts
    static let cleanAndJerk = Exercise(
        nameKey: "exercise.cleanAndJerk",
        category: .olympic,
        difficulty: .advanced,
        icon: "figure.strengthtraining.functional"
    )

    static let snatch = Exercise(
        nameKey: "exercise.snatch",
        category: .olympic,
        difficulty: .advanced,
        icon: "figure.strengthtraining.functional"
    )

    // Bodyweight
    static let pushup = Exercise(
        nameKey: "exercise.pushup",
        category: .bodyweight,
        difficulty: .beginner,
        icon: "figure.strengthtraining.traditional"
    )

    static let pullup = Exercise(
        nameKey: "exercise.pullup",
        category: .bodyweight,
        difficulty: .intermediate,
        icon: "figure.strengthtraining.traditional"
    )

    // Helper computed properties
    var localizedName: String {
        // String Catalog will automatically localize based on nameKey
        return String(localized: String.LocalizationValue(nameKey))
    }
}

// MARK: - Exercises Grouped by Category
extension Exercise {
    static var groupedByCategory: [ExerciseCategory: [Exercise]] {
        Dictionary(grouping: all, by: { $0.category })
    }
}
