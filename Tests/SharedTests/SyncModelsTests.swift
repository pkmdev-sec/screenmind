import Foundation
import Testing
@testable import Shared

// MARK: - Sync Metadata Tests

@Test func syncMetadataInitial() {
    let metadata = SyncMetadata.initial(deviceID: "device-1", contentHash: "hash123")

    #expect(metadata.deviceID == "device-1")
    #expect(metadata.version == 1)
    #expect(metadata.syncStatus == .pending)
    #expect(metadata.vectorClock["device-1"] == 1)
    #expect(metadata.contentHash == "hash123")
}

@Test func syncMetadataIncrementVersion() {
    let initial = SyncMetadata.initial(deviceID: "device-1", contentHash: "hash123")
    let incremented = initial.incrementVersion()

    #expect(incremented.version == 2)
    #expect(incremented.vectorClock["device-1"] == 2)
}

@Test func syncMetadataMergeVectorClocks() {
    let metadata1 = SyncMetadata(
        deviceID: "device-1",
        version: 2,
        lastModified: Date(),
        syncStatus: .synced,
        vectorClock: ["device-1": 2, "device-2": 1],
        contentHash: "hash1"
    )

    let metadata2 = SyncMetadata(
        deviceID: "device-2",
        version: 3,
        lastModified: Date(),
        syncStatus: .synced,
        vectorClock: ["device-1": 1, "device-2": 3],
        contentHash: "hash2"
    )

    let merged = metadata1.merge(with: metadata2)

    #expect(merged.vectorClock["device-1"] == 2)
    #expect(merged.vectorClock["device-2"] == 3)
}

// MARK: - Sync Status Tests

@Test func syncStatusEnumCases() {
    #expect(SyncStatus.pending.rawValue == "pending")
    #expect(SyncStatus.synced.rawValue == "synced")
    #expect(SyncStatus.failed.rawValue == "failed")
    #expect(SyncStatus.conflict.rawValue == "conflict")
}

// MARK: - Sync Conflict Tests

@Test func syncConflictResolveLastWriteWins() {
    let now = Date()
    let past = now.addingTimeInterval(-3600) // 1 hour ago

    let localMeta = SyncMetadata.initial(deviceID: "local", contentHash: "hash1")
    let remoteMeta = SyncMetadata(
        deviceID: "remote",
        version: 1,
        lastModified: past,
        syncStatus: .synced,
        vectorClock: ["remote": 1],
        contentHash: "hash2"
    )

    let localNote = SyncableNote(
        id: "note-1",
        title: "Local Version",
        summary: "Local",
        details: "Local details",
        category: "coding",
        tags: [],
        confidence: 0.9,
        appName: "Xcode",
        windowTitle: nil,
        createdAt: now,
        obsidianLinks: [],
        hasScreenshot: false,
        syncMetadata: localMeta
    )

    let remoteNote = SyncableNote(
        id: "note-1",
        title: "Remote Version",
        summary: "Remote",
        details: "Remote details",
        category: "coding",
        tags: [],
        confidence: 0.9,
        appName: "Xcode",
        windowTitle: nil,
        createdAt: past,
        obsidianLinks: [],
        hasScreenshot: false,
        syncMetadata: remoteMeta
    )

    let conflict = SyncConflict(
        id: "conflict-1",
        localNote: localNote,
        remoteNote: remoteNote,
        detectedAt: Date()
    )

    let resolved = conflict.resolve(with: .lastWriteWins)
    #expect(resolved.title == "Local Version") // Local is newer
}

@Test func syncConflictResolveKeepLocal() {
    let localNote = SyncableNote(
        id: "note-1",
        title: "Local Version",
        summary: "Local",
        details: "Details",
        category: "coding",
        tags: [],
        confidence: 0.9,
        appName: "Xcode",
        windowTitle: nil,
        createdAt: Date(),
        obsidianLinks: [],
        hasScreenshot: false,
        syncMetadata: .initial(deviceID: "local", contentHash: "hash1")
    )

    let remoteNote = SyncableNote(
        id: "note-1",
        title: "Remote Version",
        summary: "Remote",
        details: "Details",
        category: "coding",
        tags: [],
        confidence: 0.9,
        appName: "Xcode",
        windowTitle: nil,
        createdAt: Date(),
        obsidianLinks: [],
        hasScreenshot: false,
        syncMetadata: .initial(deviceID: "remote", contentHash: "hash2")
    )

    let conflict = SyncConflict(
        id: "conflict-1",
        localNote: localNote,
        remoteNote: remoteNote,
        detectedAt: Date()
    )

    let resolved = conflict.resolve(with: .keepLocal)
    #expect(resolved.title == "Local Version")
}

// MARK: - Sync Delta Tests

@Test func syncDeltaInit() {
    let delta = SyncDelta(
        entityID: "note-1",
        changeType: .update,
        changedFields: ["title": "New Title"],
        timestamp: Date(),
        deviceID: "device-1"
    )

    #expect(delta.entityID == "note-1")
    #expect(delta.changeType == .update)
    #expect(delta.changedFields?["title"] == "New Title")
}

// MARK: - Sync Statistics Tests

@Test func syncStatisticsEmpty() {
    let stats = SyncStatistics.empty

    #expect(stats.totalSynced == 0)
    #expect(stats.pendingSyncCount == 0)
    #expect(stats.failedSyncCount == 0)
    #expect(stats.conflictCount == 0)
    #expect(stats.lastSyncedAt == nil)
}

@Test func syncStatisticsInit() {
    let now = Date()
    let stats = SyncStatistics(
        totalSynced: 100,
        pendingSyncCount: 5,
        failedSyncCount: 2,
        conflictCount: 1,
        lastSyncedAt: now,
        nextSyncAt: now.addingTimeInterval(300),
        bytesUploaded: 1024,
        bytesDownloaded: 2048
    )

    #expect(stats.totalSynced == 100)
    #expect(stats.pendingSyncCount == 5)
    #expect(stats.failedSyncCount == 2)
    #expect(stats.conflictCount == 1)
    #expect(stats.bytesUploaded == 1024)
}
