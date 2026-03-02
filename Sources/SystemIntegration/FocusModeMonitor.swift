import Foundation
import Shared

/// Monitors macOS Focus mode (Do Not Disturb) and optionally pauses capture.
public actor FocusModeMonitor {
    private var isMonitoring = false
    private var observer: NSObjectProtocol?
    private var onFocusChanged: ((Bool) -> Void)?

    public init() {}

    /// Start observing Focus mode changes.
    public func startMonitoring(onFocusChanged: @escaping (Bool) -> Void) {
        guard !isMonitoring else { return }
        self.onFocusChanged = onFocusChanged

        // Monitor DND/Focus via DistributedNotificationCenter
        let center = DistributedNotificationCenter.default()
        observer = center.addObserver(
            forName: NSNotification.Name("com.apple.accessibility.api.focus.status"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            Task { await self.handleFocusNotification(notification) }
        }

        isMonitoring = true
        SMLogger.system.info("Focus mode monitoring started")
    }

    /// Stop observing.
    public func stopMonitoring() {
        if let observer {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
        observer = nil
        isMonitoring = false
    }

    /// Check if Do Not Disturb / Focus is currently active.
    /// Uses NSWorkspace shared workspace focus state.
    public nonisolated func isFocusActive() -> Bool {
        // Check DND mirror defaults (undocumented but reliable)
        let dndDefaults = UserDefaults(suiteName: "com.apple.ncprefs")
        return dndDefaults?.bool(forKey: "dnd_prefs_enabled") ?? false
    }

    private func handleFocusNotification(_ notification: Notification) {
        let focusActive = isFocusActive()
        SMLogger.system.info("Focus mode changed: \(focusActive ? "active" : "inactive")")

        // Only pause if user opted in
        if UserDefaults.standard.bool(forKey: "pauseDuringFocus") {
            onFocusChanged?(focusActive)
        }
    }
}
