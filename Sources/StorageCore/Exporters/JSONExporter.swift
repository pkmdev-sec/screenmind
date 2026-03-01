import Foundation
import AIProcessing
import Shared

/// Exports notes as individual JSON files for data pipelines and scripting.
public struct JSONExporter: NoteExporter, Sendable {
    public let exporterType: ExporterType = .json
    private let outputDirectory: String

    public init(outputDirectory: String) {
        self.outputDirectory = (outputDirectory as NSString).expandingTildeInPath
    }

    public func export(note: GeneratedNote, appName: String, windowTitle: String?, timestamp: Date) async throws -> Bool {
        // Ensure directory exists
        try FileManager.default.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true)

        let json: [String: Any] = [
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
            "exported_at": ISO8601DateFormatter().string(from: Date())
        ]

        let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])

        let filename = safeFilename(from: note.title, timestamp: timestamp)
        let filePath = (outputDirectory as NSString).appendingPathComponent(filename)
        try data.write(to: URL(fileURLWithPath: filePath))

        SMLogger.storage.info("JSON exported: \(filename)")
        return true
    }

    private func safeFilename(from title: String, timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        let timeString = formatter.string(from: timestamp)
        let safe = title.safeFilename
        let truncated = String(safe.prefix(60))
        return "\(timeString)-\(truncated).json"
    }
}
