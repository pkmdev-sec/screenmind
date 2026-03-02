import Foundation

/// Platform-independent note representation for syncing between devices.
/// This model bridges macOS, iOS, and web clients, ensuring consistent
/// note structure across all platforms.
public struct SyncableNote: Codable, Sendable, Identifiable {
    /// Unique note identifier (same across all devices)
    public let id: String
    /// Note title
    public let title: String
    /// Note summary
    public let summary: String
    /// Full note details
    public let details: String
    /// Category (meeting, research, coding, etc.)
    public let category: String
    /// Tags for organization
    public let tags: [String]
    /// AI confidence score (0.0 to 1.0)
    public let confidence: Double
    /// Application that generated this note
    public let appName: String
    /// Window title when note was captured
    public let windowTitle: String?
    /// Creation timestamp
    public let createdAt: Date
    /// Obsidian links (if any)
    public let obsidianLinks: [String]
    /// Whether note has associated screenshot
    public let hasScreenshot: Bool
    /// Sync metadata
    public let syncMetadata: SyncMetadata

    public init(
        id: String,
        title: String,
        summary: String,
        details: String,
        category: String,
        tags: [String],
        confidence: Double,
        appName: String,
        windowTitle: String?,
        createdAt: Date,
        obsidianLinks: [String],
        hasScreenshot: Bool,
        syncMetadata: SyncMetadata
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.details = details
        self.category = category
        self.tags = tags
        self.confidence = confidence
        self.appName = appName
        self.windowTitle = windowTitle
        self.createdAt = createdAt
        self.obsidianLinks = obsidianLinks
        self.hasScreenshot = hasScreenshot
        self.syncMetadata = syncMetadata
    }
}

/// Sync metadata attached to every syncable entity.
/// Implements vector clock-based conflict resolution for multi-device sync.
public struct SyncMetadata: Codable, Sendable, Equatable {
    /// Device that last modified this entity
    public let deviceID: String
    /// Version number for this device (incremented on each edit)
    public let version: Int
    /// Last modification timestamp
    public let lastModified: Date
    /// Sync status
    public var syncStatus: SyncStatus
    /// Vector clock for conflict detection (deviceID -> version)
    public let vectorClock: [String: Int]
    /// Hash of content for change detection
    public let contentHash: String

    public init(
        deviceID: String,
        version: Int,
        lastModified: Date,
        syncStatus: SyncStatus,
        vectorClock: [String: Int],
        contentHash: String
    ) {
        self.deviceID = deviceID
        self.version = version
        self.lastModified = lastModified
        self.syncStatus = syncStatus
        self.vectorClock = vectorClock
        self.contentHash = contentHash
    }

    /// Create initial sync metadata for new entity.
    public static func initial(deviceID: String, contentHash: String) -> SyncMetadata {
        return SyncMetadata(
            deviceID: deviceID,
            version: 1,
            lastModified: Date(),
            syncStatus: .pending,
            vectorClock: [deviceID: 1],
            contentHash: contentHash
        )
    }

    /// Increment version and update timestamp.
    public func incrementVersion() -> SyncMetadata {
        var newVectorClock = vectorClock
        newVectorClock[deviceID] = version + 1

        return SyncMetadata(
            deviceID: deviceID,
            version: version + 1,
            lastModified: Date(),
            syncStatus: .pending,
            vectorClock: newVectorClock,
            contentHash: contentHash
        )
    }

    /// Merge vector clocks from two devices.
    public func merge(with other: SyncMetadata) -> SyncMetadata {
        var mergedClock = vectorClock
        for (deviceID, version) in other.vectorClock {
            mergedClock[deviceID] = max(mergedClock[deviceID] ?? 0, version)
        }

        return SyncMetadata(
            deviceID: deviceID,
            version: version,
            lastModified: lastModified,
            syncStatus: syncStatus,
            vectorClock: mergedClock,
            contentHash: contentHash
        )
    }
}

/// Sync status for an entity.
public enum SyncStatus: String, Codable, Sendable {
    /// Not yet synced to remote
    case pending
    /// Successfully synced
    case synced
    /// Sync failed (will retry)
    case failed
    /// Conflict detected (manual resolution needed)
    case conflict
}

