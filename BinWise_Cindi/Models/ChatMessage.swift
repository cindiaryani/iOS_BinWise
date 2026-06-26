import Foundation

// MARK: – Role

/// Sender of a chat message in the Coach chatbot conversation.
enum MessageRole: String, Codable {
    case user
    case assistant
}

// MARK: – Model

/// A single message in the Coach chatbot conversation history.
/// Persisted to UserDefaults (last 20 messages) for cross-session continuity.
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date

    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date()) {
        self.id        = id
        self.role      = role
        self.content   = content
        self.timestamp = timestamp
    }
}
