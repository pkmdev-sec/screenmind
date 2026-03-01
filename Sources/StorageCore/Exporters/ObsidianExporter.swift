import Foundation
import AIProcessing
import Shared

/// Obsidian vault exporter — wraps the existing ObsidianNoteWriter.
public struct ObsidianExporter: NoteExporter, Sendable {
    public let exporterType: ExporterType = .obsidian
    private let writer: ObsidianNoteWriter

    public init() {
        self.writer = ObsidianNoteWriter()
    }

    public func export(note: GeneratedNote, appName: String, windowTitle: String?, timestamp: Date) async throws -> Bool {
        _ = try writer.write(note: note, appName: appName, windowTitle: windowTitle, timestamp: timestamp)
        return true
    }
}
