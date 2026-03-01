import Foundation
import CaptureCore

/// Text extracted from a screen frame via OCR.
public struct RecognizedText: Sendable {
    public let text: String
    public let averageConfidence: Double
    public let wordCount: Int
    public let processingTime: TimeInterval
    public let appName: String
    public let windowTitle: String?
    public let timestamp: Date

    public init(
        text: String,
        averageConfidence: Double,
        wordCount: Int,
        processingTime: TimeInterval,
        appName: String,
        windowTitle: String? = nil,
        timestamp: Date = .now
    ) {
        self.text = text
        self.averageConfidence = averageConfidence
        self.wordCount = wordCount
        self.processingTime = processingTime
        self.appName = appName
        self.windowTitle = windowTitle
        self.timestamp = timestamp
    }
}
