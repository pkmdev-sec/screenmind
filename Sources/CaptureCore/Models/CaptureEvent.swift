import Foundation

/// Events that trigger screen captures in event-driven mode.
public enum CaptureEvent: Sendable {
    case appSwitch(bundleID: String)
    case windowFocus(title: String)
    case typingPause
    case scrollStop
    case clipboard
    case visualChange(score: Double)
    case idle
    case manual

    public var isManual: Bool {
        if case .manual = self { return true }
        return false
    }
}
