import Foundation
import AIProcessing
import Shared

/// Exports notes to Logseq journal format.
public struct LogseqExporter: NoteExporter, Sendable {
    public let exporterType: ExporterType = .logseq

    private let graphPath: String

    public init?(graphPath: String? = nil) {
        if let graphPath = graphPath {
            self.graphPath = graphPath
        } else if let storedPath = UserDefaults.standard.string(forKey: "logseqGraphPath"), !storedPath.isEmpty {
            self.graphPath = storedPath
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
        guard UserDefaults.standard.bool(forKey: "logseqExportEnabled") else {
            return false
        }

        let expandedPath = (graphPath as NSString).expandingTildeInPath
        let journalsDir = URL(fileURLWithPath: expandedPath).appendingPathComponent("journals")

        // Create journals directory if needed
        try? FileManager.default.createDirectory(at: journalsDir, withIntermediateDirectories: true)

        // Format: YYYY_MM_DD.md
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy_MM_dd"
        let filename = dateFormatter.string(from: timestamp) + ".md"
        let fileURL = journalsDir.appendingPathComponent(filename)

        // Build Logseq block format
        var block = "- " + note.title + "\n"
        block += "  category:: \(note.category.rawValue)\n"
        block += "  app:: \(appName)\n"
        if let window = windowTitle {
            block += "  window:: \(window)\n"
        }
        if !note.tags.isEmpty {
            block += "  tags:: " + note.tags.map { "#\($0)" }.joined(separator: ", ") + "\n"
        }
        block += "  \n"  // Empty line
        block += "  " + note.summary + "\n"
        if !note.details.isEmpty {
            // Indent details as nested block
            let detailLines = note.details.split(separator: "\n")
            for line in detailLines {
                block += "    " + line + "\n"
            }
        }
        // Add page references for Obsidian links
        for link in note.obsidianLinks {
            let pageName = link.replacingOccurrences(of: "[[", with: "").replacingOccurrences(of: "]]", with: "")
            block += "  [[\(pageName)]]\n"
        }
        block += "\n"

        do {
            // Append to existing journal file or create new
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let handle = try FileHandle(forWritingTo: fileURL)
                handle.seekToEndOfFile()
                handle.write(block.data(using: .utf8)!)
                try handle.close()
            } else {
                try block.write(to: fileURL, atomically: true, encoding: .utf8)
            }

            SMLogger.storage.info("Logseq exported: '\(note.title)' to \(filename)")
            return true
        } catch {
            SMLogger.storage.error("Logseq export error: \(error.localizedDescription)")
            return false
        }
    }
}
