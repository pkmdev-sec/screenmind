import Foundation
import Testing
@testable import Shared

// MARK: - AppConstants Tests

@Test func appConstantsExist() {
    #expect(AppConstants.bundleIdentifier == "com.screenmind.app")
    #expect(!AppConstants.AI.modelName.isEmpty)
    #expect(!AppConstants.Obsidian.defaultVaultPath.isEmpty)
}

// MARK: - Date Extension Tests

@Test func dateExtensions() {
    let date = Date()
    #expect(!date.dateFolderName.isEmpty)
    #expect(!date.iso8601String.isEmpty)
}

@Test func dateFolderNameFormat() {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone.current

    let date = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC
    let folderName = date.dateFolderName

    // Should be in YYYY-MM-DD format
    #expect(folderName.count == 10)
    #expect(folderName.contains("-"))
}

@Test func iso8601StringFormat() {
    let date = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC
    let iso = date.iso8601String

    #expect(iso.contains("2024"))
    #expect(iso.contains("T")) // ISO 8601 separator
}

@Test func relativeStringNotEmpty() {
    let date = Date()
    let relative = date.relativeString
    #expect(!relative.isEmpty)
}

@Test func relativeStringForPastDate() {
    let pastDate = Date(timeIntervalSinceNow: -3600) // 1 hour ago
    let relative = pastDate.relativeString
    #expect(relative.contains("ago") || relative.contains("hr"))
}

// MARK: - String Extension Tests

@Test func stringExtensions() {
    #expect("Hello World!".safeFilename == "hello-world")
    #expect("My Tag".obsidianTag == "my-tag")
    #expect("Short".truncated(to: 10) == "Short")
    #expect("Very Long String".truncated(to: 8) == "Very Lo…")
}

@Test func safeFilenameRemovesSpecialCharacters() {
    // The safeFilename extension removes special chars, lowercases, and replaces spaces with hyphens
    #expect("file@name#test.txt".safeFilename == "filenametesttxt")
    #expect("UPPERCASE".safeFilename == "uppercase")
    // Multiple spaces become multiple hyphens (each space is replaced)
    #expect("Multiple   Spaces".safeFilename == "multiple---spaces")
}

@Test func safeFilenameHandlesEdgeCases() {
    #expect("".safeFilename == "")
    #expect("   ".safeFilename == "")
    #expect("123".safeFilename == "123")
    #expect("a-b_c".safeFilename == "a-b_c")
}

@Test func obsidianTagFormat() {
    #expect("Coding Project".obsidianTag == "coding-project")
    #expect("swift-lang".obsidianTag == "swift-lang")
    #expect("TAG@#$%".obsidianTag == "tag")
}

@Test func obsidianTagRemovesInvalidCharacters() {
    #expect("tag!@#$%^&*()".obsidianTag == "tag")
    #expect("multi word tag".obsidianTag == "multi-word-tag")
}

@Test func truncatedPreservesShortStrings() {
    #expect("abc".truncated(to: 10) == "abc")
    #expect("".truncated(to: 5) == "")
}

@Test func truncatedAddsEllipsis() {
    let longString = "This is a very long string that needs truncation"
    let truncated = longString.truncated(to: 20)

    #expect(truncated.count <= 20)
    #expect(truncated.hasSuffix("…"))
    #expect(truncated.count == 20)
}

@Test func truncatedHandlesExactLength() {
    let text = "Exactly10c"
    #expect(text.truncated(to: 10) == text)
}
