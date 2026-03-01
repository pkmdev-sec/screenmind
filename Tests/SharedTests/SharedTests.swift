import Foundation
import Testing
@testable import Shared

@Test func appConstantsExist() {
    #expect(AppConstants.bundleIdentifier == "com.screenmind")
    #expect(AppConstants.AI.modelName == "claude-sonnet-4-6")
    #expect(AppConstants.Obsidian.defaultVaultPath == "~/Desktop/pgm-dev-dash-notes")
}

@Test func dateExtensions() {
    let date = Date()
    #expect(!date.dateFolderName.isEmpty)
    #expect(!date.iso8601String.isEmpty)
}

@Test func stringExtensions() {
    #expect("Hello World!".safeFilename == "hello-world")
    #expect("My Tag".obsidianTag == "my-tag")
    #expect("Short".truncated(to: 10) == "Short")
    #expect("Very Long String".truncated(to: 8) == "Very Lo…")
}
