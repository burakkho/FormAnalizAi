//
//  HomeView.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import SwiftUI

struct HomeView: View {
    @Environment(SubscriptionService.self) private var subscriptionService
    @State private var navigationPath = NavigationPath()
    @State private var viewModel: HomeViewModel?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // App Logo
                    Image("image-logo")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(height: 360)

                    // Main Action Button
                    Button {
                        startAnalysis()
                    } label: {
                        HStack(spacing: Constants.UI.smallPadding) {
                            Image(systemName: "video.fill")
                                .font(.title3)
                            Text("Yeni Analiz")
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.primary)
                    .padding(.horizontal, Constants.UI.horizontalPadding)
                    .padding(.top, Constants.UI.mediumSpacing)
                    .bounceAnimation()

                    // Secondary Actions
                    HStack(spacing: Constants.UI.mediumSpacing) {
                        NavigationButton(
                            icon: "clock.fill",
                            title: "Geçmiş",
                            action: {
                                navigationPath.append(AppRoute.history)
                            }
                        )

                        NavigationButton(
                            icon: "gearshape.fill",
                            title: "Ayarlar",
                            action: {
                                navigationPath.append(AppRoute.settings)
                            }
                        )
                    }
                    .padding(.horizontal, Constants.UI.horizontalPadding)
                    .padding(.top, Constants.UI.mediumSpacing)

                    Spacer()

                    // Daily limit indicator
                    if let viewModel = viewModel {
                        if !viewModel.isPremium {
                            HStack(spacing: Constants.UI.smallPadding) {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundStyle(AppColors.primaryBlue)
                                    .font(.title3)

                                Text("\(viewModel.remainingAnalyses)/\(viewModel.dailyLimit) analiz kaldı")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, Constants.UI.largePadding)
                            .padding(.vertical, Constants.UI.smallPadding + 2)
                            .vibrantGlass(tint: AppColors.primaryBlue, cornerRadius: Constants.UI.cornerRadius)
                            .padding(.bottom, Constants.UI.extraLargePadding)
                        } else {
                            HStack(spacing: Constants.UI.smallSpacing) {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.title3)

                                Text("Premium Üye")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, Constants.UI.largePadding)
                            .padding(.vertical, Constants.UI.smallPadding + 2)
                            .vibrantGlass(tint: .yellow, cornerRadius: Constants.UI.cornerRadius)
                            .padding(.bottom, Constants.UI.extraLargePadding)
                        }
                    }
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route)
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.showPaywall ?? false },
                set: { if !$0 { viewModel?.showPaywall = false } }
            )) {
                PaywallView()
            }
            .task {
                // Initialize ViewModel lazily (only once)
                if viewModel == nil {
                    viewModel = HomeViewModel(subscriptionService: subscriptionService)
                }
            }
        }
    }

    // MARK: - Actions
    private func startAnalysis() {
        guard let viewModel = viewModel else { return }

        // Check subscription limit and trigger haptic feedback via ViewModel
        if !viewModel.startAnalysis() {
            return
        }

        // Navigate to exercise selection
        navigationPath.append(AppRoute.exerciseSelection)
    }

    // MARK: - Navigation Destinations
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .exerciseSelection:
            ExerciseSelectionView(navigationPath: $navigationPath)

        case .videoRecording(let exercise):
            VideoRecordingView(exercise: exercise, navigationPath: $navigationPath)

        case .analysis(let exercise, let videoURL):
            AnalysisLoadingView(exercise: exercise, videoURL: videoURL, navigationPath: $navigationPath)

        case .analysisResult(let session):
            AnalysisResultView(session: session, navigationPath: $navigationPath)

        case .chat(let session):
            ChatView(session: session)

        case .history:
            HistoryView(navigationPath: $navigationPath)

        case .paywall:
            PaywallView()

        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Navigation Button Component
struct NavigationButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Constants.UI.smallSpacing) {
                Image(systemName: icon)
                    .font(.title2)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: Constants.UI.largeButtonHeight + 15)
            .liquidGlass(cornerRadius: Constants.UI.cornerRadius)
        }
    }
}


#Preview {
    HomeView()
        .environment(SubscriptionService())
}
