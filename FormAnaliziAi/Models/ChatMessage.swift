//
//  ChatMessage.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import Foundation

// MARK: - Message Role
enum MessageRole: String, Codable, Sendable {
    case user = "user"
    case assistant = "assistant"
}

// MARK: - Chat Message Model
struct ChatMessage: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }

    var isUser: Bool {
        role == .user
    }

    var isAssistant: Bool {
        role == .assistant
    }
}

// MARK: - Mock Data
extension ChatMessage {
    static let mockMessages: [ChatMessage] = [
        ChatMessage(
            role: .user,
            content: "Squat derinliğimi nasıl artırabilirim?"
        ),
        ChatMessage(
            role: .assistant,
            content: "Squat derinliğini artırmak için birkaç öneri:\n\n1. Ankle mobility çalışmaları yapın\n2. Goblet squat ile başlayın\n3. Topuk altına plaka koyarak deneyin\n4. Hamstring esneklik çalışmaları"
        ),
        ChatMessage(
            role: .user,
            content: "Kaç kere tekrar yapmalıyım?"
        ),
        ChatMessage(
            role: .assistant,
            content: "Form çalışması için 3-4 set, 8-12 tekrar ideal. Ağırlık eklemeden önce formu mükemmelleştirin."
        )
    ]
}
