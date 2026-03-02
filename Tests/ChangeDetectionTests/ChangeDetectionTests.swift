import Testing
import CoreGraphics
@testable import ChangeDetection
@testable import CaptureCore

// MARK: - Test Fixtures

enum ChangeDetectionTestFixtures {
    static func makeSolidColorImage(
        width: Int = 100,
        height: Int = 100,
        red: CGFloat = 1.0,
        green: CGFloat = 0.0,
        blue: CGFloat = 0.0
    ) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(red: red, green: green, blue: blue, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }

    static func makeGradientImage(
        width: Int = 100,
        height: Int = 100,
        startGray: CGFloat = 0.0,
        endGray: CGFloat = 1.0
    ) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )!

        // Draw horizontal gradient
        for x in 0..<width {
            let t = CGFloat(x) / CGFloat(width - 1)
            let gray = startGray + (endGray - startGray) * t
            context.setFillColor(CGColor(gray: gray, alpha: 1.0))
            context.fill(CGRect(x: x, y: 0, width: 1, height: height))
        }

        return context.makeImage()!
    }

    static func makeCapturedFrame(
        image: CGImage? = nil,
        appName: String = "TestApp",
        isManualCapture: Bool = false
    ) -> CapturedFrame {
        let frameImage = image ?? makeSolidColorImage()
        return CapturedFrame(
            image: frameImage,
            appName: appName,
            isManualCapture: isManualCapture
        )
    }
}

// MARK: - ChangeDetectionActor Tests

@Test func changeDetectionActorInitializes() async {
    let actor = ChangeDetectionActor()
    let stats = await actor.stats
    #expect(stats.total == 0)
    #expect(stats.filtered == 0)
}

@Test func changeDetectionActorFirstFrameAlwaysPasses() async {
    let actor = ChangeDetectionActor()
    let frame = ChangeDetectionTestFixtures.makeCapturedFrame()
    let result = await actor.process(frame)

    #expect(result != nil)
    #expect(result?.differenceScore == 1.0)

    let stats = await actor.stats
    #expect(stats.total == 1)
    #expect(stats.passed == 1)
    #expect(stats.filtered == 0)
}

@Test func changeDetectionActorIdenticalFrameFiltered() async {
    let actor = ChangeDetectionActor(threshold: 0.1)
    let image = ChangeDetectionTestFixtures.makeSolidColorImage()

    // First frame
    let frame1 = ChangeDetectionTestFixtures.makeCapturedFrame(image: image)
    let result1 = await actor.process(frame1)
    #expect(result1 != nil)

    // Identical frame
    let frame2 = ChangeDetectionTestFixtures.makeCapturedFrame(image: image)
    let result2 = await actor.process(frame2)
    #expect(result2 == nil) // Filtered out

    let stats = await actor.stats
    #expect(stats.total == 2)
    #expect(stats.passed == 1)
    #expect(stats.filtered == 1)
}

@Test func changeDetectionActorSignificantChangePasses() async {
    let actor = ChangeDetectionActor(threshold: 0.1)

    // First frame - gradient left to right
    let image1 = ChangeDetectionTestFixtures.makeGradientImage(startGray: 0.0, endGray: 1.0)
    let frame1 = ChangeDetectionTestFixtures.makeCapturedFrame(image: image1)
    let result1 = await actor.process(frame1)
    #expect(result1 != nil)

    // Second frame - gradient right to left (significantly different)
    let image2 = ChangeDetectionTestFixtures.makeGradientImage(startGray: 1.0, endGray: 0.0)
    let frame2 = ChangeDetectionTestFixtures.makeCapturedFrame(image: image2)
    let result2 = await actor.process(frame2)
    #expect(result2 != nil) // Should pass threshold

    let stats = await actor.stats
    #expect(stats.total == 2)
    #expect(stats.passed == 2)
    #expect(stats.filtered == 0)
}

// MARK: - ImageDifferentiator Tests

@Test func imageDifferentiatorIdenticalHashes() {
    let diff = ImageDifferentiator.difference(hash1: 0xFFFF, hash2: 0xFFFF)
    #expect(diff == 0.0)
}

@Test func imageDifferentiatorOppositeHashes() {
    let diff = ImageDifferentiator.difference(hash1: 0, hash2: UInt64.max)
    #expect(diff == 1.0)
}

@Test func imageDifferentiatorSingleBitFlip() {
    let hash1: UInt64 = 0b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000
    let hash2: UInt64 = 0b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001
    let diff = ImageDifferentiator.difference(hash1: hash1, hash2: hash2)
    #expect(diff == 1.0 / 64.0) // 1 bit difference out of 64 bits
}

// MARK: - PerceptualHasher Tests

@Test func perceptualHasherIsDeterministic() {
    let image = ChangeDetectionTestFixtures.makeSolidColorImage()
    let hash1 = PerceptualHasher.hash(of: image)
    let hash2 = PerceptualHasher.hash(of: image)
    #expect(hash1 == hash2)
}

@Test func perceptualHasherDifferentImagesProduceDifferentHashes() {
    // Solid colors produce hash 0 because dHash compares adjacent pixels.
    // Create a gradient image instead for meaningful hash difference.
    let image1 = ChangeDetectionTestFixtures.makeGradientImage(startGray: 0.0, endGray: 1.0)
    let image2 = ChangeDetectionTestFixtures.makeGradientImage(startGray: 1.0, endGray: 0.0)

    let hash1 = PerceptualHasher.hash(of: image1)
    let hash2 = PerceptualHasher.hash(of: image2)

    #expect(hash1 != hash2)
}
