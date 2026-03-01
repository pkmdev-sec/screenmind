import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Shared

/// Manages screenshot file storage on disk.
public struct ScreenshotFileManager: Sendable {
    private let baseDirectory: URL

    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.baseDirectory = appSupport
            .appendingPathComponent(AppConstants.bundleIdentifier)
            .appendingPathComponent(AppConstants.Storage.screenshotDirectory)
    }

    /// Save a CGImage as JPEG to disk. Returns the file path.
    public func save(_ image: CGImage, hash: UInt64, timestamp: Date) throws -> String {
        let folder = baseDirectory.appendingPathComponent(timestamp.dateFolderName)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let filename = "\(Int(timestamp.timeIntervalSince1970))-\(hash).jpg"
        let fileURL = folder.appendingPathComponent(filename)

        guard let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw ScreenshotError.createFailed
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.6
        ]
        CGImageDestinationAddImage(destination, image, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ScreenshotError.writeFailed
        }

        return fileURL.path
    }

    /// Delete a screenshot file.
    public func delete(at path: String) throws {
        try FileManager.default.removeItem(atPath: path)
    }

    /// Calculate total disk usage of screenshots.
    public func totalDiskUsage() -> Int64 {
        guard FileManager.default.fileExists(atPath: baseDirectory.path) else { return 0 }
        let enumerator = FileManager.default.enumerator(at: baseDirectory, includingPropertiesForKeys: [.fileSizeKey])
        var total: Int64 = 0
        while let url = enumerator?.nextObject() as? URL {
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            total += Int64(size)
        }
        return total
    }
}

public enum ScreenshotError: Error {
    case createFailed
    case writeFailed
}
