import Foundation
import CoreGraphics
import AppKit
import Shared

/// Monitors user activity to switch between active/idle capture intervals.
public actor ActivityMonitorActor {
    private var lastActivityDate: Date = .now
    private var eventMonitor: Any?

    public init() {}

    /// Whether the user has been active in the last 30 seconds.
    public var isUserActive: Bool {
        Date.now.timeIntervalSince(lastActivityDate) < 30
    }

    /// Returns the appropriate capture interval based on activity.
    public func currentInterval(config: CaptureConfiguration) -> TimeInterval {
        isUserActive ? config.activeInterval : config.idleInterval
    }

    /// Start monitoring user activity via global event monitoring.
    public func startMonitoring() {
        guard eventMonitor == nil else { return } // Prevent double-start
        let mask: NSEvent.EventTypeMask = [.mouseMoved, .keyDown, .leftMouseDown, .rightMouseDown, .scrollWheel]
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] _ in
            guard let self else { return }
            Task { await self.recordActivity() }
        }
        SMLogger.capture.info("Activity monitoring started")
    }

    /// Stop monitoring and release the event monitor.
    public func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
            SMLogger.capture.info("Activity monitoring stopped")
        }
    }

    /// Record that user activity occurred.
    public func recordActivity() {
        lastActivityDate = .now
    }
}
