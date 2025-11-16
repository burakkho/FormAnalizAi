//
//  HomeViewModel.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import Foundation
import Observation

@Observable
@MainActor
class HomeViewModel {
    // Dependencies
    private let subscriptionService: SubscriptionService

    // Published State
    var isPremium: Bool { subscriptionService.isPremium }
    var remainingAnalyses: Int { subscriptionService.getRemainingAnalyses() }
    var dailyLimit: Int { Constants.Subscription.freeDailyLimit }

    // UI State
    var showPaywall = false
    var error: AppError?
    var showError = false

    init(subscriptionService: SubscriptionService) {
        self.subscriptionService = subscriptionService
    }

    // MARK: - Actions
    func canStartAnalysis() -> Bool {
        return subscriptionService.canAnalyze()
    }

    func startAnalysis() -> Bool {
        // Provide haptic feedback
        HapticManager.shared.impact(.medium)

        // Check subscription limit
        if !subscriptionService.canAnalyze() {
            showPaywall = true
            return false
        }
        return true
    }

    func checkSubscriptionLimit() -> Bool {
        if !subscriptionService.canAnalyze() {
            showPaywall = true
            return false
        }
        return true
    }
}
