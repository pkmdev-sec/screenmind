import Foundation
import Testing
@testable import SystemIntegration

// MARK: - LaunchAtLoginManager Tests

@Test func launchAtLoginManagerInitializes() {
    let manager = LaunchAtLoginManager()
    _ = manager
}

// MARK: - ResourceMonitor Tests

@Test func resourceSnapshotInitializes() {
    let snapshot = ResourceMonitor.ResourceSnapshot(
        cpuPercent: 5.2,
        memoryMB: 120.5,
        batteryLevel: 85,
        isOnBattery: true,
        isLowPower: false
    )
    #expect(snapshot.cpuPercent == 5.2)
    #expect(snapshot.memoryMB == 120.5)
    #expect(snapshot.batteryLevel == 85)
    #expect(snapshot.isOnBattery == true)
    #expect(snapshot.isLowPower == false)
}

@Test func throughputStatsDefaults() {
    let stats = ResourceMonitor.ThroughputStats()
    #expect(stats.totalFramesCaptured == 0)
    #expect(stats.framesFiltered == 0)
    #expect(stats.framesOCRd == 0)
    #expect(stats.notesGenerated == 0)
    #expect(stats.notesSkippedByAI == 0)
    #expect(stats.notesSkippedByRules == 0)
    #expect(stats.redactionsApplied == 0)
    #expect(stats.avgOCRTimeMs == 0)
    #expect(stats.avgAITimeMs == 0)
    #expect(stats.lastNoteTime == nil)
}

@Test func throughputStatsMutable() {
    var stats = ResourceMonitor.ThroughputStats()
    stats.totalFramesCaptured = 100
    stats.notesGenerated = 10
    stats.avgOCRTimeMs = 50.0

    #expect(stats.totalFramesCaptured == 100)
    #expect(stats.notesGenerated == 10)
    #expect(stats.avgOCRTimeMs == 50.0)
}

@Test func resourceMonitorSharedInstance() async {
    let monitor = ResourceMonitor.shared
    _ = monitor // Verify singleton access
}

@Test func resourceMonitorCurrentResources() async {
    let monitor = ResourceMonitor.shared
    let resources = await monitor.currentResources()
    // These should return non-negative values
    #expect(resources.cpuPercent >= 0)
    #expect(resources.memoryMB >= 0)
    #expect(resources.batteryLevel >= 0 && resources.batteryLevel <= 100)
}

@Test func resourceMonitorCurrentThroughput() async {
    let monitor = ResourceMonitor.shared
    let throughput = await monitor.currentThroughput()
    #expect(throughput.totalFramesCaptured >= 0)
}

@Test func resourceMonitorRecordFrameOperations() async {
    let monitor = ResourceMonitor.shared

    // Reset to get clean baseline
    await monitor.resetSession()
    let before = await monitor.currentThroughput()

    // Record operations
    await monitor.recordFrameCaptured()
    await monitor.recordFrameCaptured()
    await monitor.recordFrameFiltered()

    let after = await monitor.currentThroughput()

    #expect(after.totalFramesCaptured == before.totalFramesCaptured + 2)
    #expect(after.framesFiltered == before.framesFiltered + 1)
}

@Test func resourceMonitorRecordOCRAndAI() async {
    let monitor = ResourceMonitor.shared
    await monitor.resetSession()

    // Record OCR with timing
    await monitor.recordOCRComplete(timeMs: 50.0)
    await monitor.recordOCRComplete(timeMs: 60.0)

    // Record AI with timing
    await monitor.recordNoteGenerated(aiTimeMs: 200.0)

    let stats = await monitor.currentThroughput()

    #expect(stats.framesOCRd == 2)
    #expect(stats.notesGenerated == 1)
    #expect(stats.avgOCRTimeMs == 55.0) // (50 + 60) / 2
    #expect(stats.avgAITimeMs == 200.0)
    #expect(stats.lastNoteTime != nil)
}

@Test func resourceMonitorRecordSkips() async {
    let monitor = ResourceMonitor.shared
    await monitor.resetSession()

    await monitor.recordNoteSkippedByAI()
    await monitor.recordNoteSkippedByRule()
    await monitor.recordNoteSkippedByRule()

    let stats = await monitor.currentThroughput()

    #expect(stats.notesSkippedByAI == 1)
    #expect(stats.notesSkippedByRules == 2)
}

@Test func resourceMonitorRecordRedactions() async {
    let monitor = ResourceMonitor.shared
    await monitor.resetSession()

    await monitor.recordRedaction(count: 3)
    await monitor.recordRedaction(count: 2)

    let stats = await monitor.currentThroughput()

    #expect(stats.redactionsApplied == 5)
}

