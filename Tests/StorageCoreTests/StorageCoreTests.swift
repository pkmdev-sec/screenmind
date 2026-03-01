import Foundation
import Testing
import SwiftData
@testable import StorageCore

@Test func noteModelInitializes() {
    let note = NoteModel(
        title: "Test Note",
        summary: "A test summary",
        details: "Some details",
        category: "coding",
        tags: ["swift", "test"],
        confidence: 0.95,
        appName: "Xcode"
    )
    #expect(note.title == "Test Note")
    #expect(note.category == "coding")
    #expect(note.tags.count == 2)
    #expect(!note.obsidianExported)
}

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
}

@Test func vaultManagerPaths() {
    let vault = VaultManager(vaultPath: "/tmp/test-vault")
    #expect(vault.screenMindRoot.lastPathComponent == "ScreenMind")
}

@Test func storageActorInitializesWithContainer() async throws {
    let schema = Schema([NoteModel.self, ScreenshotModel.self, AppContextModel.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: config)
    let actor = StorageActor(modelContainer: container)
    _ = actor
}
