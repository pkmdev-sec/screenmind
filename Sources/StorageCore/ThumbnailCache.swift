import Foundation
import AppKit
import CryptoKit
import Shared

/// In-memory + disk thumbnail cache for screenshot previews.
/// Thread-safety: NSCache is internally thread-safe for concurrent reads/writes.
/// Disk writes happen on detached tasks and don't share mutable state.
public final class ThumbnailCache: @unchecked Sendable {
    public static let shared = ThumbnailCache()

    private let memoryCache = NSCache<NSString, NSImage>()
    private let thumbnailSize: CGFloat = 240
    private let cacheDirectory: URL

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = caches.appendingPathComponent("com.screenmind.thumbnails")
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        memoryCache.countLimit = 200
    }

    /// Get or generate a thumbnail for a screenshot file path.
    public func thumbnail(for filePath: String) -> NSImage? {
        let key = filePath as NSString

        // Check memory cache
        if let cached = memoryCache.object(forKey: key) {
            return cached
        }

        // Check disk cache
        let diskPath = diskCachePath(for: filePath)
        if let diskImage = NSImage(contentsOf: diskPath) {
            memoryCache.setObject(diskImage, forKey: key)
            return diskImage
        }

        // Generate from source (supports encrypted .enc files)
        guard FileManager.default.fileExists(atPath: filePath) else { return nil }

        let sourceImage: NSImage?
        if filePath.hasSuffix(".enc") {
            // Decrypt encrypted screenshot
            guard let decryptedData = try? ScreenshotEncryptor.decrypt(Data(contentsOf: URL(fileURLWithPath: filePath))),
                  let image = NSImage(data: decryptedData) else {
                return nil
            }
            sourceImage = image
        } else {
            sourceImage = NSImage(contentsOfFile: filePath)
        }

        guard let sourceImage else { return nil }

        let thumbnail = resized(image: sourceImage, maxDimension: thumbnailSize)
        memoryCache.setObject(thumbnail, forKey: key)

        // Save to disk cache asynchronously
        Task.detached(priority: .utility) { [diskPath, thumbnail] in
            guard let tiffData = thumbnail.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else {
                SMLogger.storage.warning("Thumbnail: failed to encode image for \(filePath)")
                return
            }
            do {
                try jpegData.write(to: diskPath)
            } catch {
                SMLogger.storage.warning("Thumbnail: disk write failed for \(filePath): \(error.localizedDescription)")
            }
        }

        return thumbnail
    }

    /// Clear all cached thumbnails.
    public func clearAll() {
        SMLogger.storage.info("Clearing all thumbnail caches")
        memoryCache.removeAllObjects()
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Private

    /// Produce a stable, collision-resistant cache key from the file path using SHA256.
    private func diskCachePath(for filePath: String) -> URL {
        let hash = SHA256.hash(data: Data(filePath.utf8))
        let hexString = hash.prefix(16).map { String(format: "%02x", $0) }.joined()
        return cacheDirectory.appendingPathComponent("\(hexString).thumb.jpg")
    }

    /// Resize image using modern NSGraphicsContext API (no deprecated lockFocus).
    private func resized(image: NSImage, maxDimension: CGFloat) -> NSImage {
        let sourceSize = image.size
        guard sourceSize.width > 0, sourceSize.height > 0 else { return image }

        let scale: CGFloat
        if sourceSize.width > sourceSize.height {
            scale = maxDimension / sourceSize.width
        } else {
            scale = maxDimension / sourceSize.height
        }

        if scale >= 1.0 { return image }

        let newSize = NSSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
        let newImage = NSImage(size: newSize, flipped: false) { rect in
            image.draw(in: rect, from: NSRect(origin: .zero, size: sourceSize), operation: .copy, fraction: 1.0)
            return true
        }
        return newImage
    }
}
