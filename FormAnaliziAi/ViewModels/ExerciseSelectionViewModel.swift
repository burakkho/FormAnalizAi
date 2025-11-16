//
//  ExerciseSelectionViewModel.swift
//  FormAnaliziAi
//
//  Created by Claude Code
//

import Foundation
import Observation

@Observable
@MainActor
class ExerciseSelectionViewModel {
    // Published State
    let groupedExercises: [ExerciseCategory: [Exercise]]

    init() {
        self.groupedExercises = Exercise.groupedByCategory
    }

    // MARK: - Actions
    func selectExercise() {
        // Provide haptic feedback
        HapticManager.shared.selection()
    }
}
