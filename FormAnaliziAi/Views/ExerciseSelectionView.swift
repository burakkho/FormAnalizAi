//
//  ExerciseSelectionView.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import SwiftUI

struct ExerciseSelectionView: View {
    @Binding var navigationPath: NavigationPath
    @State private var viewModel = ExerciseSelectionViewModel()

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Constants.UI.sectionSpacing) {
                    // Header
                    VStack(spacing: Constants.UI.smallSpacing) {
                        Text("Egzersiz Seç")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("Analiz etmek istediğiniz egzersizi seçin")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    .padding(.top, Constants.UI.largePadding)

                    // Exercise Categories
                    ForEach(ExerciseCategory.allCases, id: \.self) { category in
                        if let exercises = viewModel.groupedExercises[category] {
                            ExerciseCategorySection(
                                category: category,
                                exercises: exercises,
                                onSelect: { exercise in
                                    viewModel.selectExercise()
                                    navigationPath.append(AppRoute.videoRecording(exercise))
                                }
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Exercise Category Section
struct ExerciseCategorySection: View {
    let category: ExerciseCategory
    let exercises: [Exercise]
    let onSelect: (Exercise) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.UI.mediumSpacing) {
            // Category Header
            Text(category.displayName)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            // Exercise Cards
            VStack(spacing: Constants.UI.smallPadding) {
                ForEach(exercises) { exercise in
                    ExerciseCard(exercise: exercise) {
                        onSelect(exercise)
                    }
                }
            }
        }
    }
}

// MARK: - Exercise Card
struct ExerciseCard: View {
    let exercise: Exercise
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: Constants.UI.mediumSpacing) {
                // Icon
                ZStack {
                    Circle()
                        .fill(difficultyColor.opacity(Constants.UI.glassOverlay20))
                        .frame(width: Constants.UI.buttonHeight, height: Constants.UI.buttonHeight)

                    Image(systemName: exercise.icon)
                        .font(.title2)
                        .foregroundStyle(difficultyColor)
                }

                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.localizedName)
                        .font(.headline)
                        .foregroundStyle(.white)

                    HStack(spacing: Constants.UI.smallSpacing) {
                        // Difficulty badge
                        Badge(
                            text: exercise.difficulty.displayName,
                            color: difficultyColor,
                            size: .small
                        )

                        // Category
                        Text(exercise.category.displayName)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppColors.glassBorder)
            }
            .glassCard(cornerRadius: Constants.UI.cornerRadius)
        }
        .buttonStyle(.plain)
    }

    private var difficultyColor: Color {
        switch exercise.difficulty {
        case .beginner:
            return AppColors.successGreen
        case .intermediate:
            return AppColors.warningOrange
        case .advanced:
            return AppColors.errorRed
        }
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()

    NavigationStack(path: $path) {
        ExerciseSelectionView(navigationPath: $path)
    }
}
