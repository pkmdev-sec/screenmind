import Foundation
import Shared

/// Manages the Obsidian vault directory structure for ScreenMind notes.
public struct VaultManager: Sendable {
    private let vaultPath: String

    public init(vaultPath: String? = nil) {
        let path = vaultPath
            ?? UserDefaults.standard.string(forKey: "obsidianVaultPath")
            ?? AppConstants.Obsidian.defaultVaultPath
        let expanded = (path as NSString).expandingTildeInPath
        self.vaultPath = expanded

        // Auto-create the vault + ScreenMind subfolder on first use
        let screenMindDir = (expanded as NSString).appendingPathComponent(AppConstants.Obsidian.subfolder)
        if !FileManager.default.fileExists(atPath: screenMindDir) {
            try? FileManager.default.createDirectory(atPath: screenMindDir, withIntermediateDirectories: true)
            SMLogger.storage.info("Created vault directory: \(screenMindDir)")
        }
    }

    /// Full path to the ScreenMind subfolder in the vault.
    public var screenMindRoot: URL {
        URL(fileURLWithPath: vaultPath)
            .appendingPathComponent(AppConstants.Obsidian.subfolder)
    }

    /// Daily folder path: ScreenMind/YYYY-MM-DD/
    public func dailyFolder(for date: Date = .now) -> URL {
        screenMindRoot.appendingPathComponent(date.dateFolderName)
    }

    /// Ensure the daily folder exists, creating it if necessary.
    public func ensureDailyFolder(for date: Date = .now) throws -> URL {
        let folder = dailyFolder(for: date)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    /// Check if the vault root exists and is writable.
    public var isVaultAccessible: Bool {
        let path = (vaultPath as NSString).expandingTildeInPath
        return FileManager.default.isWritableFile(atPath: path)
    }

    /// List all daily folders in the ScreenMind subfolder.
    public func listDailyFolders() throws -> [URL] {
        let root = screenMindRoot
        guard FileManager.default.fileExists(atPath: root.path) else { return [] }
        let contents = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey])
        return contents.filter { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
        }.sorted { $0.lastPathComponent > $1.lastPathComponent }
    }
}
