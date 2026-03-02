import Foundation
import AIProcessing

/// Protocol for note export destinations.
public protocol NoteExporter: Sendable {
    /// Unique identifier for this exporter type.
    var exporterType: ExporterType { get }

    /// Export a generated note. Returns true on success.
    func export(
        note: GeneratedNote,
        appName: String,
        windowTitle: String?,
        timestamp: Date
    ) async throws -> Bool
}

/// Supported exporter types.
public enum ExporterType: String, CaseIterable, Sendable, Codable {
    case obsidian = "Obsidian Markdown"
    case json = "JSON"
    case flatMarkdown = "Flat Markdown"
    case webhook = "Webhook"
    case notion = "Notion"
    case logseq = "Logseq"
    case slack = "Slack"

    /// SF Symbol icon.
    public var iconName: String {
        switch self {
        case .obsidian: return "book.closed.fill"
        case .json: return "curlybraces"
        case .flatMarkdown: return "doc.text"
        case .webhook: return "arrow.up.forward.app"
        case .notion: return "note.text"
        case .logseq: return "square.stack.3d.up"
        case .slack: return "bubble.left.and.bubble.right"
        }
    }

    /// Short description.
    public var subtitle: String {
        switch self {
        case .obsidian: return "Daily folders with frontmatter and wiki-links"
        case .json: return "One JSON file per note for data pipelines"
        case .flatMarkdown: return "Simple .md files without vault structure"
        case .webhook: return "POST note data to a URL"
        case .notion: return "Export to Notion database via API"
        case .logseq: return "Logseq journal format with block properties"
        case .slack: return "Send note summaries to Slack channel"
        }
    }

    /// UserDefaults key for enabled state.
    public var enabledKey: String {
        "exporter_\(rawValue)_enabled"
    }
}

/// Factory that builds the set of enabled exporters.
public enum ExporterFactory {

    /// Build all currently enabled exporters.
    public static func enabledExporters() -> [any NoteExporter] {
        var exporters: [any NoteExporter] = []

        // Obsidian (enabled by default)
        if UserDefaults.standard.object(forKey: ExporterType.obsidian.enabledKey) == nil ||
           UserDefaults.standard.bool(forKey: ExporterType.obsidian.enabledKey) {
            exporters.append(ObsidianExporter())
        }

        if UserDefaults.standard.bool(forKey: ExporterType.json.enabledKey) {
            let path = UserDefaults.standard.string(forKey: "exportJsonPath") ?? defaultJSONPath()
            exporters.append(JSONExporter(outputDirectory: path))
        }

        if UserDefaults.standard.bool(forKey: ExporterType.flatMarkdown.enabledKey) {
            let path = UserDefaults.standard.string(forKey: "exportMarkdownPath") ?? defaultMarkdownPath()
            exporters.append(FlatMarkdownExporter(outputDirectory: path))
        }

        if UserDefaults.standard.bool(forKey: ExporterType.webhook.enabledKey) {
            if let url = UserDefaults.standard.string(forKey: "exportWebhookURL"), !url.isEmpty {
                let headers = UserDefaults.standard.dictionary(forKey: "exportWebhookHeaders") as? [String: String] ?? [:]
                exporters.append(WebhookExporter(webhookURL: url, headers: headers))
            }
        }

        if UserDefaults.standard.bool(forKey: ExporterType.notion.enabledKey) {
            if let exporter = NotionExporter() {
                exporters.append(exporter)
            }
        }

        if UserDefaults.standard.bool(forKey: ExporterType.logseq.enabledKey) {
            if let exporter = LogseqExporter() {
                exporters.append(exporter)
            }
        }

        if UserDefaults.standard.bool(forKey: ExporterType.slack.enabledKey) {
            if let exporter = SlackExporter() {
                exporters.append(exporter)
            }
        }

        return exporters
    }

    private static func defaultJSONPath() -> String {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        return desktop.appendingPathComponent("ScreenMind-Export/JSON").path
    }

    private static func defaultMarkdownPath() -> String {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        return desktop.appendingPathComponent("ScreenMind-Export/Markdown").path
    }
}
