import Foundation
import Testing
@testable import Shared

@Test func appConstantsExist() {
    #expect(AppConstants.bundleIdentifier == "com.screenmind.app")
    #expect(!AppConstants.AI.modelName.isEmpty)
    #expect(!AppConstants.Obsidian.defaultVaultPath.isEmpty)
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
