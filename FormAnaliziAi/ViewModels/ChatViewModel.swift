//
//  ChatViewModel.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import Foundation
import Observation

@Observable
@MainActor
class ChatViewModel {
    // Dependencies
    private let geminiService: GeminiService
    private let storageService: StorageService

    // Published State
    var messages: [ChatMessage]
    var session: AnalysisSession
    var inputText = ""
    var isLoading = false
    var error: AppError?
    var showError = false

    init(session: AnalysisSession, geminiService: GeminiService, storageService: StorageService) {
        self.session = session
        self.messages = session.chatHistory
        self.geminiService = geminiService
        self.storageService = storageService
    }

    // MARK: - Computed Properties
    var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    // MARK: - Actions
    func sendMessage() async {
        let userMessage = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }

        // Provide haptic feedback
        HapticManager.shared.impact(.light)

        // Clear input
        inputText = ""

        // Add user message
        let message = ChatMessage(role: .user, content: userMessage)
        messages.append(message)

        // Send to AI
        isLoading = true
        defer { isLoading = false }

        do {
            // Create updated session with new message
            var updatedSession = session
            updatedSession.addChatMessage(message)

            // Send to Gemini
            let response = try await geminiService.sendChatMessage(
                message: userMessage,
                session: updatedSession
            )

            // Add assistant response
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            messages.append(assistantMessage)

            // Update session
            updatedSession.addChatMessage(assistantMessage)

            // Save session
            try await storageService.saveSession(updatedSession)

            // Update local session reference
            session = updatedSession

        } catch let appError as AppError {
            error = appError
            showError = true
        } catch {
            self.error = .unknown(error.localizedDescription)
            showError = true
        }
    }
}
