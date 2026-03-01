import Foundation
import Shared
import StorageCore

/// Chat with your notes using RAG (Retrieval-Augmented Generation).
public actor ChatActor {
    private let semanticSearch: SemanticSearchActor
    private var chatHistory: [ChatMessage] = []

    public init(semanticSearch: SemanticSearchActor) {
        self.semanticSearch = semanticSearch
    }

    /// Ask a question and get an AI-generated answer using note context.
    public func ask(question: String, modelContainer: Any) async throws -> ChatResponse {
        // 1. Retrieve relevant notes via semantic search
        let matches = try await semanticSearch.search(query: question, limit: 5)

        // 2. Build context string from matched note IDs
        // Note: in real implementation, we'd fetch full notes from StorageActor
        // For now, return the matches and let the caller build the prompt
        let context = matches.map { "Note \($0.noteID) (score: \(String(format: "%.2f", $0.score)))" }.joined(separator: "\n")

        // 3. Build RAG prompt
        let prompt = buildRAGPrompt(question: question, context: context)

        // 4. Add to history
        chatHistory.append(ChatMessage(role: .user, content: question))

        return ChatResponse(
            answer: prompt, // Caller sends this to AI provider
            sourceNoteIDs: matches.map(\.noteID),
            sourcesCount: matches.count,
            ragPrompt: prompt
        )
    }

    /// Clear chat history.
    public func clearHistory() {
        chatHistory.removeAll()
    }

    public var history: [ChatMessage] { chatHistory }

    // MARK: - Private

    private func buildRAGPrompt(question: String, context: String) -> String {
        let historyText = chatHistory.suffix(6).map { "\($0.role.rawValue): \($0.content)" }.joined(separator: "\n")

        return """
        You are a helpful assistant that answers questions based on the user's captured screen notes from ScreenMind.

        RELEVANT NOTES (retrieved by semantic similarity):
        \(context)

        CONVERSATION HISTORY:
        \(historyText)

        USER QUESTION: \(question)

        Instructions:
        - Answer based on the provided notes context
        - If the notes don't contain relevant information, say so clearly
        - Be concise and direct
        - Reference specific notes when possible
        - If the user asks about time/dates, use the note timestamps

        ANSWER:
        """
    }
}

/// A chat message.
public struct ChatMessage: Sendable, Codable, Identifiable {
    public let id: UUID
    public let role: Role
    public let content: String
    public let timestamp: Date

    public enum Role: String, Sendable, Codable {
        case user
        case assistant
        case system
    }

    public init(role: Role, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = .now
    }
}

/// Response from the chat actor.
public struct ChatResponse: Sendable {
    public let answer: String
    public let sourceNoteIDs: [String]
    public let sourcesCount: Int
    public let ragPrompt: String

    public init(answer: String, sourceNoteIDs: [String], sourcesCount: Int, ragPrompt: String) {
        self.answer = answer
        self.sourceNoteIDs = sourceNoteIDs
        self.sourcesCount = sourcesCount
        self.ragPrompt = ragPrompt
    }
}
