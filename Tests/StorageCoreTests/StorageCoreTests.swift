import Foundation
import Testing
import SwiftData
@testable import StorageCore
@testable import AIProcessing

// MARK: - NoteModel Tests

@Test func noteModelInitializesWithAllFields() {
    let note = NoteModel(
        title: "Test Note",
        summary: "A test summary",
        details: "Some details",
        category: "coding",
        tags: ["swift", "test"],
        confidence: 0.95,
        appName: "Xcode",
        windowTitle: "MyFile.swift",
        obsidianLinks: ["[[Swift]]", "[[Testing]]"],
        obsidianExported: true,
        redactionCount: 3
    )
    #expect(note.title == "Test Note")
    #expect(note.summary == "A test summary")
    #expect(note.details == "Some details")
    #expect(note.category == "coding")
    #expect(note.tags == ["swift", "test"])
    #expect(note.confidence == 0.95)
    #expect(note.appName == "Xcode")
    #expect(note.windowTitle == "MyFile.swift")
    #expect(note.obsidianLinks == ["[[Swift]]", "[[Testing]]"])
    #expect(note.obsidianExported == true)
    #expect(note.redactionCount == 3)
    #expect(note.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    #expect(note.createdAt.timeIntervalSinceNow < 1)
}

@Test func noteModelInitializesWithDefaults() {
    let note = NoteModel(
        title: "Simple Note",
        summary: "Summary",
        details: "Details",
        category: "other",
        tags: [],
        confidence: 0.5,
        appName: "TestApp"
    )
    #expect(note.windowTitle == nil)
    #expect(note.obsidianLinks == [])
    #expect(note.obsidianExported == false)
    #expect(note.redactionCount == 0)
}

// MARK: - ScreenshotModel Tests

@Test func screenshotModelInitializes() {
    let screenshot = ScreenshotModel(
        filePath: "/path/to/screenshot.jpg",
        hash: 12345678,
        width: 1920,
        height: 1080,
        capturedAt: Date(timeIntervalSince1970: 1000)
    )
    #expect(screenshot.filePath == "/path/to/screenshot.jpg")
    #expect(screenshot.hash == 12345678)
    #expect(screenshot.width == 1920)
    #expect(screenshot.height == 1080)
    #expect(screenshot.capturedAt == Date(timeIntervalSince1970: 1000))
    #expect(screenshot.note == nil)
}

// MARK: - AppContextModel Tests

@Test func appContextModelInitializes() {
    let context = AppContextModel(
        appName: "Xcode",
        bundleIdentifier: "com.apple.dt.Xcode"
    )
    #expect(context.appName == "Xcode")
    #expect(context.bundleIdentifier == "com.apple.dt.Xcode")
    #expect(context.totalNotes == 0)
    #expect(context.notes.isEmpty)
    #expect(context.lastSeenAt.timeIntervalSinceNow < 1)
}

// MARK: - StorageActor Tests

