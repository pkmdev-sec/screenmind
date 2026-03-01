import Foundation
import Shared

/// Detects and redacts sensitive data from OCR text before AI processing.
/// Runs after OCR, before AI — ensures passwords, credit cards, and API keys never reach the LLM.
public struct ContentRedactor: Sendable {

    /// Result of a redaction pass.
    public struct RedactionResult: Sendable {
        public let text: String
        public let redactionCount: Int
        public let redactedTypes: [String]
    }

    /// Built-in sensitive patterns.
    private static let builtInPatterns: [(name: String, pattern: String)] = [
        // Credit card numbers (Visa, MasterCard, Amex, etc.)
        ("credit-card", #"\b(?:\d[ -]*?){13,19}\b"#),
        // SSN (US Social Security Number)
        ("ssn", #"\b\d{3}[-\s]?\d{2}[-\s]?\d{4}\b"#),
        // API keys (common patterns: sk-..., AKIA..., ghp_..., etc.)
        ("api-key-anthropic", #"\bsk-ant-[a-zA-Z0-9_-]{20,}\b"#),
        ("api-key-openai", #"\bsk-[a-zA-Z0-9]{20,}\b"#),
        ("api-key-aws", #"\bAKIA[0-9A-Z]{16}\b"#),
        ("api-key-github", #"\bgh[ps]_[A-Za-z0-9_]{36,}\b"#),
        ("api-key-generic", #"\b[A-Za-z0-9_-]{32,}(?:key|token|secret|password)[A-Za-z0-9_-]*\b"#),
        // Email addresses
        ("email", #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"#),
        // Password field indicators (password: ..., passwd=..., etc.) — limited to prevent ReDoS
        ("password-field", #"(?i)(?:password|passwd|pwd|secret|token)\s*[:=]\s*[^\s]{1,100}"#),
        // Bearer tokens
        ("bearer-token", #"(?i)Bearer\s+[A-Za-z0-9._~+/=-]+"#),
        // Private keys (PEM format header)
        ("private-key", #"-----BEGIN\s+(?:RSA\s+)?PRIVATE\s+KEY-----"#),
    ]

    /// Redact sensitive content from OCR text.
    /// Uses built-in patterns + user-defined custom patterns from UserDefaults.
    public static func redact(_ text: String) -> RedactionResult {
        var redactedText = text
        var totalRedactions = 0
        var redactedTypes: [String] = []

        // Check if redaction is enabled (default: true)
        guard UserDefaults.standard.object(forKey: "privacyRedactionEnabled") == nil ||
              UserDefaults.standard.bool(forKey: "privacyRedactionEnabled") else {
            return RedactionResult(text: text, redactionCount: 0, redactedTypes: [])
        }

        // Apply built-in patterns
        for (name, pattern) in builtInPatterns {
            let (result, count) = applyPattern(pattern, to: redactedText, label: name)
            if count > 0 {
                redactedText = result
                totalRedactions += count
                redactedTypes.append(name)
            }
        }

        // Apply user-defined custom patterns
        let customPatterns = loadCustomPatterns()
        for custom in customPatterns {
            let (result, count) = applyPattern(custom.pattern, to: redactedText, label: custom.name)
            if count > 0 {
                redactedText = result
                totalRedactions += count
                redactedTypes.append("custom:\(custom.name)")
            }
        }

        if totalRedactions > 0 {
            SMLogger.ocr.info("Redacted \(totalRedactions) sensitive field(s): \(redactedTypes.joined(separator: ", "))")
        }

        return RedactionResult(text: redactedText, redactionCount: totalRedactions, redactedTypes: redactedTypes)
    }

    // MARK: - Pattern Application

    private static func applyPattern(_ pattern: String, to text: String, label: String) -> (String, Int) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            SMLogger.ocr.warning("Invalid redaction pattern for \(label): \(pattern)")
            return (text, 0)
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.numberOfMatches(in: text, range: range)

        if matches > 0 {
            let redacted = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "[REDACTED]")
            return (redacted, matches)
        }
        return (text, 0)
    }

    // MARK: - Custom Patterns

    /// A user-defined redaction pattern.
    public struct CustomPattern: Codable, Sendable {
        public let name: String
        public let pattern: String
        public let enabled: Bool

        public init(name: String, pattern: String, enabled: Bool = true) {
            self.name = name
            self.pattern = pattern
            self.enabled = enabled
        }
    }

    /// Load custom patterns from UserDefaults.
    public static func loadCustomPatterns() -> [CustomPattern] {
        guard let data = UserDefaults.standard.data(forKey: "privacyCustomRedactionPatterns") else {
            return []
        }
        return (try? JSONDecoder().decode([CustomPattern].self, from: data)) ?? []
    }

    /// Save custom patterns to UserDefaults.
    public static func saveCustomPatterns(_ patterns: [CustomPattern]) {
        if let data = try? JSONEncoder().encode(patterns) {
            UserDefaults.standard.set(data, forKey: "privacyCustomRedactionPatterns")
        }
    }

    /// Validate that a regex pattern compiles.
    public static func validatePattern(_ pattern: String) -> Bool {
        (try? NSRegularExpression(pattern: pattern)) != nil
    }
}
