import Foundation
import Shared

/// Configuration for screen capture behavior.
public struct CaptureConfiguration: Sendable {
    public var activeInterval: TimeInterval
    public var idleInterval: TimeInterval
    public var maxWidth: Int
    public var excludedBundleIDs: Set<String>

    public init(
        activeInterval: TimeInterval = AppConstants.Capture.activeInterval,
        idleInterval: TimeInterval = AppConstants.Capture.idleInterval,
        maxWidth: Int = 1920,
        excludedBundleIDs: Set<String> = []
    ) {
        self.activeInterval = activeInterval
        self.idleInterval = idleInterval
        self.maxWidth = maxWidth
        self.excludedBundleIDs = excludedBundleIDs
    }
}
