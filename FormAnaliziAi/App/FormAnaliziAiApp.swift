//
//  FormAnaliziAiApp.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import SwiftUI

@main
struct FormAnaliziAiApp: App {
    // Services - @Observable injected via .environment()
    @State private var geminiService = GeminiService()
    @State private var videoProcessingService = VideoProcessingService()
    @State private var storageService = StorageService()
    @State private var subscriptionService = SubscriptionService()

    // Onboarding State
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main App
                HomeView()
                    .environment(geminiService)
                    .environment(videoProcessingService)
                    .environment(storageService)
                    .environment(subscriptionService)

                // Onboarding Overlay
                if !hasCompletedOnboarding {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
        }
    }
}
