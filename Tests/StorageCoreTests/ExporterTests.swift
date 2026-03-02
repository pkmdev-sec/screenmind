import Foundation
import Testing
@testable import StorageCore
@testable import AIProcessing
import TestUtilities

// MARK: - NotionExporter Tests

@Test func notionExporterInitializesWithValidCredentials() {
    let exporter = NotionExporter(apiToken: "test-token", databaseID: "test-db-id")
    #expect(exporter != nil)
    #expect(exporter?.exporterType == .notion)
}

@Test func notionExporterReturnsNilWithoutToken() {
    let exporter = NotionExporter(apiToken: nil, databaseID: "test-db-id")
    #expect(exporter == nil)
}

@Test func notionExporterReturnsNilWithoutDatabaseID() {
    let exporter = NotionExporter(apiToken: "test-token", databaseID: nil)
    #expect(exporter == nil)
}

@Test func notionExporterReturnsFalseWhenDisabled() async throws {
    // Save original state
    let originalEnabled = UserDefaults.standard.object(forKey: "notionExportEnabled")
    defer {
        if let original = originalEnabled {
            UserDefaults.standard.set(original, forKey: "notionExportEnabled")
        } else {
            UserDefaults.standard.removeObject(forKey: "notionExportEnabled")
        }
    }

    UserDefaults.standard.set(false, forKey: "notionExportEnabled")

    let exporter = NotionExporter(apiToken: "test-token", databaseID: "test-db-id")!
    let note = TestFixtures.makeGeneratedNote()

    let result = try await exporter.export(
        note: note,
        appName: "TestApp",
        windowTitle: "Test Window",
        timestamp: Date()
    )

    #expect(result == false)
}

// MARK: - LogseqExporter Tests

@Test func logseqExporterInitializesWithValidPath() {
    let exporter = LogseqExporter(graphPath: "/tmp/test-logseq")
    #expect(exporter != nil)
    #expect(exporter?.exporterType == .logseq)
}

@Test func logseqExporterReturnsNilWithoutPath() {
    let exporter = LogseqExporter(graphPath: nil)
    #expect(exporter == nil)
}

@Test func logseqExporterReturnsFalseWhenDisabled() async throws {
    let originalEnabled = UserDefaults.standard.object(forKey: "logseqExportEnabled")
    defer {
        if let original = originalEnabled {
            UserDefaults.standard.set(original, forKey: "logseqExportEnabled")
        } else {
            UserDefaults.standard.removeObject(forKey: "logseqExportEnabled")
        }
    }

    UserDefaults.standard.set(false, forKey: "logseqExportEnabled")

    let exporter = LogseqExporter(graphPath: "/tmp/test-logseq")!
    let note = TestFixtures.makeGeneratedNote()

    let result = try await exporter.export(
        note: note,
        appName: "TestApp",
        windowTitle: "Test Window",
        timestamp: Date()
    )

    #expect(result == false)
}

@Test func logseqExporterCreatesValidBlockFormat() async throws {
    let originalEnabled = UserDefaults.standard.object(forKey: "logseqExportEnabled")
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("logseq-test-\(UUID().uuidString)")

    defer {
        if let original = originalEnabled {
            UserDefaults.standard.set(original, forKey: "logseqExportEnabled")
        } else {
            UserDefaults.standard.removeObject(forKey: "logseqExportEnabled")
        }
        try? FileManager.default.removeItem(at: tempDir)
    }

    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    UserDefaults.standard.set(true, forKey: "logseqExportEnabled")

    let exporter = LogseqExporter(graphPath: tempDir.path)!
    let note = TestFixtures.makeGeneratedNote(
        title: "Test Note",
        summary: "Test summary",
        category: .coding,
        tags: ["swift", "test"]
    )

    let result = try await exporter.export(
        note: note,
        appName: "Xcode",
        windowTitle: "Test.swift",
        timestamp: Date()
    )

    #expect(result == true)

    // Verify file was created
    let journalsDir = tempDir.appendingPathComponent("journals")
    let files = try FileManager.default.contentsOfDirectory(atPath: journalsDir.path)
    #expect(files.count == 1)

    // Verify content format
    let fileURL = journalsDir.appendingPathComponent(files[0])
    let content = try String(contentsOf: fileURL, encoding: .utf8)
    #expect(content.contains("- Test Note"))
    #expect(content.contains("category:: coding"))
    #expect(content.contains("app:: Xcode"))
    #expect(content.contains("window:: Test.swift"))
    #expect(content.contains("tags:: #swift, #test"))
    #expect(content.contains("Test summary"))
}

