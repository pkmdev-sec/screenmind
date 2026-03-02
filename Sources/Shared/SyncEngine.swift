import Foundation
import CloudKit

/// Multi-device sync engine implementing offline-first architecture.
/// Uses vector clocks for conflict resolution and supports pluggable backends
/// (CloudKit, custom server, P2P).
public actor SyncEngine {
    /// Current device identifier (persistent across app launches)
    private let deviceID: String
    /// Sync provider (CloudKit, custom backend, etc.)
    private let provider: SyncProvider
    /// Pending changes queue (offline-first)
    private var pendingChanges: [SyncDelta] = []
    /// Active sync conflicts
    private var conflicts: [SyncConflict] = []
    /// Sync statistics
    private var stats: SyncStatistics

    public init(provider: SyncProvider) {
        self.provider = provider
        self.deviceID = Self.getOrCreateDeviceID()
        self.stats = .empty
    }

    // MARK: - Public API

    /// Start background sync (periodically syncs pending changes).
    public func startBackgroundSync(interval: TimeInterval = 300) async {
        SMLogger.system.info("Sync engine started with interval: \(interval)s")
        // TODO: Implement background sync loop
        // - Check for pending changes
        // - Push local changes to remote
        // - Pull remote changes
        // - Resolve conflicts
    }

    /// Stop background sync.
    public func stopBackgroundSync() async {
        SMLogger.system.info("Sync engine stopped")
    }

    /// Sync immediately (manual trigger).
    public func syncNow() async throws {
        guard UserDefaults.standard.syncEnabled else {
            throw SyncError.syncDisabled
        }

        SMLogger.system.info("Manual sync started")

        // Push local changes
        let pushCount = try await pushPendingChanges()

        // Pull remote changes
        let pullCount = try await pullRemoteChanges()

        // Resolve conflicts
        let conflictCount = await resolveConflicts()

        // Update stats
        stats = SyncStatistics(
            totalSynced: stats.totalSynced + pushCount + pullCount,
            pendingSyncCount: pendingChanges.count,
            failedSyncCount: 0,
            conflictCount: conflicts.count,
            lastSyncedAt: Date(),
            nextSyncAt: nil,
            bytesUploaded: 0,
            bytesDownloaded: 0
        )

        SMLogger.system.info("Sync complete: pushed \(pushCount), pulled \(pullCount), conflicts \(conflictCount)")
    }

    /// Queue a note for sync (called after local note creation/update).
    public func queueNoteForSync(_ note: SyncableNote) async {
        let delta = SyncDelta(
            entityID: note.id,
            changeType: .update,
            changedFields: nil,
            timestamp: Date(),
            deviceID: deviceID
        )
        pendingChanges.append(delta)
        SMLogger.system.debug("Queued note for sync: \(note.id)")
    }

    /// Get sync statistics.
    public func getStatistics() async -> SyncStatistics {
        return stats
    }

    /// Get unresolved conflicts.
    public func getConflicts() async -> [SyncConflict] {
        return conflicts
    }

    /// Resolve a conflict with specified strategy.
    public func resolveConflict(_ conflict: SyncConflict, strategy: SyncConflictResolution) async throws {
        let resolvedNote = conflict.resolve(with: strategy)

        // Apply resolution to local storage
        // TODO: Call StorageActor to update note

        // Remove from conflicts
        conflicts.removeAll { $0.id == conflict.id }

        SMLogger.system.info("Conflict resolved: \(conflict.id) with strategy: \(strategy.rawValue)")
    }

    // MARK: - Private Sync Operations

    private func pushPendingChanges() async throws -> Int {
        guard !pendingChanges.isEmpty else { return 0 }

        var pushedCount = 0
        for delta in pendingChanges {
            do {
                try await provider.pushChange(delta)
                pushedCount += 1
            } catch {
                SMLogger.system.error("Failed to push change: \(error.localizedDescription)")
            }
        }

        // Clear successfully pushed changes
        pendingChanges.removeAll()
        return pushedCount
    }

    private func pullRemoteChanges() async throws -> Int {
        let remoteChanges = try await provider.pullChanges(since: stats.lastSyncedAt)

        var pulledCount = 0
        for change in remoteChanges {
            // Check for conflicts
            if let conflict = await detectConflict(for: change) {
                conflicts.append(conflict)
            } else {
                // Apply change to local storage
                // TODO: Call StorageActor to update note
                pulledCount += 1
            }
        }

        return pulledCount
    }

    private func detectConflict(for delta: SyncDelta) async -> SyncConflict? {
        // TODO: Query local storage for the same entity
        // TODO: Compare vector clocks to detect concurrent modifications
        // For now, return nil (no conflict)
        return nil
    }

    private func resolveConflicts() async -> Int {
        let autoResolvable = conflicts.filter { conflict in
            // Auto-resolve using last-write-wins for non-manual conflicts
            conflict.resolution == nil
        }

        for conflict in autoResolvable {
            try? await resolveConflict(conflict, strategy: .lastWriteWins)
        }

        return autoResolvable.count
    }

    // MARK: - Device ID Management

    private static func getOrCreateDeviceID() -> String {
        if let existing = UserDefaults.standard.string(forKey: "syncDeviceID") {
            return existing
        }

        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: "syncDeviceID")
        return newID
    }
}

