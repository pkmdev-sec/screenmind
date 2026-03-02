import Foundation
import NaturalLanguage
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

    /// PII detection sensitivity level.
    public enum PIIDetectionLevel: String, Codable, Sendable {
        case off        // No ML-based PII detection
        case low        // Names only
        case medium     // Names + places
        case high       // Names + places + organizations + all PII
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

        // Apply ML-based PII detection (NaturalLanguage framework)
        let piiLevel = getPIIDetectionLevel()
        if piiLevel != .off {
            let (result, count, types) = detectAndRedactPII(redactedText, level: piiLevel)
            if count > 0 {
                redactedText = result
                totalRedactions += count
                redactedTypes.append(contentsOf: types)
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

    // MARK: - ML-Based PII Detection

    /// Get PII detection level from UserDefaults.
    private static func getPIIDetectionLevel() -> PIIDetectionLevel {
        guard let levelString = UserDefaults.standard.string(forKey: "piiDetectionLevel") else {
            return .off
        }
        return PIIDetectionLevel(rawValue: levelString) ?? .off
    }

    /// Detect and redact PII using NaturalLanguage framework.
    private static func detectAndRedactPII(
        _ text: String,
        level: PIIDetectionLevel
    ) -> (String, Int, [String]) {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        var redactedText = text
        var redactionCount = 0
        var redactedTypes: [String] = []

        // Tags to detect based on level
        var tagsToDetect: Set<NLTag> = []
        switch level {
        case .off:
            return (text, 0, [])
        case .low:
            tagsToDetect = [.personalName]
        case .medium:
            tagsToDetect = [.personalName, .placeName]
        case .high:
            tagsToDetect = [.personalName, .placeName, .organizationName]
        }

        // Find all entities
        var entitiesToRedact: [(range: Range<String.Index>, tag: NLTag)] = []

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
            if let tag = tag, tagsToDetect.contains(tag) {
                entitiesToRedact.append((range, tag))
            }
            return true
        }

        // Redact entities in reverse order to maintain string indices
        for (range, tag) in entitiesToRedact.reversed() {
            let tagName: String
            switch tag {
            case .personalName:
                tagName = "ml-person-name"
            case .placeName:
                tagName = "ml-place-name"
            case .organizationName:
                tagName = "ml-org-name"
            default:
                tagName = "ml-unknown"
            }

            redactedText.replaceSubrange(range, with: "[REDACTED]")
            redactionCount += 1

            if !redactedTypes.contains(tagName) {
                redactedTypes.append(tagName)
            }
        }

        return (redactedText, redactionCount, redactedTypes)
    }
}
