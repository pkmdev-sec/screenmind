import Foundation
import CaptureCore
import Shared

/// Detects meaningful screen changes using perceptual hashing with a rolling window.
public actor ChangeDetectionActor {
    private let threshold: Double
    private let windowSize: Int
    private var hashWindow: [UInt64] = []
    private var lastEmittedHash: UInt64?
    private var frameCount: UInt64 = 0
    private var filteredCount: UInt64 = 0

    public init(
        threshold: Double = AppConstants.Detection.defaultThreshold,
        windowSize: Int = AppConstants.Detection.rollingWindowSize
    ) {
        self.threshold = threshold
        self.windowSize = windowSize
    }

    /// Process a captured frame and return a SignificantFrame if it passes change detection.
    public func process(_ frame: CapturedFrame) -> SignificantFrame? {
        frameCount += 1
        let hash = PerceptualHasher.hash(of: frame.image)

        // First frame is always significant
        guard let previousHash = lastEmittedHash else {
            lastEmittedHash = hash
            appendToWindow(hash)
            SMLogger.detection.info("First frame captured — hash=\(hash)")
            return SignificantFrame(frame: frame, hash: hash, differenceScore: 1.0)
        }

        let difference = ImageDifferentiator.difference(hash1: previousHash, hash2: hash)

        // Check against rolling window average to reduce flicker
        let windowAvg = averageWindowDifference(newHash: hash)
        let effectiveDifference = max(difference, windowAvg)

        appendToWindow(hash)

        guard effectiveDifference >= threshold else {
            filteredCount += 1
            return nil
        }

        lastEmittedHash = hash
        SMLogger.detection.debug("Significant change: \(String(format: "%.3f", effectiveDifference)) (threshold: \(self.threshold))")
        return SignificantFrame(frame: frame, hash: hash, differenceScore: effectiveDifference)
    }

    /// Stats for monitoring.
    public var stats: (total: UInt64, filtered: UInt64, passed: UInt64) {
        (frameCount, filteredCount, frameCount - filteredCount)
    }

    public func reset() {
        hashWindow.removeAll()
        lastEmittedHash = nil
        frameCount = 0
        filteredCount = 0
    }

    // MARK: - Private

    private func appendToWindow(_ hash: UInt64) {
        hashWindow.append(hash)
        if hashWindow.count > windowSize {
            hashWindow.removeFirst()
        }
    }

    private func averageWindowDifference(newHash: UInt64) -> Double {
        guard !hashWindow.isEmpty else { return 1.0 }
        let total = hashWindow.reduce(0.0) { sum, h in
            sum + ImageDifferentiator.difference(hash1: h, hash2: newHash)
        }
        return total / Double(hashWindow.count)
    }
}
