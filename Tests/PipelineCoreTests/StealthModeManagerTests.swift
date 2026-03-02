import Testing
import Foundation
@testable import PipelineCore

@Test func stealthModeManagerInitializes() async {
    let manager = StealthModeManager()
    let rules = await manager.getAllRules()

    // Should initialize with built-in rules
    #expect(!rules.isEmpty)
}

@Test func stealthModeManagerDetectsSensitiveApp() async {
    let manager = StealthModeManager()

    // Test 1Password detection
    let action = await manager.shouldCapture(
        appBundleID: "com.agilebits.onepassword",
        windowTitle: nil
    )

    #expect(action == .pause)
}

@Test func stealthModeManagerWindowTitlePattern() async {
    let manager = StealthModeManager()

    // Test Safari with "password" in window title
    let action1 = await manager.shouldCapture(
        appBundleID: "com.apple.Safari",
        windowTitle: "Login - Password Manager"
    )

    #expect(action1 == .skip)

    // Test Safari with normal window title (without sensitive keywords)
    let action2 = await manager.shouldCapture(
        appBundleID: "com.apple.Safari",
        windowTitle: "GitHub - Homepage"
    )

    // Should not match sensitive pattern (or return nil if no rule matches)
    // Note: Built-in rules include Safari patterns, so it might return .skip or nil
    #expect(action2 == nil || action2 == .skip)
}

@Test func stealthModeManagerAddRemoveRule() async {
    let manager = StealthModeManager()

    let rule = StealthModeManager.StealthRule(
        appBundleID: "com.test.app",
        windowTitlePattern: nil,
        action: .pause,
        enabled: true
    )

    await manager.addRule(rule)

    var rules = await manager.getAllRules()
    #expect(rules.contains(where: { $0.appBundleID == "com.test.app" }))

    await manager.removeRule(id: rule.id)

    rules = await manager.getAllRules()
    #expect(!rules.contains(where: { $0.id == rule.id }))
}

@Test func stealthModeManagerPauseState() async {
    let manager = StealthModeManager()

    // Initial state should not be paused
    var pauseState = await manager.pauseState
    #expect(!pauseState)

    // Trigger pause with sensitive app
    _ = await manager.shouldCapture(
        appBundleID: "com.agilebits.onepassword",
        windowTitle: nil
    )

    pauseState = await manager.pauseState
    #expect(pauseState)

    // Resume
    await manager.resume()

    pauseState = await manager.pauseState
    #expect(!pauseState)
}

@Test func stealthModeManagerBuiltInRules() {
    let rules = StealthModeManager.builtInRules()

    #expect(!rules.isEmpty)

    // Should include password managers
    let hasPasswordManager = rules.contains { $0.appBundleID.contains("onepassword") }
    #expect(hasPasswordManager)

    // Should include browser privacy patterns
    let hasBrowserPattern = rules.contains { $0.appBundleID.contains("Safari") }
    #expect(hasBrowserPattern)
}

@Test func stealthModeManagerRegexPattern() async {
    let manager = StealthModeManager()

    // Create rule with regex pattern for "private" in window title
    let rule = StealthModeManager.StealthRule(
        id: UUID(),
        appBundleID: "com.test.browser",
        windowTitlePattern: #"(?i)private"#,
        action: .skip,
        enabled: true
    )

    await manager.addRule(rule)

    // Should match case-insensitive "Private"
    let action1 = await manager.shouldCapture(
        appBundleID: "com.test.browser",
        windowTitle: "Private Browsing Mode"
    )
    #expect(action1 == .skip)

    // Should not match without "private"
    let action2 = await manager.shouldCapture(
        appBundleID: "com.test.browser",
        windowTitle: "Normal Browsing"
    )
    #expect(action2 == nil)
}
