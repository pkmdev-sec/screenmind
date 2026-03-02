import Foundation
import Shared

public actor PluginScheduler {
    private struct ScheduledEntry {
        let pluginID: String
        let intervalSeconds: TimeInterval
        var lastRun: Date?
    }

    private var entries: [ScheduledEntry] = []
    private var task: Task<Void, Never>?

    public init() {}

    public func start(engine: PluginEngine) {
        task = Task {
            while !Task.isCancelled {
                let now = Date.now
                for i in entries.indices {
                    let shouldRun: Bool
                    if let last = entries[i].lastRun {
                        shouldRun = now.timeIntervalSince(last) >= entries[i].intervalSeconds
                    } else { shouldRun = true }

                    if shouldRun {
                        self.entries[i].lastRun = now
                        let pluginID = self.entries[i].pluginID

                        // Execute plugin with 30-second timeout
                        let triggerTask = Task {
                            await engine.trigger(event: .timer, data: ["pluginID": pluginID, "timestamp": now.timeIntervalSince1970])
                        }

                        let timeoutTask = Task {
                            try? await Task.sleep(for: .seconds(30))
                            if !triggerTask.isCancelled {
                                SMLogger.system.warning("Plugin scheduled execution timeout: \(pluginID)")
                                triggerTask.cancel()
                            }
                        }

                        await triggerTask.value
                        timeoutTask.cancel()
                        SMLogger.system.info("Plugin scheduled: \(pluginID)")
                    }
                }
                try? await Task.sleep(for: .seconds(60))
            }
        }
    }

    public func stop() { task?.cancel(); task = nil }

    public func schedule(pluginID: String, intervalSeconds: TimeInterval) {
        entries.append(ScheduledEntry(pluginID: pluginID, intervalSeconds: intervalSeconds))
    }

    public func unschedule(pluginID: String) {
        entries.removeAll { $0.pluginID == pluginID }
    }

    public static func parseSchedule(_ schedule: String) -> TimeInterval? {
        let s = schedule.trimmingCharacters(in: .whitespaces).lowercased()
        guard s.hasPrefix("every ") else { return nil }
        let val = String(s.dropFirst(6))
        if val.hasSuffix("m"), let n = Int(val.dropLast()) { return TimeInterval(n * 60) }
        if val.hasSuffix("h"), let n = Int(val.dropLast()) { return TimeInterval(n * 3600) }
        if val.hasSuffix("d"), let n = Int(val.dropLast()) { return TimeInterval(n * 86400) }
        return nil
    }
}
