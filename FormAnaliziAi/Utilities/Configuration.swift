//
//  Configuration.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import Foundation
import OSLog

// MARK: - App Configuration
enum Configuration {
    // MARK: - Environment
    enum Environment {
        case development
        case production

        static var current: Environment {
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }

        var isProduction: Bool {
            self == .production
        }

        var isDevelopment: Bool {
            self == .development
        }
    }

    // MARK: - API Configuration
    /// Retrieves Gemini API key from Info.plist
    /// - Returns: API key string
    /// - Throws: AppError.configurationError if key not found
    static func getGeminiAPIKey() throws -> String {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
              !apiKey.isEmpty else {
            log("GEMINI_API_KEY not found or empty in Info.plist",
                category: .general,
                level: .error)
            throw AppError.configurationError("GEMINI_API_KEY not configured in Info.plist")
        }
        return apiKey
    }

    /// Legacy property for backward compatibility - use getGeminiAPIKey() instead
    /// - Warning: This will return empty string if key not configured
    static var geminiAPIKey: String {
        (try? getGeminiAPIKey()) ?? ""
    }

    // MARK: - Feature Flags
    enum FeatureFlags {
        static var enableDebugLogging: Bool {
            Environment.current.isDevelopment
        }

        static var enableMockData: Bool {
            Environment.current.isDevelopment
        }

        static var skipSubscriptionChecks: Bool {
            Environment.current.isDevelopment
        }
    }

    // MARK: - Logging with OSLog
    static func log(
        _ message: String,
        category: LogCategory = .general,
        level: OSLogType = .default
    ) {
        // In production, only log important messages
        if Environment.current.isProduction && level == .debug {
            return
        }

        category.logger.log(level: level, "\(message, privacy: .public)")
    }

    enum LogCategory: String {
        case general = "General"
        case network = "Network"
        case video = "Video"
        case subscription = "Subscription"
        case storage = "Storage"
        case ui = "UI"

        var logger: Logger {
            Logger(subsystem: Constants.App.bundleId, category: self.rawValue)
        }
    }
}
