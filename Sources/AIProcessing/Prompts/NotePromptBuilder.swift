import Foundation

/// Per-app prompt template configuration.
public struct AppPromptTemplate: Codable, Sendable {
    public let bundleID: String
    public let template: String
    public let enabled: Bool

    public init(bundleID: String, template: String, enabled: Bool = true) {
        self.bundleID = bundleID
        self.template = template
        self.enabled = enabled
    }
}

/// Shared prompt construction for all AI providers. Single source of truth for system prompt and user prompt format.
public enum NotePromptBuilder {

    /// System prompt instructing the AI how to generate notes.
    public static var systemPrompt: String {
        var prompt = """
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

        IMPORTANT: Respond ONLY with the JSON object. No markdown, no explanation, no code blocks.
        """

        // Append feedback modifiers if available
        let modifiers = FeedbackAnalyzer.loadModifiers()
        if !modifiers.isEmpty {
            prompt += "\n\nUSER FEEDBACK PATTERNS (adapt your behavior):\n"
            for modifier in modifiers {
                prompt += "- \(modifier)\n"
            }
        }

        return prompt
    }

    /// Build the user prompt from screen capture context.
    public static func buildUserPrompt(
        ocrText: String,
        appName: String,
        windowTitle: String?,
        lastNoteTitle: String?,
        lastNoteApp: String?,
        bundleID: String? = nil,
        contextWindow: [(title: String, summary: String, timestamp: Date)] = []
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let timestamp = formatter.string(from: Date())

        // Check for app-specific prompt template
        if let bundleID = bundleID,
           let template = getAppTemplate(for: bundleID) {
            return applyTemplate(
                template,
                appName: appName,
                windowTitle: windowTitle,
                ocrText: ocrText,
                timestamp: timestamp
            )
        }

        // Default prompt
        var prompt = "Timestamp: \(timestamp)\nApp: \(appName)"
        if let windowTitle, !windowTitle.isEmpty {
            prompt += "\nWindow: \(windowTitle)"
        }

        // Add context window if available
        if !contextWindow.isEmpty {
            prompt += "\n\nRecent context:"
            let now = Date.now
            for context in contextWindow.reversed() {
                let minutesAgo = Int(now.timeIntervalSince(context.timestamp) / 60)
                prompt += "\n- \(minutesAgo)m ago: [\(context.title)] — \(context.summary)"
            }
        }

        if let lastNoteTitle, let lastNoteApp {
            prompt += "\n\nPrevious note (for dedup — skip if same activity):"
            prompt += "\n- Title: \(lastNoteTitle)"
            prompt += "\n- App: \(lastNoteApp)"
        }
        prompt += "\n\nScreen text:\n\(ocrText)"
        return prompt
    }

    /// Get the app-specific template for a bundle ID.
    private static func getAppTemplate(for bundleID: String) -> String? {
        guard let data = UserDefaults.standard.data(forKey: "appPromptTemplates"),
              let templates = try? JSONDecoder().decode([AppPromptTemplate].self, from: data) else {
            return nil
        }

        // Find matching template (enabled only)
        return templates.first(where: { $0.bundleID == bundleID && $0.enabled })?.template
    }

    /// Apply template with variable substitution.
    private static func applyTemplate(
        _ template: String,
        appName: String,
        windowTitle: String?,
        ocrText: String,
        timestamp: String
    ) -> String {
        return template
            .replacingOccurrences(of: "{app}", with: appName)
            .replacingOccurrences(of: "{window}", with: windowTitle ?? "")
            .replacingOccurrences(of: "{text}", with: ocrText)
            .replacingOccurrences(of: "{timestamp}", with: timestamp)
    }
}
