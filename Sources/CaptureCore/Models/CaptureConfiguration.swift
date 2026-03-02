import Foundation
import Shared

/// Configuration for screen capture behavior.
public struct CaptureConfiguration: Sendable {
    public var activeInterval: TimeInterval
    public var idleInterval: TimeInterval
    public var maxWidth: Int
    public var excludedBundleIDs: Set<String>
    public var eventDrivenEnabled: Bool
    public var minDebounceInterval: TimeInterval
    public var typingPauseThreshold: TimeInterval
    public var scrollStopThreshold: TimeInterval
    public var visualChangeFallback: TimeInterval

    public init(
        activeInterval: TimeInterval = AppConstants.Capture.activeInterval,
        idleInterval: TimeInterval = AppConstants.Capture.idleInterval,
        maxWidth: Int = 1920,
        excludedBundleIDs: Set<String> = [],
        eventDrivenEnabled: Bool = true,
        minDebounceInterval: TimeInterval = 0.2,
        typingPauseThreshold: TimeInterval = 0.5,
        scrollStopThreshold: TimeInterval = 0.3,
        visualChangeFallback: TimeInterval = 3.0
    ) {
        self.activeInterval = activeInterval
        self.idleInterval = idleInterval
        self.maxWidth = maxWidth
        self.excludedBundleIDs = excludedBundleIDs
        self.eventDrivenEnabled = eventDrivenEnabled
        self.minDebounceInterval = minDebounceInterval
        self.typingPauseThreshold = typingPauseThreshold
        self.scrollStopThreshold = scrollStopThreshold
        self.visualChangeFallback = visualChangeFallback
    }
}
