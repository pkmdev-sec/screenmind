import Foundation
import Shared

/// Extracts action items from notes and creates Todoist tasks.
public actor TodoistIntegration {
    public static let shared = TodoistIntegration()

    private init() {}

    /// Extract action items from note text using regex patterns.
    private func extractActionItems(from text: String) -> [String] {
        var items: [String] = []

        // Patterns to detect action items
        let patterns = [
            #"TODO:\s*(.+?)(?:\n|$)"#,
            #"FIXME:\s*(.+?)(?:\n|$)"#,
            #"need to\s+(.+?)(?:\.|,|\n|$)"#,
            #"should\s+(.+?)(?:\.|,|\n|$)"#,
            #"must\s+(.+?)(?:\.|,|\n|$)"#,
            #"remember to\s+(.+?)(?:\.|,|\n|$)"#,
            #"don't forget to\s+(.+?)(?:\.|,|\n|$)"#,
            #"\[ \]\s*(.+?)(?:\n|$)"#  // Markdown checkbox
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }

            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if match.numberOfRanges > 1,
                   let range = Range(match.range(at: 1), in: text) {
                    let item = String(text[range]).trimmingCharacters(in: .whitespaces)
                    if !item.isEmpty && item.count > 5 {  // Filter out very short items
                        items.append(item)
                    }
                }
            }
        }

        return Array(Set(items))  // Remove duplicates
    }

    /// Create Todoist tasks from note data.
    /// - Parameters:
    ///   - title: Note title
    ///   - summary: Note summary
    ///   - details: Note details
    ///   - tags: Tags to apply as labels
    ///   - appName: App name for task description context
    /// - Returns: Number of tasks created
    public func createTasks(
        title: String,
        summary: String,
        details: String,
        tags: [String],
        appName: String
    ) async -> Int {
        guard UserDefaults.standard.bool(forKey: "todoistEnabled") else {
            return 0
        }

        guard let token = try? KeychainManager.retrieve(key: "com.screenmind.todoist-api-token"), !token.isEmpty else {
            SMLogger.system.error("Todoist: API token not found in Keychain")
            return 0
        }

        // Extract action items from note content
        let allText = title + "\n" + summary + "\n" + details
        let actionItems = extractActionItems(from: allText)

        guard !actionItems.isEmpty else {
            return 0
        }

        let projectID = UserDefaults.standard.string(forKey: "todoistProjectID")
        var createdCount = 0

        for item in actionItems {
            if await createTask(
                content: item,
                description: "From \(appName): \(title)",
                projectID: projectID,
                labels: tags,
                token: token
            ) {
                createdCount += 1
            }
        }

        if createdCount > 0 {
            SMLogger.system.info("Todoist: created \(createdCount) tasks from '\(title)'")
        }

        return createdCount
    }

    /// Create a single Todoist task via REST API v2.
    private func createTask(
        content: String,
        description: String,
        projectID: String?,
        labels: [String],
        token: String
    ) async -> Bool {
        let url = URL(string: "https://api.todoist.com/rest/v2/tasks")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var payload: [String: Any] = [
            "content": content,
            "description": description
        ]

        if let projectID = projectID, !projectID.isEmpty {
            payload["project_id"] = projectID
        }

        if !labels.isEmpty {
            payload["labels"] = labels
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = data

            let (_, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                return false
            }

            if (200..<300).contains(http.statusCode) {
                return true
            } else {
                SMLogger.system.warning("Todoist task creation failed: \(http.statusCode)")
                return false
            }
        } catch {
            SMLogger.system.error("Todoist error: \(error.localizedDescription)")
            return false
        }
    }
}
