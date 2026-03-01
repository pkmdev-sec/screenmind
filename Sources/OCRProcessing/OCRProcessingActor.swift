import Foundation
import Shared
import ChangeDetection
import CaptureCore

/// Extracts and preprocesses text from significant screen frames.
public actor OCRProcessingActor {
    private var processedCount: UInt64 = 0
    private var totalProcessingTime: TimeInterval = 0

    public init() {}

    /// Process a significant frame through OCR and return recognized text.
    public func process(_ significantFrame: SignificantFrame) async -> RecognizedText? {
        let start = CFAbsoluteTimeGetCurrent()

        do {
            let rawResults = try await TextRecognizer.recognizeText(in: significantFrame.frame.image)

            guard !rawResults.isEmpty else {
                SMLogger.ocr.debug("No text found in frame")
                return nil
            }

            let (cleanText, avgConfidence, wordCount) = TextPreprocessor.clean(rawResults)

            guard wordCount >= 3 else {
                SMLogger.ocr.debug("Too few words (\(wordCount)), skipping frame")
                return nil
            }

            let elapsed = CFAbsoluteTimeGetCurrent() - start
            processedCount += 1
            totalProcessingTime += elapsed

            let truncatedText = TextPreprocessor.truncate(cleanText)

            SMLogger.ocr.debug("OCR: \(wordCount) words, confidence: \(String(format: "%.2f", avgConfidence)), time: \(String(format: "%.1f", elapsed * 1000))ms")

            return RecognizedText(
                text: truncatedText,
                averageConfidence: avgConfidence,
                wordCount: wordCount,
                processingTime: elapsed,
                appName: significantFrame.frame.appName,
                windowTitle: significantFrame.frame.windowTitle,
                timestamp: significantFrame.frame.timestamp
            )
        } catch {
            SMLogger.ocr.error("OCR failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Stats for monitoring.
    public var stats: (processed: UInt64, avgTime: TimeInterval) {
        let avg = processedCount > 0 ? totalProcessingTime / Double(processedCount) : 0
        return (processedCount, avg)
    }
}
