import Foundation
import Shared

/// Creates GitHub issues from notes via GitHub REST API.
public actor GitHubIntegration {
    public static let shared = GitHubIntegration()

    private init() {}

    /// Create a GitHub issue from note data.
    /// - Parameters:
    ///   - title: Issue title
    ///   - summary: Issue summary
    ///   - details: Issue details
    ///   - category: Note category for labels
    ///   - tags: Additional tags for labels
    ///   - repo: Repository in format "owner/repo"
    ///   - appName: App name for context
    ///   - windowTitle: Window title for context
    /// - Returns: Issue URL if successful, nil otherwise
    public func createIssue(
        title: String,
        summary: String,
        details: String,
        category: String,
        tags: [String],
        repo: String,
        appName: String,
        windowTitle: String?
    ) async -> String? {
        guard UserDefaults.standard.bool(forKey: "githubEnabled") else {
            return nil
        }

        guard let token = try? KeychainManager.retrieve(key: "com.screenmind.github-pat"), !token.isEmpty else {
            SMLogger.system.error("GitHub: PAT not found in Keychain")
            return nil
        }

        // Validate repo format
        let parts = repo.split(separator: "/")
        guard parts.count == 2 else {
            SMLogger.system.error("GitHub: invalid repo format '\(repo)'. Expected 'owner/repo'")
            return nil
        }

        let url = URL(string: "https://api.github.com/repos/\(repo)/issues")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ScreenMind/1.0", forHTTPHeaderField: "User-Agent")

        // Build issue body with context
        var body = summary + "\n\n"
        if !details.isEmpty {
            body += "## Details\n\n" + details + "\n\n"
        }
        body += "---\n\n"
        body += "**Context:**\n"
        body += "- App: \(appName)\n"
        if let window = windowTitle {
            body += "- Window: \(window)\n"
        }
        body += "- Captured: \(ISO8601DateFormatter().string(from: Date()))\n"
        body += "\n*Created by [ScreenMind](https://github.com/pumaurya/screenmind)*"

        // Map category to label
        let labels = [category] + tags

        let payload: [String: Any] = [
            "title": title,
            "body": body,
            "labels": labels
        ]

        do {
            let data = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = data

            let (responseData, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                SMLogger.system.error("GitHub: invalid response")
                return nil
            }

            guard (200..<300).contains(http.statusCode) else {
                SMLogger.system.warning("GitHub issue creation failed: \(http.statusCode)")
                return nil
            }

            // Parse response to get issue URL
            if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
               let htmlURL = json["html_url"] as? String {
                SMLogger.system.info("GitHub issue created: \(htmlURL)")
                return htmlURL
            }

            return nil
        } catch {
            SMLogger.system.error("GitHub error: \(error.localizedDescription)")
            return nil
        }
    }
}
