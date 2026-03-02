import Foundation
import Testing
@testable import SystemIntegration
@testable import AIProcessing

// MARK: - GitHubIntegration Tests

@Test func githubIntegrationReturnsNilWhenDisabled() async {
    let integration = await GitHubIntegration.shared

    let originalEnabled = UserDefaults.standard.object(forKey: "githubEnabled")
    defer {
        if let original = originalEnabled {
            UserDefaults.standard.set(original, forKey: "githubEnabled")
        } else {
            UserDefaults.standard.removeObject(forKey: "githubEnabled")
        }
    }

    UserDefaults.standard.set(false, forKey: "githubEnabled")

    let result = await integration.createIssue(
        title: "Test Issue",
        summary: "Summary",
        details: "Details",
        category: "coding",
        tags: ["test"],
        repo: "owner/repo",
        appName: "TestApp",
        windowTitle: nil
    )

    #expect(result == nil)
}

@Test func githubIntegrationReturnsNilWithoutPAT() async {
    let integration = await GitHubIntegration.shared

    let originalEnabled = UserDefaults.standard.object(forKey: "githubEnabled")
    defer {
        if let original = originalEnabled {
            UserDefaults.standard.set(original, forKey: "githubEnabled")
        } else {
            UserDefaults.standard.removeObject(forKey: "githubEnabled")
        }
    }

    UserDefaults.standard.set(true, forKey: "githubEnabled")

    let result = await integration.createIssue(
        title: "Test Issue",
        summary: "Summary",
        details: "Details",
        category: "coding",
        tags: ["test"],
        repo: "owner/repo",
        appName: "TestApp",
        windowTitle: nil
    )

    // Should return nil when no PAT is configured
    #expect(result == nil)
}

// MARK: - TodoistIntegration Tests

@Test func todoistIntegrationReturnsZeroWhenDisabled() async {
    let integration = await TodoistIntegration.shared

    let originalEnabled = UserDefaults.standard.object(forKey: "todoistEnabled")
    defer {
        if let original = originalEnabled {
            UserDefaults.standard.set(original, forKey: "todoistEnabled")
        } else {
            UserDefaults.standard.removeObject(forKey: "todoistEnabled")
        }
    }

    UserDefaults.standard.set(false, forKey: "todoistEnabled")

    let count = await integration.createTasks(
        title: "Test",
        summary: "TODO: Follow up",
        details: "FIXME: Update docs",
        tags: ["test"],
        appName: "TestApp"
    )
    #expect(count == 0)
}

@Test func todoistIntegrationReturnsZeroWithoutToken() async {
    let integration = await TodoistIntegration.shared

    let originalEnabled = UserDefaults.standard.object(forKey: "todoistEnabled")
    defer {
        if let original = originalEnabled {
            UserDefaults.standard.set(original, forKey: "todoistEnabled")
        } else {
            UserDefaults.standard.removeObject(forKey: "todoistEnabled")
        }
    }

    UserDefaults.standard.set(true, forKey: "todoistEnabled")

    let count = await integration.createTasks(
        title: "Meeting Notes",
        summary: "TODO: Test task",
        details: "",
        tags: [],
        appName: "TestApp"
    )

    // Should return 0 when no token is configured
    #expect(count == 0)
}
