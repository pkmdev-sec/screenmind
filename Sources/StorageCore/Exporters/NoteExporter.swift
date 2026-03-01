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

    /// SF Symbol icon.
    public var iconName: String {
        switch self {
        case .obsidian: return "book.closed.fill"
        case .json: return "curlybraces"
        case .flatMarkdown: return "doc.text"
        case .webhook: return "arrow.up.forward.app"
        }
    }

    /// Short description.
    public var subtitle: String {
        switch self {
        case .obsidian: return "Daily folders with frontmatter and wiki-links"
        case .json: return "One JSON file per note for data pipelines"
        case .flatMarkdown: return "Simple .md files without vault structure"
        case .webhook: return "POST note data to a URL"
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