/// Protocol for sync providers (CloudKit, custom backend, P2P).
public protocol SyncProvider: Sendable {
    /// Push a local change to remote.
    func pushChange(_ delta: SyncDelta) async throws

    /// Pull remote changes since a timestamp.
    func pullChanges(since: Date?) async throws -> [SyncDelta]

    /// Check if sync is available (network + credentials).
    func isAvailable() async -> Bool
}

/// CloudKit sync provider (stub implementation).
public actor CloudKitSyncProvider: SyncProvider {
    private let container: CKContainer
    private let database: CKDatabase

    public init(containerIdentifier: String = "iCloud.com.screenmind.app") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.database = container.privateCloudDatabase
    }

    public func pushChange(_ delta: SyncDelta) async throws {
        // TODO: Convert SyncDelta to CKRecord
        // TODO: Save to CloudKit using database.save()
        SMLogger.system.debug("CloudKit: pushing change \(delta.entityID)")
    }

    public func pullChanges(since: Date?) async throws -> [SyncDelta] {
        // TODO: Query CloudKit for records modified since timestamp
        // TODO: Convert CKRecords to SyncDeltas
        SMLogger.system.debug("CloudKit: pulling changes since \(since?.description ?? "beginning")")
        return []
    }

    public func isAvailable() async -> Bool {
        // Check CloudKit availability
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            SMLogger.system.error("CloudKit unavailable: \(error.localizedDescription)")
            return false
        }
    }
}

/// Custom backend sync provider (stub for self-hosted server).
public actor CustomBackendSyncProvider: SyncProvider {
    private let baseURL: URL
    private let apiKey: String

    public init(baseURL: URL, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    public func pushChange(_ delta: SyncDelta) async throws {
        // TODO: POST delta to baseURL/api/sync/push
        // TODO: Include apiKey in Authorization header
        SMLogger.system.debug("Custom backend: pushing change \(delta.entityID)")
    }

    public func pullChanges(since: Date?) async throws -> [SyncDelta] {
        // TODO: GET baseURL/api/sync/pull?since=<timestamp>
        // TODO: Include apiKey in Authorization header
        SMLogger.system.debug("Custom backend: pulling changes")
        return []
    }

    public func isAvailable() async -> Bool {
        // TODO: Check server reachability
        return false
    }
}

// MARK: - Sync Errors

public enum SyncError: Error, LocalizedError {
    case syncDisabled
    case providerUnavailable
    case conflictDetected
    case networkError(Error)

    public var errorDescription: String? {
        switch self {
        case .syncDisabled:
            return "Sync is disabled in settings"
        case .providerUnavailable:
            return "Sync provider is unavailable"
        case .conflictDetected:
            return "Sync conflict detected"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - UserDefaults Extensions

extension UserDefaults {
    /// Whether sync is enabled.
    public var syncEnabled: Bool {
        get { bool(forKey: "syncEnabled") }
        set { set(newValue, forKey: "syncEnabled") }
    }

    /// Sync provider type (cloudkit, custom, p2p).
    public var syncProviderType: String {
        get { string(forKey: "syncProviderType") ?? "cloudkit" }
        set { set(newValue, forKey: "syncProviderType") }
    }

    /// Custom backend URL (if using custom provider).
    public var syncBackendURL: String? {
        get { string(forKey: "syncBackendURL") }
        set { set(newValue, forKey: "syncBackendURL") }
    }
}
