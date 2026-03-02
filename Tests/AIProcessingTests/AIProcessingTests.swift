import Foundation
import Testing
@testable import AIProcessing

// MARK: - NoteCategory Tests

@Test func noteCategoryValues() {
    #expect(NoteCategory.allCases.count == 7)
    #expect(NoteCategory.coding.rawValue == "coding")
    #expect(NoteCategory.meeting.rawValue == "meeting")
    #expect(NoteCategory.research.rawValue == "research")
    #expect(NoteCategory.communication.rawValue == "communication")
    #expect(NoteCategory.reading.rawValue == "reading")
    #expect(NoteCategory.terminal.rawValue == "terminal")
    #expect(NoteCategory.other.rawValue == "other")
}

@Test func noteCategoryFromString() {
    #expect(NoteCategory(rawValue: "coding") == .coding)
    #expect(NoteCategory(rawValue: "meeting") == .meeting)
    #expect(NoteCategory(rawValue: "invalid") == nil)
}

// MARK: - GeneratedNote Tests

@Test func generatedNoteInit() {
    let note = GeneratedNote(
        title: "Test",
        summary: "Test summary",
        details: "Details",
        category: .coding,
        tags: ["swift"],
        confidence: 0.9,
        skip: false,
        obsidianLinks: []
    )
    #expect(note.title == "Test")
    #expect(note.summary == "Test summary")
    #expect(note.details == "Details")
    #expect(note.category == .coding)
    #expect(note.tags == ["swift"])
    #expect(note.confidence == 0.9)
    #expect(note.skip == false)
    #expect(note.obsidianLinks == [])
}

