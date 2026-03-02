import Foundation
import AIProcessing
import Shared

/// Exports notes to Notion database via Notion API.
public struct NotionExporter: NoteExporter, Sendable {
    public let exporterType: ExporterType = .notion

    private let apiToken: String
    private let databaseID: String

    public init?(apiToken: String? = nil, databaseID: String? = nil) {
        // Try provided values, then Keychain, then UserDefaults
        let token: String
        if let apiToken = apiToken {
            token = apiToken
        } else if let keychainToken = try? KeychainManager.retrieve(key: "com.screenmind.notion-api-token"), !keychainToken.isEmpty {
            token = keychainToken
        } else {
            return nil
        }

        let dbID: String
        if let databaseID = databaseID {
            dbID = databaseID
        } else if let storedID = UserDefaults.standard.string(forKey: "notionDatabaseID"), !storedID.isEmpty {
            dbID = storedID
        } else {
            return nil
        }

        self.apiToken = token
        self.databaseID = dbID
    }

    public func export(
        note: GeneratedNote,
        appName: String,
        windowTitle: String?,
        timestamp: Date
    ) async throws -> Bool {
        guard UserDefaults.standard.bool(forKey: "notionExportEnabled") else {
            return false
        }

        let url = URL(string: "https://api.notion.com/v1/pages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")

        // Build Notion page properties
        let properties: [String: Any] = [
            "title": [
                "title": [
                    ["text": ["content": note.title]]
                ]
            ],
            "summary": [
                "rich_text": [
                    ["text": ["content": note.summary]]
                ]
            ],
            "category": [
                "select": ["name": note.category.rawValue]
            ],
            "tags": [
                "multi_select": note.tags.map { ["name": $0] }
            ],
            "app": [
                "rich_text": [
                    ["text": ["content": appName]]
                ]
            ],
            "date": [
                "date": [
                    "start": ISO8601DateFormatter().string(from: timestamp)
                ]
            ]
        ]

        let body: [String: Any] = [
            "parent": ["database_id": databaseID],
            "properties": properties,
            "children": [
                [
                    "object": "block",
                    "type": "paragraph",
                    "paragraph": [
                        "rich_text": [
                            ["type": "text", "text": ["content": note.details]]
                        ]
                    ]
                ]
            ]
        ]

        let data = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = data

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                SMLogger.storage.error("Notion: invalid response")
                return false
            }

            guard (200..<300).contains(http.statusCode) else {
                SMLogger.storage.warning("Notion export failed: \(http.statusCode) for '\(note.title)'")
                return false
            }

            SMLogger.storage.info("Notion exported: '\(note.title)'")
            return true
        } catch {
            SMLogger.storage.error("Notion export error: \(error.localizedDescription)")
            return false
        }
    }
}
