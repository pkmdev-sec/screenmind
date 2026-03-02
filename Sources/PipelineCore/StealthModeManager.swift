import Foundation
import Shared

/// Manages stealth mode: auto-pause capture in sensitive apps/windows.
public actor StealthModeManager {

    /// Action to take when stealth rule matches.
    public enum StealthAction: String, Codable, Sendable {
        case pause      // Pause all capture
        case skip       // Skip this frame only
        case allowOnce  // Allow this frame, but prompt next time
    }

    /// A stealth mode rule.
    public struct StealthRule: Codable, Sendable, Identifiable {
        public let id: UUID
        public let appBundleID: String
        public let windowTitlePattern: String? // Regex
        public let action: StealthAction
        public let enabled: Bool

        public init(
            id: UUID = UUID(),
            appBundleID: String,
            windowTitlePattern: String? = nil,
            action: StealthAction = .pause,
            enabled: Bool = true
        ) {
            self.id = id
            self.appBundleID = appBundleID
            self.windowTitlePattern = windowTitlePattern
            self.action = action
            self.enabled = enabled
        }
    }

    private var rules: [StealthRule] = []
    private var isPaused: Bool = false
    private var cachedRegexes: [UUID: NSRegularExpression] = [:]

    public init() {
        let loadedRules = Self.loadRules()
        self.rules = loadedRules
        // Compile regexes after initialization
        Task {
            await self.compileRegexes()
        }
    }

    // MARK: - Public API

    /// Whether stealth mode is enabled globally.
    public static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "stealthEnabled") as? Bool ?? true
    }

    /// Current pause state.
    public var pauseState: Bool {
        isPaused
    }

    /// Evaluate if current app/window should be captured.
    public func shouldCapture(appBundleID: String, windowTitle: String?) -> StealthAction? {
        guard Self.isEnabled else { return nil }

        for rule in rules where rule.enabled {
            // Check bundle ID match
            if !appBundleID.contains(rule.appBundleID) {
                continue
            }

            // Check window title pattern if specified
            if let pattern = rule.windowTitlePattern,
               let windowTitle = windowTitle {
                if let regex = cachedRegexes[rule.id] {
                    let range = NSRange(windowTitle.startIndex..., in: windowTitle)
                    if regex.firstMatch(in: windowTitle, range: range) == nil {
                        continue // Pattern doesn't match
                    }
                }
            }

            // Rule matched
            SMLogger.pipeline.info("Stealth rule matched: \(rule.appBundleID) — \(rule.action.rawValue)")
            if rule.action == .pause {
                isPaused = true
            }
            return rule.action
        }

        return nil
    }

    /// Resume capture after stealth pause.
    public func resume() {
        isPaused = false
        SMLogger.pipeline.info("Stealth mode resumed")
    }

    /// Add a new stealth rule.
    public func addRule(_ rule: StealthRule) {
        rules.append(rule)
        Self.saveRules(rules)
        compileRegexes()
        SMLogger.system.info("Stealth rule added: \(rule.appBundleID)")
    }

    /// Remove a stealth rule.
    public func removeRule(id: UUID) {
        rules.removeAll { $0.id == id }
        Self.saveRules(rules)
        cachedRegexes.removeValue(forKey: id)
        SMLogger.system.info("Stealth rule removed")
    }

    /// Update a stealth rule.
    public func updateRule(_ rule: StealthRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
            Self.saveRules(rules)
            compileRegexes()
            SMLogger.system.info("Stealth rule updated")
        }
    }

    /// Get all stealth rules.
    public func getAllRules() -> [StealthRule] {
        rules
    }

    /// Load built-in sensitive app patterns.
    public static func builtInRules() -> [StealthRule] {
        [
            // Password managers
            StealthRule(
                appBundleID: "com.agilebits.onepassword",
                windowTitlePattern: nil,
                action: .pause
            ),
            StealthRule(
                appBundleID: "com.bitwarden",
                windowTitlePattern: nil,
                action: .pause
            ),
            StealthRule(
                appBundleID: "com.lastpass",
                windowTitlePattern: nil,
                action: .pause
            ),
            StealthRule(
                appBundleID: "com.keepersecurity.keeperapp",
                windowTitlePattern: nil,
                action: .pause
            ),

            // Banking/Finance apps (examples)
            StealthRule(
                appBundleID: "com.bankofamerica",
                windowTitlePattern: nil,
                action: .pause
            ),
            StealthRule(
                appBundleID: "com.chase",
                windowTitlePattern: nil,
                action: .pause
            ),

            // Browsers with sensitive window titles
            StealthRule(
                appBundleID: "com.apple.Safari",
                windowTitlePattern: #"(?i)(password|vault|private|incognito)"#,
                action: .skip
            ),
            StealthRule(
                appBundleID: "com.google.Chrome",
                windowTitlePattern: #"(?i)(password|vault|private|incognito)"#,
                action: .skip
            ),
            StealthRule(
                appBundleID: "org.mozilla.firefox",
                windowTitlePattern: #"(?i)(password|vault|private|incognito)"#,
                action: .skip
            ),

            // macOS System Preferences / Settings
            StealthRule(
                appBundleID: "com.apple.systempreferences",
                windowTitlePattern: #"(?i)(users|password|privacy|security)"#,
                action: .skip
            ),
        ]
    }

    // MARK: - Persistence

    private static func loadRules() -> [StealthRule] {
        guard let data = UserDefaults.standard.data(forKey: "stealthPatterns") else {
            // First run: install built-in rules
            let builtIn = builtInRules()
            saveRules(builtIn)
            return builtIn
        }

        return (try? JSONDecoder().decode([StealthRule].self, from: data)) ?? []
    }

    private static func saveRules(_ rules: [StealthRule]) {
        if let data = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(data, forKey: "stealthPatterns")
        }
    }

    // MARK: - Regex Compilation

    private func compileRegexes() {
        cachedRegexes.removeAll()

        for rule in rules {
            guard let pattern = rule.windowTitlePattern else { continue }

            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                cachedRegexes[rule.id] = regex
            } else {
                SMLogger.system.warning("Invalid regex pattern in stealth rule: \(pattern)")
            }
        }
    }
}
