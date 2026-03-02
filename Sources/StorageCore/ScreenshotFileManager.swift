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

    /// Save a CGImage to disk in JPEG or HEIF format. Returns the file path.
    public func save(_ image: CGImage, hash: UInt64, timestamp: Date) throws -> String {
        let folder = baseDirectory.appendingPathComponent(timestamp.dateFolderName)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        // Get format and quality from UserDefaults
        let format = UserDefaults.standard.string(forKey: "screenshotFormat") ?? "jpeg"
        let quality = UserDefaults.standard.double(forKey: "screenshotQuality")
        let qualityValue = quality > 0 ? quality : (format == "heif" ? 0.5 : 0.6)

        let (utType, ext) = format == "heif" ? (UTType.heif, "heic") : (UTType.jpeg, "jpg")
        let filename = "\(Int(timestamp.timeIntervalSince1970))-\(hash).\(ext)"
        let fileURL = folder.appendingPathComponent(filename)

        guard let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, utType.identifier as CFString, 1, nil) else {
            throw ScreenshotError.createFailed
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: qualityValue as CFNumber
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

    /// Enforce storage quota by deleting oldest screenshots when over limit.
    /// Returns the number of files deleted.
    @discardableResult
    public func enforceQuota(maxBytes: Int64 = AppConstants.Storage.quotaBytes) -> Int {
        var currentUsage = totalDiskUsage()
        guard currentUsage > maxBytes else { return 0 }

        // Collect all screenshot files with creation dates
        guard FileManager.default.fileExists(atPath: baseDirectory.path) else { return 0 }
        var files: [(url: URL, date: Date, size: Int64)] = []

        if let enumerator = FileManager.default.enumerator(
            at: baseDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .creationDateKey]
        ) {
            while let url = enumerator.nextObject() as? URL {
                guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey]),
                      let size = values.fileSize,
                      let date = values.creationDate,
                      ["jpg", "heic", "enc"].contains(url.pathExtension) else { continue }
                files.append((url: url, date: date, size: Int64(size)))
            }
        }

        // Sort oldest first
        files.sort { $0.date < $1.date }

        var deleted = 0
        for file in files {
            guard currentUsage > maxBytes else { break }
            do {
                try FileManager.default.removeItem(at: file.url)
                currentUsage -= file.size
                deleted += 1
            } catch {
                SMLogger.storage.warning("Quota cleanup: failed to delete \(file.url.lastPathComponent): \(error.localizedDescription)")
            }
        }

        if deleted > 0 {
            SMLogger.storage.info("Quota enforcement: deleted \(deleted) screenshots, freed \(deleted > 0 ? "space" : "none")")
        }

        // Clean up empty day folders
        cleanEmptyDayFolders()

        return deleted
    }

    /// Remove empty day folders after quota cleanup.
    private func cleanEmptyDayFolders() {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: baseDirectory,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) else { return }

        for folder in contents {
            guard (try? folder.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else { continue }
            let items = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
            if items.isEmpty {
                try? FileManager.default.removeItem(at: folder)
            }
        }
    }
}

public enum ScreenshotError: Error {
    case createFailed
    case writeFailed
}
