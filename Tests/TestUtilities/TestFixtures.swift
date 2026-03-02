import Foundation
import CoreGraphics
import AIProcessing
import CaptureCore

/// Shared test fixtures for all test targets.
public enum TestFixtures {
    /// Create a solid-color CGImage for testing.
    public static func makeSolidColorImage(
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

    /// Create a GeneratedNote fixture.
    public static func makeGeneratedNote(
        title: String = "Test Note",
        summary: String = "Test summary",
        details: String = "Test details",
        category: AIProcessing.NoteCategory = .coding,
        tags: [String] = ["test"],
        confidence: Double = 0.9,
        skip: Bool = false,
        obsidianLinks: [String] = []
    ) -> AIProcessing.GeneratedNote {
        AIProcessing.GeneratedNote(
            title: title,
            summary: summary,
            details: details,
            category: category,
            tags: tags,
            confidence: confidence,
            skip: skip,
            obsidianLinks: obsidianLinks
        )
    }

    /// Create a CapturedFrame fixture.
    public static func makeCapturedFrame(
        image: CGImage? = nil,
        timestamp: Date = .now,
        appName: String = "TestApp",
        windowTitle: String? = "Test Window",
        bundleIdentifier: String? = "com.test.app",
        displayID: CGDirectDisplayID = CGMainDisplayID(),
        isManualCapture: Bool = false
    ) -> CaptureCore.CapturedFrame {
        let frameImage = image ?? makeSolidColorImage()
        return CaptureCore.CapturedFrame(
            image: frameImage,
            timestamp: timestamp,
            appName: appName,
            windowTitle: windowTitle,
            bundleIdentifier: bundleIdentifier,
            displayID: displayID,
            isManualCapture: isManualCapture
        )
    }
}
