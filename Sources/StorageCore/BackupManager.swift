import Foundation
import SwiftData
import Shared

/// Pre-migration backup utility for ScreenMind data.
///
/// Creates JSON backups of all notes before applying schema migrations.
/// Backups are stored in a temporary directory and can be used for
/// recovery if migration fails.
public struct BackupManager: Sendable {

    /// Create a JSON backup of all notes in the given container.
    /// - Parameter modelContainer: The SwiftData container to back up.
    /// - Returns: URL of the backup directory containing JSON files.
    @MainActor
    public static func backup(modelContainer: ModelContainer) throws -> URL {
        let timestamp = Int(Date.now.timeIntervalSince1970)
        let backupDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("screenmind-backup-\(timestamp)")
        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)

        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<NoteModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let notes = try context.fetch(descriptor)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        for note in notes {
            let noteDict: [String: Any] = [
                "id": note.id.uuidString,
                "title": note.title,
                "summary": note.summary,
                "details": note.details,
                "category": note.category,
                "tags": note.tags,
                "confidence": note.confidence,
                "appName": note.appName,
                "windowTitle": note.windowTitle ?? "",
                "createdAt": note.createdAt.iso8601String,
                "obsidianLinks": note.obsidianLinks,
                "obsidianExported": note.obsidianExported,
                "redactionCount": note.redactionCount
            ]
            let data = try JSONSerialization.data(withJSONObject: noteDict, options: [.prettyPrinted, .sortedKeys])
            let filename = "\(note.id.uuidString).json"
            try data.write(to: backupDir.appendingPathComponent(filename))
        }

        SMLogger.storage.info("Backup created: \(notes.count) notes at \(backupDir.path)")
        return backupDir
    }
}
