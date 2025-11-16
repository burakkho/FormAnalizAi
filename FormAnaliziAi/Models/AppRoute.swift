//
//  AppRoute.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import Foundation

// MARK: - App Navigation Routes
enum AppRoute: Hashable, Sendable {
    case exerciseSelection
    case videoRecording(Exercise)
    case analysis(Exercise, URL) // Exercise + video URL
    case analysisResult(AnalysisSession)
    case chat(AnalysisSession)
    case history
    case paywall
    case settings
}
