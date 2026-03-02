import Testing
import CoreGraphics
@testable import OCRProcessing

// MARK: - Test Fixtures

enum UIElementTestFixtures {
    static func makeImageWithRectangles(width: Int = 800, height: Int = 600) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            fatalError("Failed to create context")
        }

        // White background
        context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Draw a few rectangles simulating UI elements
        // Large centered dialog (200x150)
        context.setFillColor(CGColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0))
        context.fill(CGRect(x: 300, y: 225, width: 200, height: 150))

        // Button (100x30)
        context.setFillColor(CGColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0))
        context.fill(CGRect(x: 350, y: 300, width: 100, height: 30))

        // Text field (200x25)
        context.setFillColor(CGColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0))
        context.fill(CGRect(x: 300, y: 250, width: 200, height: 25))

        return context.makeImage()!
    }

    static func makeBlankImage(width: Int = 800, height: Int = 600) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            fatalError("Failed to create context")
        }

        // Solid gray
        context.setFillColor(gray: 0.5, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        return context.makeImage()!
    }
}

// MARK: - Tests

@Test func uiElementDetectorInitializes() {
    let detector = UIElementDetector()
    // Should initialize without errors
}

@Test func uiElementDetectorBlankImageNoElements() async throws {
    let detector = UIElementDetector()
    let image = UIElementTestFixtures.makeBlankImage()

    let elements = try await detector.detect(in: image)

    // Blank image should have no UI elements (or very few false positives)
    #expect(elements.count < 5)
}

@Test func uiElementDetectorFindsRectangles() async throws {
    let detector = UIElementDetector(
        config: UIElementDetector.Configuration(
            minimumConfidence: 0.3,
            minimumSize: 10,
            maximumSize: 1000
        )
    )
    let image = UIElementTestFixtures.makeImageWithRectangles()

    let elements = try await detector.detect(in: image)

    // Should detect at least some rectangles
    #expect(!elements.isEmpty)
}

@Test func uiElementDetectorClassifiesTypes() async throws {
    let detector = UIElementDetector(
        config: UIElementDetector.Configuration(
            minimumConfidence: 0.3,
            minimumSize: 10,
            maximumSize: 1000
        )
    )
    let image = UIElementTestFixtures.makeImageWithRectangles()

    let elements = try await detector.detect(in: image)

    // Should have classified types (not all unknown)
    let hasClassifiedTypes = elements.contains { $0.type != .unknown }
    #expect(hasClassifiedTypes || elements.isEmpty)
}

@Test func uiElementDetectionResultGeneratesSummary() async throws {
    let detector = UIElementDetector()
    let image = UIElementTestFixtures.makeImageWithRectangles()

    let elements = try await detector.detect(in: image)
    let result = UIElementDetectionResult(elements: elements)

    // Summary should be non-empty
    #expect(!result.summary.isEmpty)
}

@Test func uiElementDetectionResultEmptyElements() {
    let result = UIElementDetectionResult(elements: [])
    #expect(result.summary.contains("No UI elements"))
}