@Test func generatedNoteJSONEncoding() throws {
    let note = GeneratedNote(
        title: "Test Note",
        summary: "Summary",
        details: "Details",
        category: .research,
        tags: ["test", "swift"],
        confidence: 0.85,
        skip: false,
        obsidianLinks: ["[[Related]]"]
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(note)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    #expect(json?["title"] as? String == "Test Note")
    #expect(json?["summary"] as? String == "Summary")
    #expect(json?["details"] as? String == "Details")
    #expect(json?["category"] as? String == "research")
    #expect((json?["tags"] as? [String])?.count == 2)
    #expect(json?["confidence"] as? Double == 0.85)
    #expect(json?["skip"] as? Bool == false)
    #expect((json?["obsidian_links"] as? [String])?.first == "[[Related]]")
}

@Test func generatedNoteJSONDecoding() throws {
    let json = """
    {
        "title": "Decoded Note",
        "summary": "A summary",
        "details": "More details",
        "category": "terminal",
        "tags": ["bash", "cli"],
        "confidence": 0.75,
        "skip": false,
        "obsidian_links": ["[[Linux]]", "[[Shell]]"]
    }
    """

    let decoder = JSONDecoder()
    let note = try decoder.decode(GeneratedNote.self, from: json.data(using: .utf8)!)

    #expect(note.title == "Decoded Note")
    #expect(note.summary == "A summary")
    #expect(note.details == "More details")
    #expect(note.category == .terminal)
    #expect(note.tags == ["bash", "cli"])
    #expect(note.confidence == 0.75)
    #expect(note.skip == false)
    #expect(note.obsidianLinks == ["[[Linux]]", "[[Shell]]"])
}

@Test func generatedNoteDecodingWithMissingFields() throws {
    let json = """
    {
        "title": "Minimal Note",
        "category": "other"
    }
    """

    let decoder = JSONDecoder()
    let note = try decoder.decode(GeneratedNote.self, from: json.data(using: .utf8)!)

    #expect(note.title == "Minimal Note")
    #expect(note.summary == "")
    #expect(note.details == "")
    #expect(note.category == .other)
    #expect(note.tags == [])
    #expect(note.confidence == 0.5)
    #expect(note.skip == false)
    #expect(note.obsidianLinks == [])
}

@Test func generatedNoteDecodingWithUnknownCategory() throws {
    let json = """
    {
        "title": "Note",
        "category": "unknown_category"
    }
    """

    let decoder = JSONDecoder()
    let note = try decoder.decode(GeneratedNote.self, from: json.data(using: .utf8)!)

    #expect(note.category == .other)
}

@Test func generatedNoteRoundTrip() throws {
    let original = GeneratedNote(
        title: "Round Trip Test",
        summary: "Testing encoding/decoding",
        details: "Should preserve all data",
        category: .coding,
        tags: ["swift", "testing"],
        confidence: 0.95,
        skip: false,
        obsidianLinks: ["[[Swift]]"]
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(original)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(GeneratedNote.self, from: data)

    #expect(decoded.title == original.title)
    #expect(decoded.summary == original.summary)
    #expect(decoded.details == original.details)
    #expect(decoded.category == original.category)
    #expect(decoded.tags == original.tags)
    #expect(decoded.confidence == original.confidence)
    #expect(decoded.skip == original.skip)
    #expect(decoded.obsidianLinks == original.obsidianLinks)
}

// MARK: - NotePromptBuilder Tests

@Test func notePromptBuilderSystemPromptContainsRequiredFields() {
    let systemPrompt = NotePromptBuilder.systemPrompt

    #expect(systemPrompt.contains("title"))
    #expect(systemPrompt.contains("summary"))
    #expect(systemPrompt.contains("details"))
    #expect(systemPrompt.contains("category"))
    #expect(systemPrompt.contains("tags"))
    #expect(systemPrompt.contains("confidence"))
    #expect(systemPrompt.contains("skip"))
    #expect(systemPrompt.contains("obsidian_links"))
    #expect(systemPrompt.contains("JSON"))
}

@Test func notePromptBuilderSystemPromptContainsCategories() {
    let systemPrompt = NotePromptBuilder.systemPrompt

    #expect(systemPrompt.contains("meeting"))
    #expect(systemPrompt.contains("research"))
    #expect(systemPrompt.contains("coding"))
    #expect(systemPrompt.contains("communication"))
    #expect(systemPrompt.contains("reading"))
    #expect(systemPrompt.contains("terminal"))
    #expect(systemPrompt.contains("other"))
}

@Test func notePromptBuilderUserPromptIncludesBasicInfo() {
    let prompt = NotePromptBuilder.buildUserPrompt(
        ocrText: "Sample OCR text",
        appName: "Xcode",
        windowTitle: "MyFile.swift",
        lastNoteTitle: nil,
        lastNoteApp: nil
    )

    #expect(prompt.contains("Xcode"))
    #expect(prompt.contains("MyFile.swift"))
    #expect(prompt.contains("Sample OCR text"))
    #expect(prompt.contains("App:"))
    #expect(prompt.contains("Window:"))
}

@Test func notePromptBuilderUserPromptWithoutWindowTitle() {
    let prompt = NotePromptBuilder.buildUserPrompt(
        ocrText: "Text",
        appName: "Terminal",
        windowTitle: nil,
        lastNoteTitle: nil,
        lastNoteApp: nil
    )

    #expect(prompt.contains("Terminal"))
    #expect(prompt.contains("Text"))
}

@Test func notePromptBuilderUserPromptIncludesPreviousNote() {
    let prompt = NotePromptBuilder.buildUserPrompt(
        ocrText: "New content",
        appName: "Xcode",
        windowTitle: nil,
        lastNoteTitle: "Previous Task",
        lastNoteApp: "VS Code"
    )

    #expect(prompt.contains("Previous note"))
    #expect(prompt.contains("Previous Task"))
    #expect(prompt.contains("VS Code"))
}

// MARK: - ClaudeResponseParser Tests

@Test func claudeResponseParserParsesValidJSON() throws {
    let apiResponse = """
    {
        "content": [{
            "text": "{\\\"title\\\":\\\"Test\\\",\\\"summary\\\":\\\"Summary\\\",\\\"details\\\":\\\"\\\",\\\"category\\\":\\\"other\\\",\\\"tags\\\":[],\\\"confidence\\\":0.5,\\\"skip\\\":false,\\\"obsidian_links\\\":[]}"
        }]
    }
    """

    let note = try ClaudeResponseParser.parse(apiResponse.data(using: .utf8)!)
    #expect(note.title == "Test")
    #expect(note.category == .other)
}

@Test func claudeResponseParserHandlesMarkdownWrappedJSON() throws {
    let json = """
    ```json
    {
        "title": "Wrapped Note",
        "summary": "Test",
        "details": "",
        "category": "coding",
        "tags": [],
        "confidence": 0.8,
        "skip": false,
        "obsidian_links": []
    }
    ```
    """

    let note = try ClaudeResponseParser.parseNoteJSON(json)
    #expect(note.title == "Wrapped Note")
    #expect(note.category == .coding)
}

@Test func claudeResponseParserHandlesPlainCodeBlock() throws {
    let json = """
    ```
    {
        "title": "Plain Block",
        "summary": "",
        "details": "",
        "category": "other",
        "tags": [],
        "confidence": 0.5,
        "skip": false,
        "obsidian_links": []
    }
    ```
    """

    let note = try ClaudeResponseParser.parseNoteJSON(json)
    #expect(note.title == "Plain Block")
}

@Test func claudeResponseParserExtractsJSONFromText() throws {
    let mixed = """
    Here is the note:
    {
        "title": "Extracted Note",
        "summary": "Found in text",
        "details": "",
        "category": "other",
        "tags": [],
        "confidence": 0.5,
        "skip": false,
        "obsidian_links": []
    }
    And some trailing text.
    """

    let note = try ClaudeResponseParser.parseNoteJSON(mixed)
    #expect(note.title == "Extracted Note")
}

@Test func claudeResponseParserFallbackForUnknownCategory() throws {
    let json = """
    {
        "title": "Test",
        "category": "invalid_category",
        "summary": "",
        "details": "",
        "tags": [],
        "confidence": 0.5,
        "skip": false,
        "obsidian_links": []
    }
    """

    let note = try ClaudeResponseParser.parseNoteJSON(json)
    #expect(note.category == .other)
}

// MARK: - TagSuggester Tests

@Test func tagSuggesterSuggestsAppTag() {
    let tags = TagSuggester.suggest(
        appName: "Xcode",
        windowTitle: nil,
        textSample: "Some code",
        existingTags: [:]
    )

    #expect(tags.contains("xcode"))
}

@Test func tagSuggesterDetectsTechnologyKeywords() {
    let tags = TagSuggester.suggest(
        appName: "Terminal",
        windowTitle: nil,
        textSample: "git commit -m 'fix: update swift code'",
        existingTags: [:]
    )

    #expect(tags.contains { $0 == "git" || $0 == "swift" })
}

@Test func tagSuggesterDetectsMultipleTechnologies() {
    let tags = TagSuggester.suggest(
        appName: "VS Code",
        windowTitle: "api.js",
        textSample: "docker run postgres database",
        existingTags: [:]
    )

    // Should detect docker, database, and possibly javascript from window
    let detected = tags.filter { ["docker", "devops", "database", "javascript"].contains($0) }
    #expect(detected.count > 0)
}

@Test func tagSuggesterBoostsHistoricalTags() {
    let tags = TagSuggester.suggest(
        appName: "Xcode",
        windowTitle: nil,
        textSample: "swift code with api calls",
        existingTags: ["api": 10, "swift": 8]
    )

    // Historical tags that match content should appear
    #expect(tags.contains("api") || tags.contains("swift"))
}

@Test func tagSuggesterLimitsTags() {
    let lotsOfFrequencies = Dictionary(uniqueKeysWithValues: (0..<20).map { ("tag\($0)", $0) })
    let tags = TagSuggester.suggest(
        appName: "Test",
        windowTitle: nil,
        textSample: "text",
        existingTags: lotsOfFrequencies
    )

    #expect(tags.count <= 5)
}

// MARK: - AIProviderFactory Tests

@Test func aiProviderTypeHasDefaults() {
    #expect(AIProviderType.claude.defaultBaseURL.hasPrefix("https://"))
    #expect(!AIProviderType.claude.defaultModelName.isEmpty)
    #expect(AIProviderType.claude.requiresAPIKey == true)

    #expect(AIProviderType.ollama.requiresAPIKey == false)
    #expect(AIProviderType.ollama.defaultBaseURL.contains("localhost"))
}

@Test func aiProviderTypeProperties() {
    #expect(AIProviderType.claude.rawValue == "Claude")
    #expect(AIProviderType.openai.rawValue == "OpenAI")
    #expect(AIProviderType.ollama.rawValue == "Ollama")
    #expect(AIProviderType.gemini.rawValue == "Gemini")

    #expect(!AIProviderType.claude.iconName.isEmpty)
    #expect(!AIProviderType.claude.subtitle.isEmpty)
}

@Test func aiProviderTypeKeychainKeys() {
    #expect(AIProviderType.claude.keychainKey.contains("claude"))
    #expect(AIProviderType.openai.keychainKey.contains("openai"))
}
