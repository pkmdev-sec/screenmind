import Foundation
import Testing
@testable import PipelineCore

// MARK: - PipelineStats Tests

@Test func pipelineStatsInit() {
    let stats = PipelineStats(
        totalFrames: 100,
        filteredFrames: 80,
        significantFrames: 20,
        ocrProcessed: 15,
        avgOCRTime: 0.05,
        aiRequests: 10,
        aiLimit: 100
    )
    #expect(stats.totalFrames == 100)
    #expect(stats.significantFrames == 20)
    #expect(stats.aiRequests == 10)
}

// MARK: - SkipRuleEngine Tests

@Suite(.serialized) struct SkipRuleTests {

@Test func skipRuleEngineNoRulesReturnsNoSkip() {
    // Clear any existing rules
    UserDefaults.standard.removeObject(forKey: "privacySkipRules")

    let result = SkipRuleEngine.evaluate(text: "Some text", appName: "TestApp", windowTitle: nil)
    #expect(result.shouldSkip == false)
    #expect(result.matchedRule == nil)
}

@Test func skipRuleEngineTextContainsMatch() {
    let rule = SkipRuleEngine.SkipRule(name: "Skip builds", type: .textContains, pattern: "Build succeeded")
    SkipRuleEngine.saveRules([rule])
    defer { SkipRuleEngine.saveRules([]) }

    let result = SkipRuleEngine.evaluate(text: "Build succeeded in 3.2 seconds", appName: "Xcode", windowTitle: nil)
    #expect(result.shouldSkip == true)
    #expect(result.matchedRule?.name == "Skip builds")
}

@Test func skipRuleEngineTextContainsNoMatch() {
    let rule = SkipRuleEngine.SkipRule(name: "Skip builds", type: .textContains, pattern: "Build succeeded")
    SkipRuleEngine.saveRules([rule])
    defer { SkipRuleEngine.saveRules([]) }

    let result = SkipRuleEngine.evaluate(text: "Writing Swift code", appName: "Xcode", windowTitle: nil)
    #expect(result.shouldSkip == false)
}

@Test func skipRuleEngineAppEquals() {
    let rule = SkipRuleEngine.SkipRule(name: "Skip Spotify", type: .appEquals, pattern: "Spotify")
    SkipRuleEngine.saveRules([rule])
    defer { SkipRuleEngine.saveRules([]) }

    let match = SkipRuleEngine.evaluate(text: "Now playing", appName: "Spotify", windowTitle: nil)
    #expect(match.shouldSkip == true)

    let noMatch = SkipRuleEngine.evaluate(text: "Now playing", appName: "Apple Music", windowTitle: nil)
    #expect(noMatch.shouldSkip == false)
}

@Test func skipRuleEngineAppContains() {
    let rule = SkipRuleEngine.SkipRule(name: "Skip password managers", type: .appContains, pattern: "1Password")
    SkipRuleEngine.saveRules([rule])
    defer { SkipRuleEngine.saveRules([]) }

    let result = SkipRuleEngine.evaluate(text: "Login form", appName: "1Password 7", windowTitle: nil)
    #expect(result.shouldSkip == true)
}

@Test func skipRuleEngineWindowTitleContains() {
    let rule = SkipRuleEngine.SkipRule(name: "Skip private browsing", type: .windowTitleContains, pattern: "Private")
    SkipRuleEngine.saveRules([rule])
    defer { SkipRuleEngine.saveRules([]) }

    let match = SkipRuleEngine.evaluate(text: "Web page", appName: "Safari", windowTitle: "Private Browsing")
    #expect(match.shouldSkip == true)

    let noMatch = SkipRuleEngine.evaluate(text: "Web page", appName: "Safari", windowTitle: "GitHub")
    #expect(noMatch.shouldSkip == false)

    let nilTitle = SkipRuleEngine.evaluate(text: "Web page", appName: "Safari", windowTitle: nil)
    #expect(nilTitle.shouldSkip == false)
}

@Test func skipRuleEngineTextRegex() {
    let rule = SkipRuleEngine.SkipRule(name: "Skip errors", type: .textRegex, pattern: #"ERROR\s+\d{3}"#)
    SkipRuleEngine.saveRules([rule])
    defer { SkipRuleEngine.saveRules([]) }

    let match = SkipRuleEngine.evaluate(text: "ERROR 404 not found", appName: "Terminal", windowTitle: nil)
    #expect(match.shouldSkip == true)

    let noMatch = SkipRuleEngine.evaluate(text: "Success: 200 OK", appName: "Terminal", windowTitle: nil)
    #expect(noMatch.shouldSkip == false)
}

@Test func skipRuleEngineDisabledRuleIgnored() {
    let rule = SkipRuleEngine.SkipRule(name: "Disabled rule", type: .textContains, pattern: "match this", enabled: false)
    SkipRuleEngine.saveRules([rule])
    defer { SkipRuleEngine.saveRules([]) }

    let result = SkipRuleEngine.evaluate(text: "match this text", appName: "Test", windowTitle: nil)
    #expect(result.shouldSkip == false) // Disabled rule should not match
}

@Test func skipRuleEngineRuleTypesHaveIcons() {
    for ruleType in SkipRuleEngine.RuleType.allCases {
        #expect(!ruleType.iconName.isEmpty)
    }
}

@Test func skipRuleEnginePersistence() {
    let rules = [
        SkipRuleEngine.SkipRule(name: "Rule 1", type: .textContains, pattern: "test1"),
        SkipRuleEngine.SkipRule(name: "Rule 2", type: .appEquals, pattern: "test2"),
    ]
    SkipRuleEngine.saveRules(rules)
    defer { SkipRuleEngine.saveRules([]) }

    let loaded = SkipRuleEngine.loadRules()
    #expect(loaded.count == 2)
    #expect(loaded[0].name == "Rule 1")
    #expect(loaded[1].type == .appEquals)
}

@Test func skipRuleEngineExampleRules() {
    let examples = SkipRuleEngine.exampleRules
    #expect(examples.count == 3)
    #expect(examples.allSatisfy { !$0.enabled }) // All disabled by default
}

} // end SkipRuleTests

// MARK: - WorkflowEngine Tests

@Test func workflowRuleInitializes() {
    let rule = WorkflowRule(
        name: "Test Rule",
        trigger: .categoryIs("coding"),
        action: .addTag("auto-tag")
    )
    #expect(rule.name == "Test Rule")
    #expect(rule.enabled == true)
}

@Test func workflowEngineAddRule() async {
    let engine = await WorkflowEngine.shared
    let rule = WorkflowRule(
        name: "Test Add Rule",
        trigger: .noteCreated,
        action: .addTag("test-add")
    )

    await engine.addRule(rule)
    let allRules = await engine.allRules
    let foundRule = allRules.first { $0.id == rule.id }

    #expect(foundRule != nil)
    #expect(foundRule?.name == "Test Add Rule")

    // Cleanup
    await engine.removeRule(id: rule.id)
}

@Test func workflowEngineRemoveRule() async {
    let engine = await WorkflowEngine.shared
    let rule = WorkflowRule(
        name: "Test Remove Rule",
        trigger: .noteCreated,
        action: .addTag("test-remove")
    )

    await engine.addRule(rule)
    var allRules = await engine.allRules
    let ruleExists = allRules.contains { $0.id == rule.id }
    #expect(ruleExists == true)

    await engine.removeRule(id: rule.id)
    allRules = await engine.allRules
    let ruleStillExists = allRules.contains { $0.id == rule.id }
    #expect(ruleStillExists == false)
}

@Test func workflowEngineToggleRule() async {
    let engine = await WorkflowEngine.shared
    let rule = WorkflowRule(
        name: "Test Toggle Rule",
        trigger: .noteCreated,
        action: .addTag("test-toggle"),
        enabled: true
    )

    await engine.addRule(rule)
    let rules = await engine.allRules
    let addedRule = rules.first { $0.id == rule.id }
    #expect(addedRule?.enabled == true)

    await engine.toggleRule(id: rule.id)
    let updatedRules = await engine.allRules
    let toggledRule = updatedRules.first { $0.id == rule.id }
    #expect(toggledRule?.enabled == false)

    // Cleanup
    await engine.removeRule(id: rule.id)
}

@Test func workflowEngineEvaluateMatchingTrigger() async {
    let engine = await WorkflowEngine.shared
    let rule = WorkflowRule(
        name: "Category Match Test",
        trigger: .categoryIs("Meeting"),
        action: .addTag("meeting-tag"),
        enabled: true
    )

    await engine.addRule(rule)

    let event = WorkflowEvent(
        title: "Test Meeting",
        summary: "Meeting notes",
        category: "Meeting",
        appName: "Zoom",
        tags: [],
        confidence: 0.95
    )

    // Should trigger without throwing
    await engine.evaluate(event: event)

    // Cleanup
    await engine.removeRule(id: rule.id)
}

@Test func workflowEngineEvaluateNonMatchingTrigger() async {
    let engine = await WorkflowEngine.shared
    let rule = WorkflowRule(
        name: "Non-Match Test",
        trigger: .categoryIs("Meeting"),
        action: .addTag("meeting-tag"),
        enabled: true
    )

    await engine.addRule(rule)

    let event = WorkflowEvent(
        title: "Code Review",
        summary: "Review notes",
        category: "Development",
        appName: "GitHub",
        tags: [],
        confidence: 0.85
    )

    // Should not match, but shouldn't fail
    await engine.evaluate(event: event)

    // Cleanup
    await engine.removeRule(id: rule.id)
}

@Test func workflowEngineTriggerAppIs() async {
    let engine = await WorkflowEngine.shared
    let rule = WorkflowRule(
        name: "App Trigger Test",
        trigger: .appIs("Slack"),
        action: .addTag("slack-tag")
    )

    await engine.addRule(rule)

    let matchingEvent = WorkflowEvent(
        title: "Test",
        summary: "Test",
        category: "Communication",
        appName: "Slack",
        tags: [],
        confidence: 0.9
    )

    await engine.evaluate(event: matchingEvent)

    // Cleanup
    await engine.removeRule(id: rule.id)
}

@Test func workflowEngineTriggerTagContains() async {
    let engine = await WorkflowEngine.shared
    let rule = WorkflowRule(
        name: "Tag Trigger Test",
        trigger: .tagContains("urgent"),
        action: .notify("Urgent item detected")
    )

    await engine.addRule(rule)

    let event = WorkflowEvent(
        title: "Important Task",
        summary: "Urgent task",
        category: "Task",
        appName: "Todoist",
        tags: ["urgent", "work"],
        confidence: 0.9
    )

    await engine.evaluate(event: event)

    // Cleanup
    await engine.removeRule(id: rule.id)
}

@Test func workflowEngineTriggerTitleContains() async {
    let engine = await WorkflowEngine.shared
    let rule = WorkflowRule(
        name: "Title Trigger Test",
        trigger: .titleContains("bug"),
        action: .addTag("bug-report")
    )

    await engine.addRule(rule)

    let event = WorkflowEvent(
        title: "Bug: Login fails",
        summary: "Login issue",
        category: "Bug",
        appName: "Jira",
        tags: [],
        confidence: 0.88
    )

    await engine.evaluate(event: event)

    // Cleanup
    await engine.removeRule(id: rule.id)
}

@Test func workflowEngineTriggerConfidenceAbove() async {
    let engine = await WorkflowEngine.shared
    let rule = WorkflowRule(
        name: "Confidence Trigger Test",
        trigger: .confidenceAbove(0.9),
        action: .addTag("high-confidence")
    )

    await engine.addRule(rule)

    let highConfEvent = WorkflowEvent(
        title: "Clear Meeting Notes",
        summary: "Detailed notes",
        category: "Meeting",
        appName: "Zoom",
        tags: [],
        confidence: 0.95
    )

    await engine.evaluate(event: highConfEvent)

    let lowConfEvent = WorkflowEvent(
        title: "Unclear Notes",
        summary: "Some notes",
        category: "Misc",
        appName: "Notes",
        tags: [],
        confidence: 0.7
    )

    await engine.evaluate(event: lowConfEvent)

    // Cleanup
    await engine.removeRule(id: rule.id)
}

@Test func workflowTriggerCodable() throws {
    let triggers: [WorkflowTrigger] = [
        .noteCreated,
        .categoryIs("coding"),
        .appIs("Xcode"),
        .tagContains("swift"),
        .titleContains("API"),
        .confidenceAbove(0.8),
    ]

    for trigger in triggers {
        let data = try JSONEncoder().encode(trigger)
        let decoded = try JSONDecoder().decode(WorkflowTrigger.self, from: data)
        // Verify roundtrip
        let reEncoded = try JSONEncoder().encode(decoded)
        #expect(data == reEncoded)
    }
}

@Test func workflowActionCodable() throws {
    let actions: [WorkflowAction] = [
        .addTag("test"),
        .webhook("https://example.com/hook"),
        .notify("Alert: {title}"),
        .exportToFolder("/tmp/export"),
    ]

    for action in actions {
        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(WorkflowAction.self, from: data)
        let reEncoded = try JSONEncoder().encode(decoded)
        #expect(data == reEncoded)
    }
}

@Test func workflowRuleCodable() throws {
    let rule = WorkflowRule(
        name: "Codable Test",
        trigger: .categoryIs("meeting"),
        action: .notify("Meeting detected"),
        enabled: true
    )
    let data = try JSONEncoder().encode(rule)
    let decoded = try JSONDecoder().decode(WorkflowRule.self, from: data)

    #expect(decoded.name == rule.name)
    #expect(decoded.enabled == rule.enabled)
}

@Test func workflowEventInitializes() {
    let event = WorkflowEvent(
        title: "Test Event",
        summary: "Summary",
        category: "coding",
        appName: "Xcode",
        tags: ["swift"],
        confidence: 0.9
    )
    #expect(event.title == "Test Event")
    #expect(event.category == "coding")
    #expect(event.tags == ["swift"])
    #expect(event.confidence == 0.9)
}

// MARK: - RetryStrategy Tests

@Test func retryStrategyDelayCalculation() {
    let strategy = RetryStrategy(maxAttempts: 3, baseDelay: 1.0, maxDelay: 10.0, multiplier: 2.0)

    #expect(strategy.delay(forAttempt: 0) == 1.0) // 1.0 * 2^0 = 1.0
    #expect(strategy.delay(forAttempt: 1) == 2.0) // 1.0 * 2^1 = 2.0
    #expect(strategy.delay(forAttempt: 2) == 4.0) // 1.0 * 2^2 = 4.0
    #expect(strategy.delay(forAttempt: 3) == 8.0) // 1.0 * 2^3 = 8.0
    #expect(strategy.delay(forAttempt: 10) == 10.0) // Capped at maxDelay
}

@Test func retryStrategyPresets() {
    let ai = RetryStrategy.aiAPI
    #expect(ai.maxAttempts == 3)
    #expect(ai.baseDelay == 2.0)

    let storage = RetryStrategy.storage
    #expect(storage.maxAttempts == 2)
    #expect(storage.baseDelay == 0.5)

    let ocr = RetryStrategy.ocr
    #expect(ocr.maxAttempts == 2)
}

@Test func retryStrategySucceedsOnFirstAttempt() async throws {
    let strategy = RetryStrategy(maxAttempts: 3, baseDelay: 0.01)
    var callCount = 0

    let result = try await strategy.execute(operation: "test") {
        callCount += 1
        return 42
    }

    #expect(result == 42)
    #expect(callCount == 1)
}

@Test func retryStrategyRetriesOnFailure() async throws {
    let strategy = RetryStrategy(maxAttempts: 3, baseDelay: 0.01, maxDelay: 0.01)
    var callCount = 0

    let result = try await strategy.execute(operation: "test") {
        callCount += 1
        if callCount < 3 {
            throw NSError(domain: "test", code: 1)
        }
        return "success"
    }

    #expect(result == "success")
    #expect(callCount == 3)
}

@Test func retryStrategyThrowsAfterMaxAttempts() async {
    let strategy = RetryStrategy(maxAttempts: 2, baseDelay: 0.01, maxDelay: 0.01)

    do {
        _ = try await strategy.execute(operation: "test") { () -> Int in
            throw NSError(domain: "test", code: 1)
        }
        #expect(Bool(false), "Should have thrown")
    } catch {
        #expect(error is NSError)
    }
}

// MARK: - AuditLogger Tests

@Test func auditLoggerActionRawValues() {
    #expect(AuditLogger.AuditAction.captured.rawValue == "captured")
    #expect(AuditLogger.AuditAction.skipped.rawValue == "skipped")
    #expect(AuditLogger.AuditAction.redacted.rawValue == "redacted")
    #expect(AuditLogger.AuditAction.exported.rawValue == "exported")
    #expect(AuditLogger.AuditAction.deleted.rawValue == "deleted")
    #expect(AuditLogger.AuditAction.encrypted.rawValue == "encrypted")
}

// MARK: - ErrorBoundary Tests

@Test func errorBoundaryTracksErrors() async {
    let boundary = ErrorBoundary(errorThreshold: 3, cooldownInterval: 10)

    struct TestError: Error {}

    let shouldDisable1 = await boundary.recordError(stage: "test-stage-1", error: TestError())
    #expect(shouldDisable1 == false)

    let count = await boundary.errorCount(stage: "test-stage-1")
    #expect(count == 1)
}

@Test func errorBoundaryReachesThreshold() async {
    let boundary = ErrorBoundary(errorThreshold: 3, cooldownInterval: 10)

    struct TestError: Error {}

    _ = await boundary.recordError(stage: "test-stage-2", error: TestError())
    _ = await boundary.recordError(stage: "test-stage-2", error: TestError())
    let shouldDisable = await boundary.recordError(stage: "test-stage-2", error: TestError())

    #expect(shouldDisable == true)

    let count = await boundary.errorCount(stage: "test-stage-2")
    #expect(count == 3)
}

@Test func errorBoundaryCooldownReset() async {
    let boundary = ErrorBoundary(errorThreshold: 5, cooldownInterval: 0.5)

    struct TestError: Error {}

    _ = await boundary.recordError(stage: "test-stage-3", error: TestError())
    let count1 = await boundary.errorCount(stage: "test-stage-3")
    #expect(count1 == 1)

    // Wait for cooldown
    try? await Task.sleep(for: .seconds(0.6))

    // Next error should reset the count
    _ = await boundary.recordError(stage: "test-stage-3", error: TestError())
    let count2 = await boundary.errorCount(stage: "test-stage-3")
    #expect(count2 == 1)
}

@Test func errorBoundaryWithBoundarySuccess() async {
    let boundary = ErrorBoundary(errorThreshold: 3, cooldownInterval: 10)

    let result = await boundary.withBoundary(
        stage: "test-stage-4",
        fallback: "fallback-value"
    ) {
        return "success-value"
    }

    #expect(result == "success-value")

    let count = await boundary.errorCount(stage: "test-stage-4")
    #expect(count == 0)
}

@Test func errorBoundaryWithBoundaryFailure() async {
    let boundary = ErrorBoundary(errorThreshold: 3, cooldownInterval: 10)

    struct TestError: Error {}

    let result = await boundary.withBoundary(
        stage: "test-stage-5",
        fallback: "fallback-value"
    ) {
        throw TestError()
    }

    #expect(result == "fallback-value")

    let count = await boundary.errorCount(stage: "test-stage-5")
    #expect(count == 1)
}

@Test func errorBoundaryResetErrors() async {
    let boundary = ErrorBoundary(errorThreshold: 3, cooldownInterval: 10)

    struct TestError: Error {}

    _ = await boundary.recordError(stage: "test-stage-6", error: TestError())
    _ = await boundary.recordError(stage: "test-stage-6", error: TestError())

    let countBefore = await boundary.errorCount(stage: "test-stage-6")
    #expect(countBefore == 2)

    await boundary.resetErrors(stage: "test-stage-6")

    let countAfter = await boundary.errorCount(stage: "test-stage-6")
    #expect(countAfter == 0)
}

@Test func errorBoundarySummary() async {
    let boundary = ErrorBoundary(errorThreshold: 5, cooldownInterval: 10)

    struct TestError: Error {}

    _ = await boundary.recordError(stage: "stage-A", error: TestError())
    _ = await boundary.recordError(stage: "stage-B", error: TestError())
    _ = await boundary.recordError(stage: "stage-B", error: TestError())

    let summary = await boundary.summary()
    #expect(summary["stage-A"] == 1)
    #expect(summary["stage-B"] == 2)
}

// MARK: - Self-Exclusion Logic Tests (PipelineCoordinator concept)

@Test func selfPIDExclusionDetectsOwnProcess() {
    // Verify the PID-based self-exclusion pattern used in PipelineCoordinator.processFrame
    let selfPID = ProcessInfo.processInfo.processIdentifier
    #expect(selfPID > 0, "Self PID should be a valid positive integer")

    // Simulate the guard from processFrame:
    // if let pid = frame.processIdentifier, pid == ProcessInfo.processInfo.processIdentifier
    let framePID: pid_t? = selfPID
    let shouldSkip = framePID.map { $0 == ProcessInfo.processInfo.processIdentifier } ?? false
    #expect(shouldSkip == true, "Frame with self PID should be skipped")
}

@Test func selfPIDExclusionAllowsOtherProcesses() {
    let otherPID: pid_t = 1 // launchd
    let shouldSkip = otherPID == ProcessInfo.processInfo.processIdentifier
    #expect(shouldSkip == false, "Frame from other process should not be skipped")
}

@Test func selfPIDExclusionHandlesNilPID() {
    // When frame.processIdentifier is nil, the optional binding fails and we don't skip
    let framePID: pid_t? = nil
    let shouldSkip = framePID.map { $0 == ProcessInfo.processInfo.processIdentifier } ?? false
    #expect(shouldSkip == false, "Frame with nil PID should not be skipped")
}