@Test func resourceMonitorThroughputUptime() async {
    let monitor = ResourceMonitor.shared
    await monitor.resetSession()

    let stats = await monitor.currentThroughput()

    #expect(stats.uptime >= 0)
    #expect(stats.sessionStartTime <= Date.now)
}

@Test func resourceMonitorNotesPerHour() async {
    let monitor = ResourceMonitor.shared
    await monitor.resetSession()

    let stats = await monitor.currentThroughput()

    // Should be 0 when uptime < 60 seconds
    #expect(stats.notesPerHour == 0.0)
}

// MARK: - PowerStateMonitor Tests

@Test func powerStateInitializes() {
    let state = PowerStateMonitor.PowerState(
        isOnBattery: true,
        batteryLevel: 75,
        isLowPower: false
    )

    #expect(state.isOnBattery == true)
    #expect(state.batteryLevel == 75)
    #expect(state.isLowPower == false)
}

@Test func powerStateMonitorCurrentState() async {
    let monitor = PowerStateMonitor()
    let state = await monitor.currentState()

    // Verify valid battery level range
    #expect(state.batteryLevel >= 0)
    #expect(state.batteryLevel <= 100)
}

@Test func powerStateMonitorCustomThreshold() async {
    let monitor = PowerStateMonitor(lowBatteryThreshold: 50)
    let state = await monitor.currentState()

    // If on battery and below threshold, should be low power
    if state.isOnBattery && state.batteryLevel <= 50 {
        #expect(state.isLowPower == true)
    } else {
        #expect(state.isLowPower == false)
    }
}

@Test func powerStateMonitorShouldPauseForBattery() async {
    let monitor = PowerStateMonitor(lowBatteryThreshold: 20)
    let shouldPause = await monitor.shouldPauseForBattery()

    // Result should be a boolean (can be true or false depending on actual battery)
    _ = shouldPause
}

// MARK: - UpdateChecker Tests

@Test func updateInfoStructure() {
    let info = UpdateChecker.UpdateInfo(
        currentVersion: "1.0.0",
        latestVersion: "1.0.1",
        downloadURL: "https://example.com/download",
        releaseNotes: "Test release notes",
        isUpdateAvailable: true
    )

    #expect(info.currentVersion == "1.0.0")
    #expect(info.latestVersion == "1.0.1")
    #expect(info.downloadURL == "https://example.com/download")
    #expect(info.releaseNotes == "Test release notes")
    #expect(info.isUpdateAvailable == true)
}

@Test func updateCheckerVersionComparisonLogic() {
    // Test the version comparison logic by replicating it
    func isNewerVersion(_ latest: String, than current: String) -> Bool {
        let latestParts = latest.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(latestParts.count, currentParts.count) {
            let l = i < latestParts.count ? latestParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            if l > c { return true }
            if l < c { return false }
        }
        return false
    }

    // Test cases
    #expect(isNewerVersion("1.0.1", than: "1.0.0") == true)
    #expect(isNewerVersion("1.0.0", than: "1.0.1") == false)
    #expect(isNewerVersion("1.0.0", than: "1.0.0") == false)
    #expect(isNewerVersion("2.0.0", than: "1.9.9") == true)
    #expect(isNewerVersion("1.2.3", than: "1.2.4") == false)
    #expect(isNewerVersion("1.2.4", than: "1.2.3") == true)
    #expect(isNewerVersion("1.0", than: "1.0.0") == false)
    #expect(isNewerVersion("1.0.1", than: "1.0") == true)
}

// MARK: - NotificationManager Bare Binary Guard Tests

@Test func notificationManagerSingletonExists() {
    let manager = NotificationManager.shared
    _ = manager
}

@Test func notificationManagerRequestAuthDoesNotCrash() async {
    // In SPM test context, Bundle.main.bundleIdentifier may or may not exist.
    // The key assertion: this call must NOT crash with NSInternalInconsistencyException.
    let result = await NotificationManager.shared.requestAuthorization()
    // Result depends on environment — may be true (Xcode), false (bare binary), or
    // false (denied). The important thing is we didn't crash.
    _ = result
}

@Test func notificationManagerNotifyNoteCreatedDoesNotCrash() {
    // Must not crash in any execution environment (bundled or bare binary)
    NotificationManager.shared.notifyNoteCreated(title: "Test Note", category: "testing")
}

@Test func notificationManagerNotifyDailySummaryDoesNotCrash() {
    // Must not crash — guard should handle both bare binary and zero-count cases
    NotificationManager.shared.notifyDailySummary(noteCount: 0)
    NotificationManager.shared.notifyDailySummary(noteCount: 5)
}

@Test func notificationManagerDailySummaryZeroCountNoOp() {
    // noteCount == 0 should early-return without attempting notification
    NotificationManager.shared.notifyDailySummary(noteCount: 0)
    // No crash = pass. The guard `noteCount > 0` ensures early return.
}