@Test func storageActorInitializesWithContainer() async throws {
    let schema = Schema([NoteModel.self, ScreenshotModel.self, AppContextModel.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: config)
    let actor = StorageActor(modelContainer: container)
    _ = actor
}

@Test func storageActorSaveAndFetchNote() async throws {
    let schema = Schema([NoteModel.self, ScreenshotModel.self, AppContextModel.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: config)
    let actor = StorageActor(modelContainer: container)

    let generatedNote = GeneratedNote(
        title: "Test Note",
        summary: "Summary",
        details: "Details",
        category: .coding,
        tags: ["swift"],
        confidence: 0.9,
        skip: false,
        obsidianLinks: []
    )

    let savedNote = try await actor.saveNote(
        generatedNote,
        appName: "Xcode",
        windowTitle: "Test.swift",
        screenshotPath: nil,
        hash: 0,
        imageWidth: 0,
        imageHeight: 0,
        timestamp: Date(),
        redactionCount: 0
    )

    #expect(savedNote.title == "Test Note")
    #expect(savedNote.appName == "Xcode")

    let todayNotes = try await actor.fetchTodayNotes()
    #expect(todayNotes.count == 1)
    #expect(todayNotes.first?.title == "Test Note")
}

@Test func storageActorSearchNotes() async throws {
    let schema = Schema([NoteModel.self, ScreenshotModel.self, AppContextModel.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: config)
    let actor = StorageActor(modelContainer: container)

    let note1 = GeneratedNote(
        title: "Swift Debugging",
        summary: "Fixing bugs in Swift code",
        details: "Details about debugging",
        category: .coding,
        tags: ["swift"],
        confidence: 0.9,
        skip: false,
        obsidianLinks: []
    )

    let note2 = GeneratedNote(
        title: "Team Meeting",
        summary: "Discussed project roadmap",
        details: "Meeting notes",
        category: .meeting,
        tags: ["team"],
        confidence: 0.8,
        skip: false,
        obsidianLinks: []
    )

    _ = try await actor.saveNote(note1, appName: "Xcode", windowTitle: nil, screenshotPath: nil, hash: 0, imageWidth: 0, imageHeight: 0, timestamp: Date(), redactionCount: 0)
    _ = try await actor.saveNote(note2, appName: "Zoom", windowTitle: nil, screenshotPath: nil, hash: 0, imageWidth: 0, imageHeight: 0, timestamp: Date(), redactionCount: 0)

    let results = try await actor.searchNotes(query: "Swift")
    #expect(results.count == 1)
    #expect(results.first?.title == "Swift Debugging")

    let bugResults = try await actor.searchNotes(query: "bugs")
    #expect(bugResults.count == 1)
    #expect(bugResults.first?.title == "Swift Debugging")
}

@Test func storageActorNoteCount() async throws {
    let schema = Schema([NoteModel.self, ScreenshotModel.self, AppContextModel.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: config)
    let actor = StorageActor(modelContainer: container)

    let count = try await actor.noteCount()
    #expect(count == 0)

    let note = GeneratedNote(
        title: "Test",
        summary: "Summary",
        details: "",
        category: .other,
        tags: [],
        confidence: 0.5,
        skip: false,
        obsidianLinks: []
    )

    _ = try await actor.saveNote(note, appName: "Test", windowTitle: nil, screenshotPath: nil, hash: 0, imageWidth: 0, imageHeight: 0, timestamp: Date(), redactionCount: 0)

    let newCount = try await actor.noteCount()
    #expect(newCount == 1)
}

@Test func storageActorAdvancedSearchWithFilters() async throws {
    let schema = Schema([NoteModel.self, ScreenshotModel.self, AppContextModel.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: config)
    let actor = StorageActor(modelContainer: container)

    let note1 = GeneratedNote(
        title: "Coding Session",
        summary: "Working on feature",
        details: "",
        category: .coding,
        tags: [],
        confidence: 0.9,
        skip: false,
        obsidianLinks: []
    )

    let note2 = GeneratedNote(
        title: "Team Meeting",
        summary: "Weekly sync",
        details: "",
        category: .meeting,
        tags: [],
        confidence: 0.8,
        skip: false,
        obsidianLinks: []
    )

    _ = try await actor.saveNote(note1, appName: "Xcode", windowTitle: nil, screenshotPath: nil, hash: 0, imageWidth: 0, imageHeight: 0, timestamp: Date(), redactionCount: 0)
    _ = try await actor.saveNote(note2, appName: "Zoom", windowTitle: nil, screenshotPath: nil, hash: 0, imageWidth: 0, imageHeight: 0, timestamp: Date(), redactionCount: 0)

    let codingResults = try await actor.searchNotes(query: "", category: "coding", from: nil, to: nil, appName: nil)
    #expect(codingResults.count == 1)
    #expect(codingResults.first?.category == "coding")
}

// MARK: - FrontmatterBuilder Tests

@Test func frontmatterBuilderGeneratesYAML() {
    let yaml = FrontmatterBuilder.build(
        title: "Test Note",
        category: "coding",
        tags: ["swift"],
        appName: "Xcode",
        windowTitle: "MyFile.swift",
        confidence: 0.9,
        createdAt: Date(timeIntervalSince1970: 0)
    )
    #expect(yaml.hasPrefix("---"))
    #expect(yaml.hasSuffix("---"))
    #expect(yaml.contains("title: \"Test Note\""))
    #expect(yaml.contains("category: coding"))
    #expect(yaml.contains("app: Xcode"))
    #expect(yaml.contains("window: \"MyFile.swift\""))
    #expect(yaml.contains("confidence: 0.90"))
    #expect(yaml.contains("tags:"))
    #expect(yaml.contains("  - swift"))
}

@Test func frontmatterBuilderEscapesSpecialCharacters() {
    let yaml = FrontmatterBuilder.build(
        title: "Note with \"quotes\"",
        category: "other",
        tags: ["test"],
        appName: "App",
        windowTitle: "Window with \"quotes\" too",
        confidence: 0.5,
        createdAt: Date()
    )
    #expect(yaml.contains("title: \"Note with \\\"quotes\\\"\""))
    #expect(yaml.contains("window: \"Window with \\\"quotes\\\" too\""))
}

@Test func frontmatterBuilderWithoutWindowTitle() {
    let yaml = FrontmatterBuilder.build(
        title: "Test",
        category: "other",
        tags: [],
        appName: "App",
        windowTitle: nil,
        confidence: 0.5,
        createdAt: Date()
    )
    #expect(!yaml.contains("window:"))
}

@Test func frontmatterBuilderWithMultipleTags() {
    let yaml = FrontmatterBuilder.build(
        title: "Test",
        category: "coding",
        tags: ["swift", "testing", "ios"],
        appName: "Xcode",
        windowTitle: nil,
        confidence: 0.8,
        createdAt: Date()
    )
    #expect(yaml.contains("tags:"))
    #expect(yaml.contains("  - swift"))
    #expect(yaml.contains("  - testing"))
    #expect(yaml.contains("  - ios"))
}

// MARK: - VaultManager Tests

@Test func vaultManagerPaths() {
    let vault = VaultManager(vaultPath: "/tmp/test-vault")
    #expect(vault.screenMindRoot.lastPathComponent == "ScreenMind")
}

@Test func vaultManagerDailyFolder() {
    let vault = VaultManager(vaultPath: "/tmp/test-vault")
    let date = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC
    let folder = vault.dailyFolder(for: date)
    #expect(folder.lastPathComponent.hasPrefix("2024"))
}

// MARK: - ExporterFactory Tests

@Test func exporterFactoryBuildsEnabledExporters() {
    // Save original state
    let originalObsidian = UserDefaults.standard.object(forKey: ExporterType.obsidian.enabledKey)
    let originalJSON = UserDefaults.standard.object(forKey: ExporterType.json.enabledKey)

    defer {
        // Restore original state
        if let original = originalObsidian {
            UserDefaults.standard.set(original, forKey: ExporterType.obsidian.enabledKey)
        } else {
            UserDefaults.standard.removeObject(forKey: ExporterType.obsidian.enabledKey)
        }
        if let original = originalJSON {
            UserDefaults.standard.set(original, forKey: ExporterType.json.enabledKey)
        } else {
            UserDefaults.standard.removeObject(forKey: ExporterType.json.enabledKey)
        }
    }

    // Test: Obsidian enabled by default (no key set)
    UserDefaults.standard.removeObject(forKey: ExporterType.obsidian.enabledKey)
    UserDefaults.standard.set(false, forKey: ExporterType.json.enabledKey)

    let exporters1 = ExporterFactory.enabledExporters()
    #expect(exporters1.count == 1)
    #expect(exporters1.first?.exporterType == .obsidian)

    // Test: Enable JSON exporter
    UserDefaults.standard.set(true, forKey: ExporterType.json.enabledKey)
    UserDefaults.standard.set("/tmp/test-json", forKey: "exportJsonPath")

    let exporters2 = ExporterFactory.enabledExporters()
    #expect(exporters2.count == 2)
    #expect(exporters2.contains { $0.exporterType == .json })
}

@Test func exporterTypeProperties() {
    #expect(ExporterType.obsidian.rawValue == "Obsidian Markdown")
    #expect(ExporterType.json.rawValue == "JSON")
    #expect(ExporterType.flatMarkdown.rawValue == "Flat Markdown")
    #expect(ExporterType.webhook.rawValue == "Webhook")

    #expect(!ExporterType.obsidian.iconName.isEmpty)
    #expect(!ExporterType.obsidian.subtitle.isEmpty)
}
