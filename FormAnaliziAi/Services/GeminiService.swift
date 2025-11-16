//
//  GeminiService.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import Foundation
import Observation

// MARK: - Gemini Service
@Observable
@MainActor
class GeminiService {
    // State (only UI state on main thread)
    var isAnalyzing = false
    var isSendingMessage = false
    var error: AppError?

    // Dependencies
    private let apiClient: GeminiAPIClient

    init() {
        // Try to get API key, fallback to empty string (will fail on first API call)
        let apiKey: String
        do {
            apiKey = try Configuration.getGeminiAPIKey()
        } catch {
            Configuration.log("Failed to load API key: \(error)", category: .network, level: .error)
            apiKey = "" // Will cause proper error on API call
        }
        self.apiClient = GeminiAPIClient(apiKey: apiKey)
    }

    // MARK: - Analyze Video
    func analyzeVideo(
        videoData: Data,
        exercise: Exercise,
        language: String = Locale.current.language.languageCode?.identifier ?? "tr"
    ) async throws -> AnalysisResult {
        isAnalyzing = true
        error = nil
        defer {
            isAnalyzing = false
        }

        Configuration.log("Starting analysis for: \(exercise.localizedName)", category: .network, level: .info)

        // Get exercise-specific prompt
        let prompt = buildAnalysisPrompt(for: exercise, language: language)

        // Call API through actor
        let responseText = try await apiClient.analyzeVideo(
            videoData: videoData,
            exerciseName: exercise.localizedName,
            prompt: prompt,
            language: language
        )

        // Parse response
        let result = try parseAnalysisResponse(responseText, exercise: exercise)

        Configuration.log("Analysis completed with score: \(result.score)", category: .network, level: .info)

        return result
    }

    // MARK: - Send Chat Message
    func sendChatMessage(
        message: String,
        session: AnalysisSession,
        language: String = Locale.current.language.languageCode?.identifier ?? "tr"
    ) async throws -> String {
        isSendingMessage = true
        error = nil
        defer {
            isSendingMessage = false
        }

        Configuration.log("Sending chat message", category: .network, level: .info)

        // Build analysis context
        let context = buildAnalysisContext(from: session.analysisResult)

        // Call API through actor
        let response = try await apiClient.sendChatMessage(
            message: message,
            conversationHistory: session.chatHistory,
            analysisContext: context
        )

        Configuration.log("Chat response received", category: .network)

        return response
    }

    // MARK: - Private Helpers

    private func buildAnalysisPrompt(for exercise: Exercise, language: String) -> String {
        // Use exercise-specific prompts from ExercisePrompts
        return ExercisePrompts.getPrompt(for: exercise, language: language)
    }


    private func parseAnalysisResponse(_ text: String, exercise: Exercise) throws -> AnalysisResult {
        Configuration.log("Parsing analysis response", category: .network, level: .debug)
        Configuration.log("Raw response:\n\(text)", category: .network, level: .debug)

        // Extract all components
        var score = extractScore(from: text)
        var feedback = extractFeedback(from: text)
        let correctPoints = extractListItems(
            from: text,
            sectionPatterns: [
                "DOĞRU YAPILAN",
                "CORRECT POINTS",
                "DOĞRU NOKTALAR"
            ]
        )
        let errors = extractListItems(
            from: text,
            sectionPatterns: [
                "HATALAR",
                "DÜZELTİLMESİ GEREKENLER",
                "NEEDS CORRECTION",
                "ERRORS"
            ]
        )
        let suggestions = extractListItems(
            from: text,
            sectionPatterns: [
                "ÖNERİLER",
                "SUGGESTIONS",
                "TAVSİYELER"
            ]
        )

        // Validate and provide defaults if needed
        (score, feedback) = validateAndProvideDefaults(
            score: score,
            feedback: feedback,
            correctPoints: correctPoints,
            from: text
        )

        // Clamp score to valid range
        score = max(0, min(100, score))

        Configuration.log("Parsed - Score: \(score), Feedback: \(feedback.prefix(50))...", category: .network)
        Configuration.log("Correct: \(correctPoints.count), Errors: \(errors.count), Suggestions: \(suggestions.count)", category: .network)

        return AnalysisResult(
            exerciseId: exercise.id,
            exerciseName: exercise.localizedName,
            score: score,
            feedback: feedback.isEmpty ? "Analiz tamamlandı." : feedback,
            correctPoints: correctPoints.isEmpty ? ["Form genel olarak iyi"] : correctPoints,
            errors: errors.isEmpty ? ["Küçük düzeltmeler yapılabilir"] : errors,
            suggestions: suggestions.isEmpty ? ["Düzenli pratik yapın", "Videoyu tekrar gözden geçirin"] : suggestions
        )
    }

