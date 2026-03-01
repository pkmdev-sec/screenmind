import Foundation
import Shared

/// Actor-based audit logger that records all pipeline actions to a CSV file.
/// Provides transparency for users to see what was captured, skipped, redacted, and exported.
public actor AuditLogger {

    /// Pipeline actions that can be logged.
    public enum AuditAction: String, Sendable {
        case captured = "captured"
        case skipped = "skipped"
        case redacted = "redacted"
        case exported = "exported"
        case deleted = "deleted"
        case encrypted = "encrypted"
    }

    private let logDirectory: URL
    private let dateFormatter: DateFormatter

    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.logDirectory = appSupport
            .appendingPathComponent(AppConstants.bundleIdentifier)
            .appendingPathComponent("AuditLogs")
        try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)

        self.dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    }

    /// Log a pipeline action.
    public func log(action: AuditAction, appName: String, reason: String) {
        let enabled = UserDefaults.standard.object(forKey: "privacyAuditLogEnabled") as? Bool ?? true
        guard enabled else { return }

        let timestamp = dateFormatter.string(from: Date())
        let truncatedReason = String(reason.prefix(500))
        let csvLine = "\(escapeCSV(timestamp)),\(escapeCSV(action.rawValue)),\(escapeCSV(appName)),\(escapeCSV(truncatedReason))\n"

        let logFile = currentLogFile()
        appendToFile(csvLine, at: logFile)
    }

    /// Get the path to the current day's audit log.
    public func currentLogPath() -> String {
        currentLogFile().path
    }

    /// List all audit log files.
    public func listLogFiles() -> [URL] {
        guard FileManager.default.fileExists(atPath: logDirectory.path) else { return [] }
        let files = (try? FileManager.default.contentsOfDirectory(at: logDirectory, includingPropertiesForKeys: [.creationDateKey]))
        return (files ?? [])
            .filter { $0.pathExtension == "csv" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    /// Export all audit logs to a single CSV file. Returns the file path.
    public func exportAllLogs() throws -> String {
        let files = listLogFiles()
        let exportPath = logDirectory.appendingPathComponent("audit-export-\(Date().dateFolderName).csv")

        var combined = "timestamp,action,app,reason\n"
        for file in files.reversed() {
            if let content = try? String(contentsOf: file, encoding: .utf8) {
                // Skip header if any, just append lines
                let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty && !$0.hasPrefix("timestamp,") }
                combined += lines.joined(separator: "\n") + "\n"
            }
        }

        try combined.write(to: exportPath, atomically: true, encoding: .utf8)
        SMLogger.pipeline.info("Audit log exported: \(exportPath.lastPathComponent)")
        return exportPath.path
    }

    /// Total number of log entries across all files.
    public func totalEntryCount() -> Int {
        let files = listLogFiles()
        var count = 0
        for file in files {
            if let content = try? String(contentsOf: file, encoding: .utf8) {
                count += content.components(separatedBy: "\n").filter { !$0.isEmpty && !$0.hasPrefix("timestamp,") }.count
            }
        }
        return count
    }

    /// Clear all audit logs.
    public func clearAllLogs() {
        let files = listLogFiles()
        for file in files {
            try? FileManager.default.removeItem(at: file)
        }
        SMLogger.pipeline.info("Audit logs cleared")
    }

    // MARK: - Private

    private func currentLogFile() -> URL {
        let filename = "audit-\(Date().dateFolderName).csv"
        return logDirectory.appendingPathComponent(filename)
    }

    private func appendToFile(_ text: String, at url: URL) {
        if !FileManager.default.fileExists(atPath: url.path) {
            // Write header + first line
            let header = "timestamp,action,app,reason\n"
            try? (header + text).write(to: url, atomically: true, encoding: .utf8)
        } else {
            // Append
            if let handle = try? FileHandle(forWritingTo: url) {
                defer { handle.closeFile() }
                handle.seekToEndOfFile()
                if let data = text.data(using: .utf8) {
                    handle.write(data)
                }
            }
        }
    }

    private func escapeCSV(_ text: String) -> String {
        if text.contains(",") || text.contains("\"") || text.contains("\n") || text.contains("\r") {
            let sanitized = text
                .replacingOccurrences(of: "\"", with: "\"\"")
                .replacingOccurrences(of: "\r\n", with: " ")
                .replacingOccurrences(of: "\r", with: " ")
            return "\"\(sanitized)\""
        }
        return text
    }
}
