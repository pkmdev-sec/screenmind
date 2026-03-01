import Foundation
import Shared

/// Language model API client for note generation.
public struct ClaudeProvider: AIProvider, Sendable {
    private let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func generateNote(from ocrText: String, appName: String, windowTitle: String?, lastNoteTitle: String? = nil, lastNoteApp: String? = nil) async throws -> GeneratedNote {
        let prompt = buildPrompt(ocrText: ocrText, appName: appName, windowTitle: windowTitle, lastNoteTitle: lastNoteTitle, lastNoteApp: lastNoteApp)

        let requestBody: [String: Any] = [
            "model": AppConstants.AI.modelName,
            "max_tokens": AppConstants.AI.maxTokens,
            "temperature": AppConstants.AI.temperature,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "system": systemPrompt
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

    // MARK: - Prompt Construction

    private var systemPrompt: String {
        """
        You are a screen activity analyzer for ScreenMind, a macOS productivity app. \
        Your job is to generate concise, useful notes from OCR text captured from the user's screen. \
        Only create notes for genuinely noteworthy activity — quality over quantity.

        ALWAYS respond with valid JSON matching this schema:
        {
          "title": "Brief descriptive title (max 60 chars)",
          "summary": "1-2 sentence summary of what the user was doing and WHY it matters",
          "details": "Structured extraction of key information (see guidelines below)",
          "category": "meeting|research|coding|communication|reading|terminal|other",
          "tags": ["tag1", "tag2"],
          "confidence": 0.0-1.0,
          "skip": false,
          "obsidian_links": ["[[Related Topic]]"]
        }

        DETAILS EXTRACTION GUIDELINES — include whichever apply:
        - **URLs / links** mentioned on screen (full URLs if visible)
        - **Code snippets** or commands that are noteworthy (formatted in backticks)
        - **Names / people** mentioned (meeting participants, authors, contacts)
        - **Decisions or conclusions** reached (what was decided, not just discussed)
        - **Action items / TODOs** visible on screen
        - **Key data points** (numbers, dates, versions, error codes)
        - **Search queries** the user typed
        Format details as short bullet points, not prose. Focus on what the user would want to recall later.

        TITLE GUIDELINES:
        - Start with an action verb when possible: "Debugging auth timeout in API", "Reviewing PR #42 feedback"
        - Be specific: "Reading Rust async docs" not "Browsing web"
        - Include the core topic, not just the app name

        Set "skip": true if the screen content is:
        - A lock screen, screensaver, or blank/idle screen
        - Login/password dialogs (NEVER capture credentials or sensitive data)
        - Purely decorative UI with no meaningful content
        - Too noisy or fragmented to be useful
        - The same general activity and topic as the previous note — only create a new note if the user has meaningfully switched tasks, topics, or context
        - Repetitive terminal output, build logs, or test output without new failures
        - System notifications, alerts, or transient popups
        - App store, system settings, or routine system UI
        - Content with very little actionable or memorable information

        Be aggressive about skipping. A good rule: if the user wouldn't find this note useful tomorrow, skip it. \
        When in doubt, skip.

        For tags: use lowercase, kebab-case. Include the app name as a tag. Add 2-4 topic tags.
        For obsidian_links: suggest wiki-links to related topics, projects, or technologies the user might track.
        """
    }

    private func buildPrompt(ocrText: String, appName: String, windowTitle: String?, lastNoteTitle: String?, lastNoteApp: String?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let timestamp = formatter.string(from: Date())

        var prompt = "Timestamp: \(timestamp)\nApp: \(appName)"
        if let windowTitle, !windowTitle.isEmpty {
            prompt += "\nWindow: \(windowTitle)"
        }
        if let lastNoteTitle, let lastNoteApp {
            prompt += "\n\nPrevious note (for dedup — skip if same activity):"
            prompt += "\n- Title: \(lastNoteTitle)"
            prompt += "\n- App: \(lastNoteApp)"
        }
        prompt += "\n\nScreen text:\n\(ocrText)"
        return prompt
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