// MARK: - SlackExporter Tests

@Test func slackExporterInitializesWithValidURL() {
    let exporter = SlackExporter(webhookURL: "https://hooks.slack.com/services/TEST")
    #expect(exporter != nil)
    #expect(exporter?.exporterType == .slack)
}

@Test func slackExporterReturnsNilWithoutURL() {
    let exporter = SlackExporter(webhookURL: nil)
    #expect(exporter == nil)
}

@Test func slackExporterReturnsFalseWhenDailySummaryEnabled() async throws {
    let originalDailySummary = UserDefaults.standard.object(forKey: "slackDailySummary")
    defer {
        if let original = originalDailySummary {
            UserDefaults.standard.set(original, forKey: "slackDailySummary")
        } else {
            UserDefaults.standard.removeObject(forKey: "slackDailySummary")
        }
    }

    UserDefaults.standard.set(true, forKey: "slackDailySummary")

    let exporter = SlackExporter(webhookURL: "https://hooks.slack.com/services/TEST")!
    let note = TestFixtures.makeGeneratedNote()

    let result = try await exporter.export(
        note: note,
        appName: "TestApp",
        windowTitle: "Test Window",
        timestamp: Date()
    )

    #expect(result == false)
}

// MARK: - ExporterFactory Tests

@Test func exporterFactoryIncludesNewExporters() {
    let originalNotion = UserDefaults.standard.object(forKey: ExporterType.notion.enabledKey)
    let originalNotionDB = UserDefaults.standard.object(forKey: "notionDatabaseID")
    let originalLogseq = UserDefaults.standard.object(forKey: ExporterType.logseq.enabledKey)
    let originalLogseqPath = UserDefaults.standard.object(forKey: "logseqGraphPath")
    let originalSlack = UserDefaults.standard.object(forKey: ExporterType.slack.enabledKey)
    let originalSlackURL = UserDefaults.standard.object(forKey: "slackWebhookURL")

    defer {
        if let original = originalNotion {
            UserDefaults.standard.set(original, forKey: ExporterType.notion.enabledKey)
        } else {
            UserDefaults.standard.removeObject(forKey: ExporterType.notion.enabledKey)
        }
        if let original = originalNotionDB {
            UserDefaults.standard.set(original, forKey: "notionDatabaseID")
        } else {
            UserDefaults.standard.removeObject(forKey: "notionDatabaseID")
        }
        if let original = originalLogseq {
            UserDefaults.standard.set(original, forKey: ExporterType.logseq.enabledKey)
        } else {
            UserDefaults.standard.removeObject(forKey: ExporterType.logseq.enabledKey)
        }
        if let original = originalLogseqPath {
            UserDefaults.standard.set(original, forKey: "logseqGraphPath")
        } else {
            UserDefaults.standard.removeObject(forKey: "logseqGraphPath")
        }
        if let original = originalSlack {
            UserDefaults.standard.set(original, forKey: ExporterType.slack.enabledKey)
        } else {
            UserDefaults.standard.removeObject(forKey: ExporterType.slack.enabledKey)
        }
        if let original = originalSlackURL {
            UserDefaults.standard.set(original, forKey: "slackWebhookURL")
        } else {
            UserDefaults.standard.removeObject(forKey: "slackWebhookURL")
        }
    }

    // Enable Logseq
    UserDefaults.standard.set(true, forKey: ExporterType.logseq.enabledKey)
    UserDefaults.standard.set("/tmp/test-logseq", forKey: "logseqGraphPath")

    let exporters = ExporterFactory.enabledExporters()
    let hasLogseq = exporters.contains { $0.exporterType == .logseq }
    #expect(hasLogseq)
}

@Test func exporterTypeHasCorrectProperties() {
    #expect(ExporterType.notion.rawValue == "Notion")
    #expect(ExporterType.logseq.rawValue == "Logseq")
    #expect(ExporterType.slack.rawValue == "Slack")

    #expect(!ExporterType.notion.iconName.isEmpty)
    #expect(!ExporterType.logseq.iconName.isEmpty)
    #expect(!ExporterType.slack.iconName.isEmpty)

    #expect(!ExporterType.notion.subtitle.isEmpty)
    #expect(!ExporterType.logseq.subtitle.isEmpty)
    #expect(!ExporterType.slack.subtitle.isEmpty)
}
