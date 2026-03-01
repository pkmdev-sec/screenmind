import Foundation
import Shared

/// Parses Claude API responses into GeneratedNote structs.
public enum ClaudeResponseParser {

    /// Parse the raw API response data into a GeneratedNote.
    public static func parse(_ data: Data) throws -> GeneratedNote {
        // Parse the top-level API response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let textContent = firstBlock["text"] as? String else {
            throw ClaudeError.parseError("Could not extract text from API response")
        }

        // The text content should be JSON — parse it
        return try parseNoteJSON(textContent)
    }

    /// Parse the JSON note content from Claude's text response.
    static func parseNoteJSON(_ text: String) throws -> GeneratedNote {
        // Claude sometimes wraps JSON in markdown code blocks
        let cleaned = stripCodeBlock(text)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw ClaudeError.parseError("Could not convert text to data")
        }

        do {
            return try JSONDecoder().decode(GeneratedNote.self, from: jsonData)
        } catch {
            let msg = String(describing: error)
            let preview = String(cleaned.prefix(200))
            SMLogger.ai.error("JSON decode failed: \(msg, privacy: .public) — preview: \(preview, privacy: .public)")
            throw ClaudeError.parseError(msg)
        }
    }

    /// Strip markdown code block wrappers if present.
    private static func stripCodeBlock(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle ```json, ```JSON, or plain ```
        if result.hasPrefix("```json") {
            result = String(result.dropFirst(7))
        } else if result.hasPrefix("```JSON") {
            result = String(result.dropFirst(7))
        } else if result.hasPrefix("```") {
            result = String(result.dropFirst(3))
        }
        if result.hasSuffix("```") {
            result = String(result.dropLast(3))
        }

        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        // If still not valid JSON, try to extract JSON object from the text
        if !result.hasPrefix("{"), let start = result.firstIndex(of: "{"),
           let end = result.lastIndex(of: "}") {
            result = String(result[start...end])
        }

        return result
    }
}