/// Conflict resolution strategy for multi-device sync.
public enum SyncConflictResolution: String, Codable, Sendable {
    /// Last write wins (based on timestamp)
    case lastWriteWins
    /// Keep local version
    case keepLocal
    /// Keep remote version
    case keepRemote
    /// Manual resolution required
    case manual
    /// Merge changes (if possible)
    case merge
}

/// Represents a sync conflict that needs resolution.
public struct SyncConflict: Codable, Sendable, Identifiable {
    /// Unique conflict ID
    public let id: String
    /// Local version of the note
    public let localNote: SyncableNote
    /// Remote version of the note
    public let remoteNote: SyncableNote
    /// Detected at timestamp
    public let detectedAt: Date
    /// Resolution strategy (if resolved)
    public var resolution: SyncConflictResolution?
    /// Whether conflict is resolved
    public var isResolved: Bool

    public init(
        id: String,
        localNote: SyncableNote,
        remoteNote: SyncableNote,
        detectedAt: Date,
        resolution: SyncConflictResolution? = nil,
        isResolved: Bool = false
    ) {
        self.id = id
        self.localNote = localNote
        self.remoteNote = remoteNote
        self.detectedAt = detectedAt
        self.resolution = resolution
        self.isResolved = isResolved
    }

    /// Resolve conflict with specified strategy.
    public func resolve(with strategy: SyncConflictResolution) -> SyncableNote {
        switch strategy {
        case .lastWriteWins:
            return localNote.syncMetadata.lastModified > remoteNote.syncMetadata.lastModified
                ? localNote : remoteNote
        case .keepLocal:
            return localNote
        case .keepRemote:
            return remoteNote
        case .manual, .merge:
            // Manual/merge requires UI intervention
            return localNote
        }
    }
}

/// Delta change for incremental sync.
/// Instead of syncing full notes, sync only changes.
public struct SyncDelta: Codable, Sendable {
    /// Entity ID being changed
    public let entityID: String
    /// Type of change
    public let changeType: ChangeType
    /// Changed fields (for updates)
    public let changedFields: [String: String]?
    /// Timestamp of change
    public let timestamp: Date
    /// Device that made the change
    public let deviceID: String

    public enum ChangeType: String, Codable {
        case create
        case update
        case delete
    }

    public init(
        entityID: String,
        changeType: ChangeType,
        changedFields: [String: String]?,
        timestamp: Date,
        deviceID: String
    ) {
        self.entityID = entityID
        self.changeType = changeType
        self.changedFields = changedFields
        self.timestamp = timestamp
        self.deviceID = deviceID
    }
}

/// Sync statistics for monitoring.
public struct SyncStatistics: Codable, Sendable {
    /// Total notes synced
    public let totalSynced: Int
    /// Pending sync count
    public let pendingSyncCount: Int
    /// Failed sync count
    public let failedSyncCount: Int
    /// Conflict count
    public let conflictCount: Int
    /// Last successful sync timestamp
    public let lastSyncedAt: Date?
    /// Next scheduled sync
    public let nextSyncAt: Date?
    /// Bytes uploaded in last sync
    public let bytesUploaded: Int64
    /// Bytes downloaded in last sync
    public let bytesDownloaded: Int64

    public init(
        totalSynced: Int,
        pendingSyncCount: Int,
        failedSyncCount: Int,
        conflictCount: Int,
        lastSyncedAt: Date?,
        nextSyncAt: Date?,
        bytesUploaded: Int64,
        bytesDownloaded: Int64
    ) {
        self.totalSynced = totalSynced
        self.pendingSyncCount = pendingSyncCount
        self.failedSyncCount = failedSyncCount
        self.conflictCount = conflictCount
        self.lastSyncedAt = lastSyncedAt
        self.nextSyncAt = nextSyncAt
        self.bytesUploaded = bytesUploaded
        self.bytesDownloaded = bytesDownloaded
    }

    /// Empty statistics (no sync yet).
    public static var empty: SyncStatistics {
        return SyncStatistics(
            totalSynced: 0,
            pendingSyncCount: 0,
            failedSyncCount: 0,
            conflictCount: 0,
            lastSyncedAt: nil,
            nextSyncAt: nil,
            bytesUploaded: 0,
            bytesDownloaded: 0
        )
    }
}
