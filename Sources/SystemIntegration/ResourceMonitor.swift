import Foundation
import Shared

/// Monitors system resource usage (CPU, RAM, battery) for the ScreenMind process.
/// Provides live stats for the Performance dashboard.
public actor ResourceMonitor {
    public static let shared = ResourceMonitor()

    /// Snapshot of current resource usage.
    public struct ResourceSnapshot: Sendable {
        public let cpuPercent: Double
        public let memoryMB: Double
        public let batteryLevel: Int
        public let isOnBattery: Bool
        public let isLowPower: Bool
        public let timestamp: Date

        public init(cpuPercent: Double, memoryMB: Double, batteryLevel: Int, isOnBattery: Bool, isLowPower: Bool, timestamp: Date = .now) {
            self.cpuPercent = cpuPercent
            self.memoryMB = memoryMB
            self.batteryLevel = batteryLevel
            self.isOnBattery = isOnBattery
            self.isLowPower = isLowPower
            self.timestamp = timestamp
        }
    }

    /// Pipeline throughput stats.
    public struct ThroughputStats: Sendable {
        public var totalFramesCaptured: UInt64 = 0
        public var framesFiltered: UInt64 = 0
        public var framesOCRd: UInt64 = 0
        public var notesGenerated: UInt64 = 0
        public var notesSkippedByAI: UInt64 = 0
        public var notesSkippedByRules: UInt64 = 0
        public var redactionsApplied: UInt64 = 0
        public var avgOCRTimeMs: Double = 0
        public var avgAITimeMs: Double = 0
        public var sessionStartTime: Date = .now
        public var lastNoteTime: Date?

        public var notesPerHour: Double {
            let elapsed = Date.now.timeIntervalSince(sessionStartTime)
            guard elapsed > 60 else { return 0 }
            return Double(notesGenerated) / (elapsed / 3600)
        }

        public var uptime: TimeInterval {
            Date.now.timeIntervalSince(sessionStartTime)
        }
    }

    private var throughput = ThroughputStats()
    private let powerMonitor = PowerStateMonitor()
    private let processStartTime = Date.now
    private var lastCPUTime: Double = 0
    private var lastCPUSampleTime: Date = .now

    private init() {
        // Initialize CPU baseline
        lastCPUTime = Self.totalProcessCPUTime()
        lastCPUSampleTime = .now
    }

    /// Get current resource snapshot.
    public func currentResources() async -> ResourceSnapshot {
        let cpu = deltaCPUUsage()
        let memory = Self.processMemoryMB()
        let power = await powerMonitor.currentState()

        return ResourceSnapshot(
            cpuPercent: cpu,
            memoryMB: memory,
            batteryLevel: power.batteryLevel,
            isOnBattery: power.isOnBattery,
            isLowPower: power.isLowPower
        )
    }

    /// Get current throughput stats.
    public func currentThroughput() -> ThroughputStats {
        throughput
    }

    // MARK: - Stat Recording (called from pipeline)

    public func recordFrameCaptured() { throughput.totalFramesCaptured += 1 }
    public func recordFrameFiltered() { throughput.framesFiltered += 1 }
    public func recordOCRComplete(timeMs: Double) {
        throughput.framesOCRd += 1
        let total = throughput.avgOCRTimeMs * Double(throughput.framesOCRd - 1) + timeMs
        throughput.avgOCRTimeMs = total / Double(throughput.framesOCRd)
    }
    public func recordNoteGenerated(aiTimeMs: Double) {
        throughput.notesGenerated += 1
        throughput.lastNoteTime = .now
        let total = throughput.avgAITimeMs * Double(throughput.notesGenerated - 1) + aiTimeMs
        throughput.avgAITimeMs = total / Double(throughput.notesGenerated)
    }
    public func recordNoteSkippedByAI() { throughput.notesSkippedByAI += 1 }
    public func recordNoteSkippedByRule() { throughput.notesSkippedByRules += 1 }
    public func recordRedaction(count: Int) { throughput.redactionsApplied += UInt64(count) }

    public func resetSession() {
        throughput = ThroughputStats()
    }

    // MARK: - System Resource Measurement

    /// Get delta-based CPU usage percentage for the current process.
    /// Uses the difference between two samples to show recent (not cumulative) CPU usage.
    private func deltaCPUUsage() -> Double {
        let currentCPUTime = Self.totalProcessCPUTime()
        let now = Date.now
        let elapsed = now.timeIntervalSince(lastCPUSampleTime)
        guard elapsed > 0.1 else { return 0 } // Avoid division by near-zero

        let cpuDelta = currentCPUTime - lastCPUTime
        lastCPUTime = currentCPUTime
        lastCPUSampleTime = now

        return (cpuDelta / elapsed) * 100 // Percentage of one core
    }

    /// Get total CPU time (user + system) consumed by this process in seconds.
    private static func totalProcessCPUTime() -> Double {
        var taskInfo = task_basic_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_basic_info_data_t>.size / MemoryLayout<natural_t>.size)

        let result = withUnsafeMutablePointer(to: &taskInfo) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }

        let userTime = Double(taskInfo.user_time.seconds) + Double(taskInfo.user_time.microseconds) / 1_000_000
        let systemTime = Double(taskInfo.system_time.seconds) + Double(taskInfo.system_time.microseconds) / 1_000_000
        return userTime + systemTime
    }

    /// Get memory usage in MB for the current process.
    private static func processMemoryMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { ptr in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), ptr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }
        return Double(info.resident_size) / 1_048_576 // bytes to MB
    }
}

