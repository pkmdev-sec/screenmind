import Foundation
import AIProcessing
import Shared

/// Exports notes to Slack via Incoming Webhook with Block Kit formatting.
public struct SlackExporter: NoteExporter, Sendable {
    public let exporterType: ExporterType = .slack

    private let webhookURL: String

    public init?(webhookURL: String? = nil) {
        if let webhookURL = webhookURL {
            self.webhookURL = webhookURL
        } else if let storedURL = UserDefaults.standard.string(forKey: "slackWebhookURL"), !storedURL.isEmpty {
            self.webhookURL = storedURL
        } else {
            return nil
        }
    }

    public func export(
        note: GeneratedNote,
        appName: String,
        windowTitle: String?,
        timestamp: Date
    ) async throws -> Bool {
        // Don't export individual notes if daily summary is enabled
        // (daily summary will be handled separately)
        if UserDefaults.standard.bool(forKey: "slackDailySummary") {
            return false
        }

        guard let url = URL(string: webhookURL) else {
            SMLogger.storage.error("Slack: invalid webhook URL")
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build Block Kit message
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        var fields: [[String: Any]] = [
            [
                "type": "mrkdwn",
                "text": "*Category:*\n\(note.category.rawValue)"
            ],
            [
                "type": "mrkdwn",
                "text": "*App:*\n\(appName)"
            ]
        ]

        if let window = windowTitle {
            fields.append([
                "type": "mrkdwn",
                "text": "*Window:*\n\(window)"
            ])
        }

        if !note.tags.isEmpty {
            fields.append([
                "type": "mrkdwn",
                "text": "*Tags:*\n\(note.tags.joined(separator: ", "))"
            ])
        }

        let blocks: [[String: Any]] = [
            [
                "type": "header",
                "text": [
                    "type": "plain_text",
                    "text": note.title
                ]
            ],
            [
                "type": "section",
                "text": [
                    "type": "mrkdwn",
                    "text": note.summary
                ]
            ],
            [
                "type": "section",
                "fields": fields
            ],
            [
                "type": "context",
                "elements": [
                    [
                        "type": "mrkdwn",
                        "text": "📸 ScreenMind • \(dateFormatter.string(from: timestamp))"
                    ]
                ]
            ]
        ]

        let body: [String: Any] = ["blocks": blocks]
        let data = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = data

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                SMLogger.storage.error("Slack: invalid response")
                return false
            }

            guard (200..<300).contains(http.statusCode) else {
                SMLogger.storage.warning("Slack export failed: \(http.statusCode) for '\(note.title)'")
                return false
            }

            SMLogger.storage.info("Slack exported: '\(note.title)'")
            return true
        } catch {
            SMLogger.storage.error("Slack export error: \(error.localizedDescription)")
            return false
        }
    }
}
