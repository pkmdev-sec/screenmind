import Foundation
import Shared

/// Language model API client for note generation.
public struct ClaudeProvider: AIProvider, Sendable {
    private let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func generateNote(from ocrText: String, appName: String, windowTitle: String?, lastNoteTitle: String? = nil, lastNoteApp: String? = nil) async throws -> GeneratedNote {
        let prompt = NotePromptBuilder.buildUserPrompt(ocrText: ocrText, appName: appName, windowTitle: windowTitle, lastNoteTitle: lastNoteTitle, lastNoteApp: lastNoteApp)

        let requestBody: [String: Any] = [
            "model": AppConstants.AI.modelName,
            "max_tokens": AppConstants.AI.maxTokens,
            "temperature": AppConstants.AI.temperature,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "system": NotePromptBuilder.systemPrompt
        ]

        var request = URLRequest(url: URL(string: AppConstants.AI.apiBaseURL)!)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(AppConstants.AI.anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            SMLogger.ai.error("Claude API error \(httpResponse.statusCode): \(body)")
            throw ClaudeError.apiError(statusCode: httpResponse.statusCode, message: body)
        }

        return try ClaudeResponseParser.parse(data)
    }

}

/// Errors from the Claude API.
public enum ClaudeError: Error, LocalizedError {
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parseError(String)
    case rateLimited
    case noAPIKey

    public var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from Claude API"
        case .apiError(let code, let msg): return "Claude API error \(code): \(msg)"
        case .parseError(let detail): return "Failed to parse Claude response: \(detail)"
        case .rateLimited: return "Claude API rate limit exceeded"
        case .noAPIKey: return "No Anthropic API key configured"
        }
    }
}
