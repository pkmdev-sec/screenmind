import Foundation
import CoreGraphics

/// A single captured screen frame with metadata.
public struct CapturedFrame: Sendable {
    public let image: CGImage
    public let timestamp: Date
    public let appName: String
    public let windowTitle: String?
    public let bundleIdentifier: String?
    public let displayID: CGDirectDisplayID
    public let isManualCapture: Bool
    public let processIdentifier: pid_t?

    public init(
        image: CGImage,
        timestamp: Date = .now,
        appName: String,
        windowTitle: String? = nil,
        bundleIdentifier: String? = nil,
        displayID: CGDirectDisplayID = CGMainDisplayID(),
        isManualCapture: Bool = false,
        processIdentifier: pid_t? = nil
    ) {
        self.image = image
        self.timestamp = timestamp
        self.appName = appName
        self.windowTitle = windowTitle
        self.bundleIdentifier = bundleIdentifier
        self.displayID = displayID
        self.isManualCapture = isManualCapture
        self.processIdentifier = processIdentifier
    }
}
