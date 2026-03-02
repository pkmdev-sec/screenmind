import Foundation
import CoreGraphics
import Shared

/// Monitors screen lock state to prevent captures when screen is locked.
public actor ScreenLockMonitor {
    private var locked = false
    private var pollTask: Task<Void, Never>?

    public init() {}

    public func startMonitoring() {
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.checkLockState()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    public func stopMonitoring() {
        pollTask?.cancel()
        pollTask = nil
    }

    public func isScreenLocked() -> Bool {
        locked
    }

    private func checkLockState() {
        if let dict = CGSessionCopyCurrentDictionary() as? [String: Any] {
            locked = dict["CGSSessionScreenIsLocked"] as? Bool ?? false
        } else {
            // Fail-safe: default to locked on API failure for privacy protection
            locked = true
            SMLogger.system.warning("CGSessionCopyCurrentDictionary failed — defaulting to locked state")
        }
    }
}