    private func extractScore(from text: String) -> Int {
        let scorePatterns = [
            #"\*\*SKOR:\*\*\s*(\d+)"#,  // **SKOR:** 85
            #"SKOR:\s*(\d+)"#,            // SKOR: 85
            #"Score:\s*(\d+)"#,           // Score: 85
            #"Skor:\s*(\d+)"#             // Skor: 85
        ]

        for pattern in scorePatterns {
            if let scoreMatch = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let scoreText = String(text[scoreMatch])
                    .replacingOccurrences(of: "*", with: "")
                    .components(separatedBy: CharacterSet.decimalDigits.inverted)
                    .joined()
                if let parsedScore = Int(scoreText) {
                    return parsedScore
                }
            }
        }

        return 0
    }

    private func extractFeedback(from text: String) -> String {
        let feedbackSectionPatterns = [
            #"\*\*GENEL DEĞERLENDİRME:\*\*"#,
            #"GENEL DEĞERLENDİRME:"#,
            #"Genel Değerlendirme:"#,
            #"\*\*GENERAL ASSESSMENT:\*\*"#,
            #"GENERAL ASSESSMENT:"#
        ]

        for pattern in feedbackSectionPatterns {
            if let sectionRange = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                // Get text after section header
                let afterSection = text[sectionRange.upperBound...]

                // Find where feedback ends (next section or end)
                let endPatterns = [#"\*\*DOĞRU"#, #"DOĞRU YAPILAN"#, #"\*\*HATA"#]
                var endIndex = afterSection.endIndex

                for endPattern in endPatterns {
                    if let endRange = afterSection.range(of: endPattern, options: [.regularExpression, .caseInsensitive]) {
                        endIndex = endRange.lowerBound
                        break
                    }
                }

                // Extract feedback
                let feedback = String(afterSection[..<endIndex])
                    .replacingOccurrences(of: "*", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if !feedback.isEmpty {
                    return feedback
                }
            }
        }

        return ""
    }

    private func validateAndProvideDefaults(
        score: Int,
        feedback: String,
        correctPoints: [String],
        from text: String
    ) -> (score: Int, feedback: String) {
        var validatedScore = score
        var validatedFeedback = feedback

        // If parsing failed, provide defaults
        if validatedScore == 0 && validatedFeedback.isEmpty && correctPoints.isEmpty {
            Configuration.log("⚠️ Parsing failed, providing defaults", category: .network, level: .error)

            // Try to extract ANY number as score
            if let firstNumber = text.range(of: #"\d{1,3}"#, options: .regularExpression) {
                validatedScore = Int(String(text[firstNumber])) ?? 50
            } else {
                validatedScore = 50 // Default score
            }

            validatedFeedback = "Video analizi tamamlandı. Detayları aşağıda görebilirsiniz."
        }

        return (validatedScore, validatedFeedback)
    }

    private func extractListItems(from text: String, sectionPatterns: [String]) -> [String] {
        var sectionRange: Range<String.Index>?
        var matchedPattern = ""

        for basePattern in sectionPatterns {
            // Try to find section with different patterns
            let regexVariations = [
                "\\*\\*\(basePattern):\\*\\*",  // **BAŞLIK:**
                "\(basePattern):",                    // BAŞLIK:
                "\(basePattern.lowercased()):"        // başlık:
            ]

            for regex in regexVariations {
                if let range = text.range(of: regex, options: [.regularExpression, .caseInsensitive]) {
                    sectionRange = range
                    matchedPattern = basePattern
                    break
                }
            }

            if sectionRange != nil { break }
        }

        guard let range = sectionRange else {
            Configuration.log("⚠️ Section not found: \(sectionPatterns.joined(separator: ", "))", category: .network, level: .debug)
            return []
        }

        let afterSection = text[range.upperBound...]
        let lines = afterSection.components(separatedBy: "\n")

        var items: [String] = []
        for line in lines {
            var trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // Remove markdown formatting
            trimmed = trimmed.replacingOccurrences(of: "*", with: "")

            // Check if it's a list item
            if trimmed.hasPrefix("-") || trimmed.hasPrefix("•") || trimmed.hasPrefix("*") {
                let item = trimmed.dropFirst()
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if !item.isEmpty && !item.contains(":**") {
                    items.append(item)
                }
            }
            // Stop at next section (contains : and uppercase)
            else if !trimmed.isEmpty &&
                    (trimmed.contains(":**") ||
                     (trimmed.contains(":") && trimmed.uppercased() == trimmed)) {
                break
            }
        }

        Configuration.log("Extracted \(items.count) items for \(matchedPattern)", category: .network)
        return items
    }

    private func buildAnalysisContext(from result: AnalysisResult) -> String {
        var context = """
        Egzersiz: \(result.exerciseName)
        Skor: \(result.score)/100

        Genel Değerlendirme:
        \(result.feedback)
        """

        if !result.correctPoints.isEmpty {
            context += "\n\nDoğru Yapılan:\n" + result.correctPoints.map { "- \($0)" }.joined(separator: "\n")
        }

        if !result.errors.isEmpty {
            context += "\n\nHatalar:\n" + result.errors.map { "- \($0)" }.joined(separator: "\n")
        }

        if !result.suggestions.isEmpty {
            context += "\n\nÖneriler:\n" + result.suggestions.map { "- \($0)" }.joined(separator: "\n")
        }

        return context
    }

}
