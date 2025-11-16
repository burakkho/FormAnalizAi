//
//  AnalysisLoadingView.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import SwiftUI

struct AnalysisLoadingView: View {
    let exercise: Exercise
    let videoURL: URL
    @Binding var navigationPath: NavigationPath

    @Environment(VideoProcessingService.self) private var videoProcessingService
    @Environment(GeminiService.self) private var geminiService
    @Environment(StorageService.self) private var storageService
    @Environment(SubscriptionService.self) private var subscriptionService

    @State private var viewModel: AnalysisViewModel?
    @State private var didStartAnalysis = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.1), lineWidth: 8)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: viewModel?.progress ?? 0.0)
                        .stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: viewModel?.progress)

                    if viewModel?.currentStep == .completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 50))
                            .foregroundStyle(.white)
                    } else {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                    }
                }

                // Status Text
                VStack(spacing: 12) {
                    Text(viewModel?.currentStep.rawValue ?? "")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text("\(Int((viewModel?.progress ?? 0.0) * 100))%")
                        .font(.headline)
                        .foregroundStyle(.gray)
                }

                Spacer()
            }
        }
        .navigationTitle("Analiz Ediliyor")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .task {
            if viewModel == nil {
                viewModel = AnalysisViewModel(
                    videoProcessingService: videoProcessingService,
                    geminiService: geminiService,
                    storageService: storageService,
                    subscriptionService: subscriptionService
                )
            }

            guard !didStartAnalysis else { return }
            didStartAnalysis = true

            await viewModel?.analyzeVideo(exercise: exercise, videoURL: videoURL)

            // Navigate to result after completion
            if let session = viewModel?.analysisSession {
                try? await Task.sleep(nanoseconds: Constants.Timing.navigationDelay)
                navigationPath.append(AppRoute.analysisResult(session))
            }
        }
        .alert("Hata", isPresented: Binding(
            get: { viewModel?.showError ?? false },
            set: { if !$0, viewModel != nil { viewModel?.showError = false } }
        )) {
            Button("Tamam") {
                navigationPath.removeLast()
            }
        } message: {
            if let error = viewModel?.error {
                VStack(spacing: 8) {
                    Text(error.errorDescription ?? "Bilinmeyen hata")

                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AnalysisLoadingView(
            exercise: .squat,
            videoURL: URL(fileURLWithPath: "/tmp/test.mp4"),
            navigationPath: .constant(NavigationPath())
        )
        .environment(VideoProcessingService())
        .environment(GeminiService())
        .environment(StorageService())
        .environment(SubscriptionService())
    }
}
