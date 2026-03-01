import Foundation

/// Cleans and deduplicates OCR output before sending to AI.
public enum TextPreprocessor {

    /// Clean raw OCR lines: trim whitespace, remove duplicates, collapse blank lines.
    public static func clean(_ rawLines: [(text: String, confidence: Float)], minConfidence: Float = 0.3) -> (text: String, avgConfidence: Double, wordCount: Int) {
        let filtered = rawLines.filter { $0.confidence >= minConfidence }

        guard !filtered.isEmpty else {
            return ("", 0.0, 0)
        }

        // Deduplicate consecutive identical lines
        var deduplicated: [String] = []
        var lastLine = ""
        for (text, _) in filtered {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, trimmed != lastLine else { continue }
            deduplicated.append(trimmed)
            lastLine = trimmed
        }

        let combinedText = deduplicated.joined(separator: "\n")
        let avgConfidence = filtered.reduce(0.0) { $0 + Double($1.confidence) } / Double(filtered.count)
        let wordCount = combinedText.split(separator: " ").count

        return (combinedText, avgConfidence, wordCount)
    }

    /// Truncate text to a maximum character count, preserving word boundaries.
    public static func truncate(_ text: String, maxCharacters: Int = 4000) -> String {
        guard text.count > maxCharacters else { return text }
        let truncated = String(text.prefix(maxCharacters))
        // Cut at last space to avoid splitting words
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[truncated.startIndex..<lastSpace]) + "..."
        }
        return truncated + "..."
    }
}
