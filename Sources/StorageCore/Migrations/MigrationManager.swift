import Foundation
import SwiftData
import Shared

/// Manages SwiftData schema versions and pre-migration backups.
///
/// Usage:
/// 1. Before creating ModelContainer, call `backupIfNeeded()`
/// 2. Use the standard Schema with current models
/// 3. SwiftData handles lightweight migrations automatically for additive changes
///
/// For breaking changes (removing fields, changing types), create a custom
/// SchemaMigrationPlan and register it with ModelContainer.
public enum MigrationManager {

    /// Current schema version (increment when models change).
    public static let currentVersion = 1

    /// UserDefaults key for tracking the last known schema version.
    private static let versionKey = "screenmind.schemaVersion"

    /// Check if the schema version has changed since last launch.
    public static var needsMigration: Bool {
        let stored = UserDefaults.standard.integer(forKey: versionKey)
        return stored != 0 && stored < currentVersion
    }

    /// Record the current schema version after successful launch.
    public static func recordCurrentVersion() {
        UserDefaults.standard.set(currentVersion, forKey: versionKey)
    }

    /// Create a JSON backup of all notes before migration.
    /// Returns the backup directory path, or nil if backup fails.
    @discardableResult
    public static func backupIfNeeded(modelContainer: ModelContainer) -> URL? {
        guard needsMigration else {
            SMLogger.storage.info("Schema version \(currentVersion) — no migration needed")
            return nil
        }

        SMLogger.storage.info("Schema migration detected (stored version → current \(currentVersion)). Creating backup...")

        do {
            let backupURL = try createBackup(modelContainer: modelContainer)
            SMLogger.storage.info("Pre-migration backup created at: \(backupURL.path)")
            return backupURL
        } catch {
            SMLogger.storage.error("Pre-migration backup failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Create a JSON backup of all notes.
    public static func createBackup(modelContainer: ModelContainer) throws -> URL {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<NoteModel>(sortBy: [SortDescriptor(\.createdAt)])
        let notes = try context.fetch(descriptor)

        let backupDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent(AppConstants.bundleIdentifier)
            .appendingPathComponent("Backups")
            .appendingPathComponent("migration-v\(currentVersion)-\(Date.now.dateFolderName)")

        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        for note in notes {
            let noteData: [String: Any] = [
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
                "redactionCount": note.redactionCount
            ]

            if let jsonData = try? JSONSerialization.data(withJSONObject: noteData, options: [.prettyPrinted, .sortedKeys]) {
                let filename = "\(note.id.uuidString).json"
                try jsonData.write(to: backupDir.appendingPathComponent(filename))
            }
        }

        // Write metadata
        let metadata: [String: Any] = [
            "backupDate": Date.now.iso8601String,
            "noteCount": notes.count,
            "fromVersion": UserDefaults.standard.integer(forKey: versionKey),
            "toVersion": currentVersion
        ]
        if let metaData = try? JSONSerialization.data(withJSONObject: metadata, options: [.prettyPrinted]) {
            try metaData.write(to: backupDir.appendingPathComponent("_metadata.json"))
        }

        SMLogger.storage.info("Backed up \(notes.count) notes to \(backupDir.lastPathComponent)")
        return backupDir
    }

    /// List available backups.
    public static func listBackups() -> [URL] {
        let backupRoot = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent(AppConstants.bundleIdentifier)
            .appendingPathComponent("Backups")

        guard FileManager.default.fileExists(atPath: backupRoot.path) else { return [] }

        return (try? FileManager.default.contentsOfDirectory(at: backupRoot, includingPropertiesForKeys: [.creationDateKey]))?.sorted {
            $0.lastPathComponent > $1.lastPathComponent
        } ?? []
    }
}
