import Foundation
import Shared

/// Evaluates user-defined skip rules against OCR text and capture context.
/// Runs after OCR, before AI — saves API costs by skipping unwanted content.
public struct SkipRuleEngine: Sendable {

    /// Result of rule evaluation.
    public struct EvaluationResult: Sendable {
        public let shouldSkip: Bool
        public let matchedRule: SkipRule?
    }

    /// A user-defined skip rule.
    public struct SkipRule: Codable, Sendable, Identifiable {
        public var id: UUID
        public var name: String
        public var type: RuleType
        public var pattern: String
        public var enabled: Bool

        public init(name: String, type: RuleType, pattern: String, enabled: Bool = true) {
            self.id = UUID()
            self.name = name
            self.type = type
            self.pattern = pattern
            self.enabled = enabled
        }
    }

    /// Types of skip rules.
    public enum RuleType: String, Codable, Sendable, CaseIterable {
        case textContains = "Text contains"
        case textRegex = "Text matches regex"
        case appEquals = "App equals"
        case appContains = "App name contains"
        case windowTitleContains = "Window title contains"

        public var iconName: String {
            switch self {
            case .textContains, .textRegex: return "text.magnifyingglass"
            case .appEquals, .appContains: return "app.fill"
            case .windowTitleContains: return "macwindow"
            }
        }
    }

    /// Evaluate all enabled rules against the given context.
    public static func evaluate(
        text: String,
        appName: String,
        windowTitle: String?
    ) -> EvaluationResult {
        let rules = loadRules().filter(\.enabled)
        guard !rules.isEmpty else {
            return EvaluationResult(shouldSkip: false, matchedRule: nil)
        }

        for rule in rules {
            if matches(rule: rule, text: text, appName: appName, windowTitle: windowTitle) {
                SMLogger.pipeline.info("Skip rule matched: \"\(rule.name)\" [\(rule.type.rawValue)]")
                return EvaluationResult(shouldSkip: true, matchedRule: rule)
            }
        }

        return EvaluationResult(shouldSkip: false, matchedRule: nil)
    }

    // MARK: - Rule Matching

    private static func matches(rule: SkipRule, text: String, appName: String, windowTitle: String?) -> Bool {
        switch rule.type {
        case .textContains:
            return text.localizedCaseInsensitiveContains(rule.pattern)

        case .textRegex:
            guard let regex = try? NSRegularExpression(pattern: rule.pattern, options: [.caseInsensitive]) else {
                return false
            }
            let range = NSRange(text.startIndex..., in: text)
            return regex.firstMatch(in: text, range: range) != nil

        case .appEquals:
            return appName.localizedCaseInsensitiveCompare(rule.pattern) == .orderedSame

        case .appContains:
            return appName.localizedCaseInsensitiveContains(rule.pattern)

        case .windowTitleContains:
            guard let windowTitle else { return false }
            return windowTitle.localizedCaseInsensitiveContains(rule.pattern)
        }
    }

    // MARK: - Persistence

    /// Load skip rules from UserDefaults.
    public static func loadRules() -> [SkipRule] {
        guard let data = UserDefaults.standard.data(forKey: "privacySkipRules") else {
            return []
        }
        return (try? JSONDecoder().decode([SkipRule].self, from: data)) ?? []
    }

    /// Save skip rules to UserDefaults.
    public static func saveRules(_ rules: [SkipRule]) {
        if let data = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(data, forKey: "privacySkipRules")
        }
    }

    /// Example rules for onboarding.
    public static var exampleRules: [SkipRule] {
        [
            SkipRule(name: "Skip build logs", type: .textContains, pattern: "Build succeeded", enabled: false),
            SkipRule(name: "Skip npm output", type: .textContains, pattern: "npm install", enabled: false),
            SkipRule(name: "Skip password managers", type: .appContains, pattern: "1Password", enabled: false),
        ]
    }
}
