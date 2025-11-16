//
//  GeminiAPIClient.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import Foundation

// MARK: - Gemini API Response Models
struct GeminiResponse: Codable, Sendable {
    let candidates: [Candidate]?
    let error: GeminiError?

    struct Candidate: Codable, Sendable {
        let content: Content

        struct Content: Codable, Sendable {
            let parts: [Part]

            struct Part: Codable, Sendable {
                let text: String?
            }
        }
    }

    struct GeminiError: Codable, Sendable {
        let code: Int
        let message: String
        let status: String
    }
}

// MARK: - Gemini API Request Models
struct GeminiRequest: Codable, Sendable {
    let contents: [Content]

    struct Content: Codable, Sendable {
        let parts: [Part]

        struct Part: Codable, Sendable {
            let text: String?
            let inlineData: InlineData?

            struct InlineData: Codable, Sendable {
                let mimeType: String
                let data: String // base64 encoded
            }
        }
    }
}

// MARK: - Gemini API Client Actor
actor GeminiAPIClient {
    private let apiKey: String
    private let urlSession: URLSession

    init(apiKey: String) {
        self.apiKey = apiKey

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.API.uploadTimeout
        config.timeoutIntervalForResource = Constants.API.requestTimeout
        config.httpMaximumConnectionsPerHost = 1
        self.urlSession = URLSession(configuration: config)
    }

    // MARK: - Analyze Video
    func analyzeVideo(
        videoData: Data,
        exerciseName: String,
        prompt: String,
        language: String
    ) async throws -> String {
        Configuration.log("Starting video analysis for: \(exerciseName)", category: .network)

        // Convert video to base64 on background queue (CPU-intensive for large videos)
        let base64Video = await Task.detached(priority: .userInitiated) {
            Configuration.log("Encoding video to base64 (\(videoData.count) bytes)...", category: .network)
            let encoded = videoData.base64EncodedString()
            Configuration.log("Base64 encoding completed", category: .network)
            return encoded
        }.value

        // Build request
        let request = GeminiRequest(
            contents: [
                GeminiRequest.Content(
                    parts: [
                        GeminiRequest.Content.Part(
                            text: prompt,
                            inlineData: nil
                        ),
                        GeminiRequest.Content.Part(
                            text: nil,
                            inlineData: GeminiRequest.Content.Part.InlineData(
                                mimeType: "video/mp4",
                                data: base64Video
                            )
                        )
                    ]
                )
            ]
        )

        // Send request with retry logic
        return try await sendRequestWithRetry(request: request)
    }

    // MARK: - Send Chat Message
    func sendChatMessage(
        message: String,
        conversationHistory: [ChatMessage],
        analysisContext: String
    ) async throws -> String {
        Configuration.log("Sending chat message", category: .network)

        // Build conversation context
        var promptParts: [String] = []

        // Add analysis context
        promptParts.append("Analiz Bağlamı:\n\(analysisContext)\n")

        // Add conversation history
        if !conversationHistory.isEmpty {
            promptParts.append("Geçmiş Konuşma:")
            for msg in conversationHistory {
                let role = msg.role == .user ? "Kullanıcı" : "Asistan"
                promptParts.append("\(role): \(msg.content)")
            }
        }

        // Add current message
        promptParts.append("\nKullanıcı: \(message)\n")
        promptParts.append("Asistan:")

        let fullPrompt = promptParts.joined(separator: "\n")

        // Build request (text-only, no video)
        let request = GeminiRequest(
            contents: [
                GeminiRequest.Content(
                    parts: [
                        GeminiRequest.Content.Part(
                            text: fullPrompt,
                            inlineData: nil
                        )
                    ]
                )
            ]
        )

        return try await sendRequestWithRetry(request: request)
    }

    // MARK: - Private Helpers

    private func sendRequestWithRetry(request: GeminiRequest) async throws -> String {
        var lastError: Error?

        for attempt in 1...Constants.API.maxRetries {
            do {
                return try await sendRequest(request: request)
            } catch let error as AppError {
                // Don't retry client errors (400, 401, 403)
                if case .apiError(let msg) = error, msg.contains("400") || msg.contains("401") || msg.contains("403") {
                    throw error
                }

                // Special handling for rate limit
                if case .rateLimitExceeded = error {
                    Configuration.log("⚠️ Rate limit hit, waiting 60 seconds... (attempt \(attempt)/\(Constants.API.maxRetries))", category: .network)

                    // Only retry once for rate limit
                    if attempt >= 2 {
                        throw error
                    }

                    // Wait for rate limit
                    try await Task.sleep(nanoseconds: Constants.Timing.rateLimitWaitTime)
                    continue
                }

                Configuration.log("Request failed (attempt \(attempt)/\(Constants.API.maxRetries)): \(error)", category: .network)
                lastError = error

                // Exponential backoff for other errors
                if attempt < Constants.API.maxRetries {
                    let delay = Double(attempt) * Constants.Timing.baseRetryDelay
                    Configuration.log("Retrying in \(delay) seconds...", category: .network)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            } catch {
                lastError = error
                throw error
            }
        }

        throw lastError ?? AppError.analysisAPIFailed
    }

    private func sendRequest(request: GeminiRequest) async throws -> String {
        // Build URL
        let urlString = "\(Constants.API.baseURL)/models/\(Constants.API.model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw AppError.apiError("Invalid URL")
        }

        // Build URLRequest
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Encode body
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        // Send request
        let (data, response) = try await urlSession.data(for: urlRequest)

        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError("Invalid response")
        }

        // Handle specific HTTP errors
        guard (200...299).contains(httpResponse.statusCode) else {
            // Rate limit exceeded
            if httpResponse.statusCode == 429 {
                Configuration.log("⚠️ Rate limit exceeded (HTTP 429)", category: .network)
                throw AppError.rateLimitExceeded
            }

            // Other errors
            throw AppError.apiError("HTTP \(httpResponse.statusCode)")
        }

        // Decode response
        let decoder = JSONDecoder()
        let geminiResponse = try decoder.decode(GeminiResponse.self, from: data)

        // Check for API error
        if let error = geminiResponse.error {
            Configuration.log("Gemini API error: \(error.code) - \(error.message)", category: .network, level: .error)
            throw AppError.apiError("\(error.code): \(error.message)")
        }

        // Validate candidates array
        guard let candidates = geminiResponse.candidates, !candidates.isEmpty else {
            Configuration.log("Invalid API response: No candidates in response", category: .network, level: .error)
            throw AppError.apiError("No candidates in API response. The model may have blocked the content.")
        }

        // Extract first candidate
        let candidate = candidates[0]

        // Validate parts array
        guard !candidate.content.parts.isEmpty else {
            Configuration.log("Invalid API response: Empty parts array in candidate", category: .network, level: .error)
            throw AppError.apiError("Empty content in API response")
        }

        // Extract text from first part
        guard let text = candidate.content.parts[0].text else {
            Configuration.log("Invalid API response: No text in content part", category: .network, level: .error)
            throw AppError.apiError("No text content in API response")
        }

        // Validate text is not empty
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            Configuration.log("Invalid API response: Empty text content", category: .network, level: .error)
            throw AppError.apiError("Empty text in API response")
        }

        Configuration.log("API response received successfully (\(text.count) characters)", category: .network, level: .debug)
        return text
    }
}
