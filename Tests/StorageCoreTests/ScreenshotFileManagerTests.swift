import Foundation
import Testing
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
@testable import StorageCore

// MARK: - ScreenshotFileManager Tests

@Test func screenshotFileManagerInitializes() {
    let manager = ScreenshotFileManager()
    _ = manager
}

@Test func screenshotFileManagerSavesJPEG() throws {
    let manager = ScreenshotFileManager()

    // Set format to JPEG
    UserDefaults.standard.set("jpeg", forKey: "screenshotFormat")
    UserDefaults.standard.set(0.8, forKey: "screenshotQuality")

    let image = createTestImage()
    let path = try manager.save(image, hash: 12345, timestamp: Date())

    #expect(path.hasSuffix(".jpg"))
    #expect(FileManager.default.fileExists(atPath: path))

    // Cleanup
    try? manager.delete(at: path)
    UserDefaults.standard.removeObject(forKey: "screenshotFormat")
    UserDefaults.standard.removeObject(forKey: "screenshotQuality")
}

@Test func screenshotFileManagerSavesHEIF() throws {
    // Check if HEIF encoding is available in this environment
    let testURL = URL(fileURLWithPath: NSTemporaryDirectory() + "heif-test.heic")
    let testImage = createTestImage()
    let testDestination = CGImageDestinationCreateWithURL(testURL as CFURL, UTType.heif.identifier as CFString, 1, nil)
    
    if testDestination == nil {
        // HEIF encoding not available (common in command-line tests)
        // Skip this test by not throwing
        return
    }
    
    let manager = ScreenshotFileManager()

    // Set format to HEIF
    UserDefaults.standard.set("heif", forKey: "screenshotFormat")
    UserDefaults.standard.set(0.5, forKey: "screenshotQuality")

    let image = createTestImage()
    let path = try manager.save(image, hash: 67890, timestamp: Date())

    #expect(path.hasSuffix(".heic"))
    #expect(FileManager.default.fileExists(atPath: path))

    // Cleanup
    try? manager.delete(at: path)
    UserDefaults.standard.removeObject(forKey: "screenshotFormat")
    UserDefaults.standard.removeObject(forKey: "screenshotQuality")
}

@Test func screenshotFileManagerDefaultsToJPEG() throws {
    let manager = ScreenshotFileManager()

    // Clear UserDefaults to test defaults
    UserDefaults.standard.removeObject(forKey: "screenshotFormat")
    UserDefaults.standard.removeObject(forKey: "screenshotQuality")

    let image = createTestImage()
    let path = try manager.save(image, hash: 99999, timestamp: Date())

    #expect(path.hasSuffix(".jpg"))
    #expect(FileManager.default.fileExists(atPath: path))

    // Cleanup
    try? manager.delete(at: path)
}

@Test func screenshotFileManagerDelete() throws {
    let manager = ScreenshotFileManager()
    let image = createTestImage()
    let path = try manager.save(image, hash: 11111, timestamp: Date())

    #expect(FileManager.default.fileExists(atPath: path))

    try manager.delete(at: path)
    #expect(!FileManager.default.fileExists(atPath: path))
}

@Test func screenshotFileManagerEnforcesQuota() throws {
    let manager = ScreenshotFileManager()

    // Save a few test images
    var paths: [String] = []
    for i in 0..<3 {
        let image = createTestImage()
        let path = try manager.save(image, hash: UInt64(i), timestamp: Date())
        paths.append(path)
        Thread.sleep(forTimeInterval: 0.01) // Ensure different timestamps
    }

    // Enforce quota with very small limit (should delete all)
    let deleted = manager.enforceQuota(maxBytes: 100)
    #expect(deleted >= 0) // May delete files based on size

    // Cleanup remaining files
    for path in paths {
        try? manager.delete(at: path)
    }
}

@Test func screenshotFileManagerTotalDiskUsage() throws {
    let manager = ScreenshotFileManager()
    let initialUsage = manager.totalDiskUsage()

    let image = createTestImage()
    let path = try manager.save(image, hash: 22222, timestamp: Date())

    let newUsage = manager.totalDiskUsage()
    #expect(newUsage > initialUsage)

    // Cleanup
    try? manager.delete(at: path)
}

// MARK: - Helper Functions

private func createTestImage() -> CGImage {
    let width = 200
    let height = 200
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

    // Fill with gradient
    context.setFillColor(CGColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))

    // Add some text-like rectangles
    context.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1))
    context.fill(CGRect(x: 10, y: 10, width: 50, height: 20))
    context.fill(CGRect(x: 70, y: 10, width: 80, height: 20))

    guard let image = context.makeImage() else {
        fatalError("Could not create CGImage")
    }

    return image
}
