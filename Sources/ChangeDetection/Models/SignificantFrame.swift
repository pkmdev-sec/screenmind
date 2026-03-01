import Foundation
import CaptureCore

/// A frame that passed change detection — meaningful screen content changed.
public struct SignificantFrame: Sendable {
    public let frame: CapturedFrame
    public let hash: UInt64
    public let differenceScore: Double

    public init(frame: CapturedFrame, hash: UInt64, differenceScore: Double) {
        self.frame = frame
        self.hash = hash
        self.differenceScore = differenceScore
    }
}
