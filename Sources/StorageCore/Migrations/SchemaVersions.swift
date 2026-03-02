import Foundation
import SwiftData
import Shared

/// Schema version tracking for ScreenMind data migrations.
///
/// When adding new fields to SwiftData models:
/// 1. Create a new VersionedSchema enum (e.g., SchemaV2)
/// 2. Add a migration stage to ScreenMindMigrationPlan
/// 3. Update `current` to the new version
/// 4. Run BackupManager.backup() before applying migration
public enum SchemaVersion: Int, CaseIterable, Sendable {
    case v1 = 1

    public static var current: SchemaVersion { .v1 }
}

/// V1 Schema — initial production schema.
/// Models: NoteModel, ScreenshotModel, AppContextModel
public enum SchemaV1: VersionedSchema {
    public static var versionIdentifier = Schema.Version(1, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [NoteModel.self, ScreenshotModel.self, AppContextModel.self]
    }
}

/// Migration plan for ScreenMind SwiftData schemas.
/// Add new migration stages here when schema changes are needed.
public enum ScreenMindMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}
