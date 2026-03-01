import Foundation
import AIProcessing
import Shared

/// Exports notes by POSTing JSON to a webhook URL (Zapier, Make.com, custom API).
public struct WebhookExporter: NoteExporter, Sendable {
    public let exporterType: ExporterType = .webhook
    private let webhookURL: String
    private let headers: [String: String]

    public init(webhookURL: String, headers: [String: String] = [:]) {
        self.webhookURL = webhookURL
        self.headers = headers
    }

    public func export(note: GeneratedNote, appName: String, windowTitle: String?, timestamp: Date) async throws -> Bool {
        guard let url = URL(string: webhookURL) else {
            SMLogger.storage.error("Webhook: invalid URL \(webhookURL)")
            throw WebhookError.invalidURL(webhookURL)
        }

        // SSRF protection: block private/internal IPs
        try validateURLSafety(url)

        let payload: [String: Any] = [
            "title": note.title,
            "summary": note.summary,
            "details": note.details,
            "category": note.category.rawValue,
            "tags": note.tags,
            "confidence": note.confidence,
            "obsidian_links": note.obsidianLinks,
            "app_name": appName,
            "window_title": windowTitle ?? "",
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "source": "screenmind"
        ]

        let data = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ScreenMind/1.0", forHTTPHeaderField: "User-Agent")

        // Custom headers (note: can override defaults)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        request.httpBody = data

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw WebhookError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            SMLogger.storage.warning("Webhook failed: \(http.statusCode) for \(note.title)")
            throw WebhookError.httpError(statusCode: http.statusCode)
        }

        SMLogger.storage.info("Webhook delivered: \(note.title) -> \(http.statusCode)")
        return true
    }

    // MARK: - SSRF Protection

    /// Validate that the URL doesn't target private/internal networks.
    private func validateURLSafety(_ url: URL) throws {
        guard let host = url.host?.lowercased() else {
            throw WebhookError.invalidURL(webhookURL)
        }

        // Block localhost
        let blockedHosts = ["localhost", "127.0.0.1", "0.0.0.0", "[::1]"]
        if blockedHosts.contains(host) {
            throw WebhookError.blockedURL("localhost URLs are not allowed for webhooks")
        }

        // Block private IP ranges
        let privatePatterns = [
            "10.",      // 10.0.0.0/8
            "172.16.", "172.17.", "172.18.", "172.19.",  // 172.16.0.0/12
            "172.20.", "172.21.", "172.22.", "172.23.",
            "172.24.", "172.25.", "172.26.", "172.27.",
            "172.28.", "172.29.", "172.30.", "172.31.",
            "192.168.",  // 192.168.0.0/16
            "169.254.",  // Link-local
        ]
        for pattern in privatePatterns {
            if host.hasPrefix(pattern) {
                throw WebhookError.blockedURL("Private IP ranges are not allowed for webhooks")
            }
        }

        // Block cloud metadata endpoints
        if host == "metadata.google.internal" || host == "metadata" {
            throw WebhookError.blockedURL("Cloud metadata endpoints are not allowed")
        }
    }
}

/// Webhook export errors.
public enum WebhookError: Error, LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case httpError(statusCode: Int)
    case blockedURL(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url): return "Invalid webhook URL: \(url)"
        case .invalidResponse: return "Invalid response from webhook"
        case .httpError(let code): return "Webhook returned HTTP \(code)"
        case .blockedURL(let reason): return reason
        }
    }
}
