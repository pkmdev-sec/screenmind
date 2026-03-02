import Testing
import CoreGraphics
@testable import ChangeDetection

@Test func screenshotDifferInitializes() {
    let differ = ScreenshotDiffer()
    // Should initialize without errors
}

@Test func screenshotDifferIdenticalImagesNoChange() {
    let differ = ScreenshotDiffer()
    let image = ChangeDetectionTestFixtures.makeSolidColorImage(
        width: 200,
        height: 150,
        red: 0.5,
        green: 0.5,
        blue: 0.5
    )

    let regions = differ.diff(image1: image, image2: image)
    #expect(regions.isEmpty)
}

@Test func screenshotDifferCompletelyDifferentImages() {
    let differ = ScreenshotDiffer()
    let image1 = ChangeDetectionTestFixtures.makeSolidColorImage(
        width: 200,
        height: 150,
        red: 0.0,
        green: 0.0,
        blue: 0.0
    )
    let image2 = ChangeDetectionTestFixtures.makeSolidColorImage(
        width: 200,
        height: 150,
        red: 1.0,
        green: 1.0,
        blue: 1.0
    )

    let regions = differ.diff(image1: image1, image2: image2)
    #expect(!regions.isEmpty)
    #expect(regions.count > 0)

    // Should detect large change across entire image
    if let firstRegion = regions.first {
        #expect(firstRegion.changePercent > 0.5)
    }
}

@Test func screenshotDifferPartialChange() {
    let differ = ScreenshotDiffer(
        config: ScreenshotDiffer.Configuration(
            targetWidth: 100,
            changeThreshold: 30,
            minRegionSize: 10
        )
    )

    // Create two images with a localized change
    let image1 = ChangeDetectionTestFixtures.makeSolidColorImage(
        width: 200,
        height: 200,
        red: 0.3,
        green: 0.3,
        blue: 0.3
    )

    // Create image2 by drawing on top of image1
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: 200,
        height: 200,
        bitsPerComponent: 8,
        bytesPerRow: 200 * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return }

    // Draw base image
    context.draw(image1, in: CGRect(x: 0, y: 0, width: 200, height: 200))

    // Draw a white square in the center (50x50)
    context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
    context.fill(CGRect(x: 75, y: 75, width: 50, height: 50))

    guard let image2 = context.makeImage() else { return }

    let regions = differ.diff(image1: image1, image2: image2)

    // Should detect at least one changed region
    #expect(!regions.isEmpty)

    // The changed region should be localized (not the entire image)
    if let firstRegion = regions.first {
        #expect(firstRegion.changePercent < 0.5)
        #expect(firstRegion.changePercent > 0.0)
    }
}

@Test func screenshotDifferMinRegionSizeFilter() {
    let differ = ScreenshotDiffer(
        config: ScreenshotDiffer.Configuration(
            targetWidth: 100,
            changeThreshold: 30,
            minRegionSize: 1000 // Very high threshold
        )
    )

    let image1 = ChangeDetectionTestFixtures.makeSolidColorImage(
        width: 200,
        height: 200,
        red: 0.5,
        green: 0.5,
        blue: 0.5
    )

    // Create image with small change
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: 200,
        height: 200,
        bitsPerComponent: 8,
        bytesPerRow: 200 * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return }

    context.draw(image1, in: CGRect(x: 0, y: 0, width: 200, height: 200))
    context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
    context.fill(CGRect(x: 10, y: 10, width: 10, height: 10)) // Small 10x10 change

    guard let image2 = context.makeImage() else { return }

    let regions = differ.diff(image1: image1, image2: image2)

    // Small change should be filtered out by minRegionSize
    #expect(regions.isEmpty)
}
