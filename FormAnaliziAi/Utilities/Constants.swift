//
//  Constants.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import Foundation

// MARK: - App Constants
enum Constants {
    // MARK: - App Info
    enum App {
        static let name = "Form Analizi AI"
        static let bundleId = "com.burak.FormAnaliziAi"
        static let version = "1.0.0"
        static let appStoreId = "YOUR_APP_STORE_ID" // Update this when app is published
    }

    // MARK: - Video Processing
    enum Video {
        static let minDuration: TimeInterval = 5.0 // 5 seconds
        static let maxDuration: TimeInterval = 30.0 // 30 seconds
        static let maxRecordingDuration: TimeInterval = 60.0 // 60 seconds max recording
        static let maxFileSize: Int64 = 500 * 1024 * 1024 // 500 MB
        static let targetResolution = CGSize(width: 1280, height: 720) // 720p
        static let targetFrameRate: Int = 30
        static let supportedFormats = ["mov", "mp4", "m4v"]
    }

    // MARK: - Subscription
    enum Subscription {
        static let freeDailyLimit = 3
        static let monthlyProductId = "com.formanalizi.premium.monthly"
        static let yearlyProductId = "com.formanalizi.premium.yearly"
        static let trialDuration = 7 // days
    }

    // MARK: - Gemini API
    enum API {
        static let baseURL = "https://generativelanguage.googleapis.com/v1beta"
        static let model = "gemini-2.5-flash-lite" // Latest optimized model (Dec 2024)
        static let uploadTimeout: TimeInterval = 60.0
        static let requestTimeout: TimeInterval = 120.0
        static let maxRetries = 3

        // Rate Limits (Free Tier - Gemini 2.5)
        static let maxRequestsPerMinute = 20 // Improved limit
        static let maxRequestsPerDay = 2000 // Improved limit
    }

    // MARK: - Storage
    enum Storage {
        static let videosDirectory = "Videos"
        static let resultsDirectory = "Results"
        static let thumbnailsDirectory = "Thumbnails"
    }

    // MARK: - UserDefaults Keys
    enum UserDefaultsKeys {
        static let isPremium = "isPremium"
        static let dailyAnalysisCount = "dailyAnalysisCount"
        static let lastResetDate = "lastResetDate"
        static let selectedLanguage = "selectedLanguage"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    // MARK: - UI
    enum UI {
        // Corner Radius
        static let cornerRadius: CGFloat = 16
        static let smallCornerRadius: CGFloat = 12
        static let largeCornerRadius: CGFloat = 20

        // Padding
        static let cardPadding: CGFloat = 16
        static let horizontalPadding: CGFloat = 32
        static let smallPadding: CGFloat = 12
        static let mediumPadding: CGFloat = 16
        static let largePadding: CGFloat = 24
        static let extraLargePadding: CGFloat = 40

        // Spacing
        static let smallSpacing: CGFloat = 8
        static let mediumSpacing: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        static let largeSpacing: CGFloat = 32
        static let extraLargeSpacing: CGFloat = 40

        // Badge Padding
        static let badgePaddingHorizontal: CGFloat = 12
        static let badgePaddingVertical: CGFloat = 6
        static let smallBadgePaddingHorizontal: CGFloat = 10
        static let smallBadgePaddingVertical: CGFloat = 4

        // Button
        static let buttonHeight: CGFloat = 56
        static let largeButtonHeight: CGFloat = 70

        // Opacity Values
        static let glassOverlay10: CGFloat = 0.1
        static let glassOverlay20: CGFloat = 0.2
        static let glassOverlay30: CGFloat = 0.3

        // Animation
        static let animationDuration: TimeInterval = 0.3
    }

    // MARK: - Timing & Delays
    enum Timing {
        // Timer update intervals
        static let timerUpdateInterval: UInt64 = 100_000_000 // 0.1 seconds in nanoseconds

        // Navigation delays
        static let navigationDelay: UInt64 = 1_000_000_000 // 1 second in nanoseconds

        // API retry delays
        static let rateLimitWaitTime: UInt64 = 60_000_000_000 // 60 seconds in nanoseconds
        static let baseRetryDelay: TimeInterval = 2.0 // Base delay for exponential backoff
    }

    // MARK: - External Links
    enum Links {
        static let privacyPolicy = "https://yourapp.com/privacy"
        static let termsOfService = "https://yourapp.com/terms"
        static let support = "https://yourapp.com/support"
    }
}
