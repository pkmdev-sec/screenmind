import Testing
import Foundation
import CoreGraphics
@testable import OCRProcessing
@testable import ChangeDetection
@testable import CaptureCore

// MARK: - OCRQueueActor Tests

@Test func ocrQueueActorInitializes() async {
    let queue = OCRQueueActor()
    let depth = await queue.queueDepth
    #expect(depth == 0)
}

@Test func ocrQueueActorEnqueueAndBackpressure() async {
    let queue = OCRQueueActor()

    // Create dummy frames
    let dummyImage = createDummyImage()
    let frames = (0..<7).map { i in
        let frame = CapturedFrame(
            image: dummyImage,
            timestamp: Date(),
            appName: "Test",
            windowTitle: "Test Window",
            bundleIdentifier: "com.test.app",
            isManualCapture: false
        )
        return SignificantFrame(frame: frame, hash: UInt64(i), differenceScore: 1.0)
    }

    // Enqueue 7 frames (max queue size is 5)
    for frame in frames {
        _ = await queue.enqueue(frame)
    }

    // Queue should cap at 5 (backpressure drops oldest)
    let depth = await queue.queueDepth
    #expect(depth == 5)
}

@Test func ocrQueueActorConcurrencySettings() async {
    // Test default concurrency
    UserDefaults.standard.removeObject(forKey: "ocrMaxConcurrency")
    let queue1 = OCRQueueActor()
    // Can't directly test maxConcurrency as it's private, but we can test that it initializes

    // Test custom concurrency
    UserDefaults.standard.set(5, forKey: "ocrMaxConcurrency")
    let queue2 = OCRQueueActor()
    // Verify initialization doesn't crash

    // Cleanup
    UserDefaults.standard.removeObject(forKey: "ocrMaxConcurrency")
}

@Test func ocrQueueActorStopClearsQueue() async {
    let queue = OCRQueueActor()
    let dummyImage = createDummyImage()
    let frame = CapturedFrame(
        image: dummyImage,
        timestamp: Date(),
        appName: "Test",
        windowTitle: "Test",
        bundleIdentifier: "com.test.app",
        isManualCapture: false
    )
    let sigFrame = SignificantFrame(frame: frame, hash: 123, differenceScore: 1.0)

    _ = await queue.enqueue(sigFrame)
    var depth = await queue.queueDepth
    #expect(depth == 1)

    await queue.stop()
    depth = await queue.queueDepth
    #expect(depth == 0)
}

// MARK: - Helper Functions

private func createDummyImage() -> CGImage {
    let width = 100
    let height = 100
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo.rawValue
    ) else {
        fatalError("Could not create CGContext")
    }

    // Fill with white
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))

    guard let image = context.makeImage() else {
        fatalError("Could not create CGImage")
    }

    return image
}
