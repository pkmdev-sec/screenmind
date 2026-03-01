import Foundation
import AIProcessing
import Shared

/// Exports notes as flat Markdown files without Obsidian vault structure.
public struct FlatMarkdownExporter: NoteExporter, Sendable {
    public let exporterType: ExporterType = .flatMarkdown
    private let outputDirectory: String

    public init(outputDirectory: String) {
        self.outputDirectory = (outputDirectory as NSString).expandingTildeInPath
    }

    public func export(note: GeneratedNote, appName: String, windowTitle: String?, timestamp: Date) async throws -> Bool {
        try FileManager.default.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true)

        var md = "# \(note.title)\n\n"
        md += "**Date:** \(timestamp.iso8601String)  \n"
        md += "**App:** \(appName)  \n"
        md += "**Category:** \(note.category.rawValue)  \n"
        if let windowTitle, !windowTitle.isEmpty {
            md += "**Window:** \(windowTitle)  \n"
        }
        md += "\n---\n\n"
        md += "\(note.summary)\n\n"

        if !note.details.isEmpty {
            md += "## Details\n\n"
            md += "\(note.details)\n\n"
        }

        if !note.tags.isEmpty {
            md += "**Tags:** \(note.tags.map { "#\($0)" }.joined(separator: " "))\n\n"
        }

        if !note.obsidianLinks.isEmpty {
            md += "## Related\n\n"
            for link in note.obsidianLinks {
                md += "- \(link)\n"
            }
            md += "\n"
        }

        md += "---\n*Captured from \(appName) by ScreenMind*\n"

        let filename = safeFilename(from: note.title, timestamp: timestamp)
        let filePath = (outputDirectory as NSString).appendingPathComponent(filename)
        try md.write(toFile: filePath, atomically: true, encoding: .utf8)

        SMLogger.storage.info("Flat Markdown exported: \(filename)")
        return true
    }

    private func safeFilename(from title: String, timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        let timeString = formatter.string(from: timestamp)
        let safe = title.safeFilename
        let truncated = String(safe.prefix(60))
        return "\(timeString)-\(truncated).md"
    }
}
