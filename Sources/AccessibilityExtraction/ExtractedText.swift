import Foundation

public enum ExtractionSource: String, Sendable {
    case accessibility
    case ocr
}

public struct ExtractedText: Sendable {
    public let text: String
    public let source: ExtractionSource
    public let nodeCount: Int
    public let browserURL: String?
    public let extractionTime: TimeInterval

    public init(text: String, source: ExtractionSource, nodeCount: Int, browserURL: String? = nil, extractionTime: TimeInterval) {
        self.text = text
        self.source = source
        self.nodeCount = nodeCount
        self.browserURL = browserURL
        self.extractionTime = extractionTime
    }
}
