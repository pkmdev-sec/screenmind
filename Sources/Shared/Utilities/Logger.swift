import Foundation
import OSLog

/// Centralized logging for ScreenMind using OSLog.
public enum SMLogger {
    private static let subsystem = AppConstants.bundleIdentifier

    public static let capture = Logger(subsystem: subsystem, category: "capture")
    public static let detection = Logger(subsystem: subsystem, category: "detection")
    public static let ocr = Logger(subsystem: subsystem, category: "ocr")
    public static let ai = Logger(subsystem: subsystem, category: "ai")
    public static let storage = Logger(subsystem: subsystem, category: "storage")
    public static let pipeline = Logger(subsystem: subsystem, category: "pipeline")
    public static let system = Logger(subsystem: subsystem, category: "system")
    public static let ui = Logger(subsystem: subsystem, category: "ui")
    public static let general = Logger(subsystem: subsystem, category: "general")
}
