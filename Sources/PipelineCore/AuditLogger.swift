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

    // MARK: - GDPR & Compliance

    /// Export all user data for GDPR compliance (right to data portability).
    /// Exports audit logs, notes metadata, and system settings.
    /// - Returns: Path to exported JSON file
    public func exportGDPRData() throws -> String {
        let exportDate = Date()
        let exportPath = logDirectory.appendingPathComponent("gdpr-export-\(exportDate.dateFolderName).json")

        // Collect all user data
        var gdprData: [String: Any] = [:]

        // 1. Audit logs
        let logs = listLogFiles()
        var allLogEntries: [[String: String]] = []
        for logFile in logs {
            if let content = try? String(contentsOf: logFile, encoding: .utf8) {
                let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty && !$0.hasPrefix("timestamp,") }
                for line in lines {
                    let fields = parseCSVLine(line)
                    if fields.count >= 4 {
                        allLogEntries.append([
                            "timestamp": fields[0],
                            "action": fields[1],
                            "app": fields[2],
                            "reason": fields[3]
                        ])
                    }
                }
            }
        }
        gdprData["audit_logs"] = allLogEntries

        // 2. System settings (privacy-related)
        let settings: [String: Any] = [
            "audit_log_enabled": UserDefaults.standard.bool(forKey: "privacyAuditLogEnabled"),
            "compliance_mode": UserDefaults.standard.bool(forKey: "complianceMode"),
            "data_retention_days": UserDefaults.standard.integer(forKey: "dataRetentionDays"),
            "sync_enabled": UserDefaults.standard.bool(forKey: "syncEnabled"),
            "sso_enabled": UserDefaults.standard.bool(forKey: "ssoEnabled")
        ]
        gdprData["settings"] = settings

        // 3. Export metadata
        gdprData["export_metadata"] = [
            "exported_at": ISO8601DateFormatter().string(from: exportDate),
            "export_version": "1.0",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ]

        // Write to JSON
        let jsonData = try JSONSerialization.data(withJSONObject: gdprData, options: [.prettyPrinted, .sortedKeys])
        try jsonData.write(to: exportPath)

        SMLogger.pipeline.info("GDPR data exported: \(exportPath.lastPathComponent)")
        return exportPath.path
    }

    /// Delete user data older than retention period (GDPR right to erasure).
    /// - Parameter retentionDays: Number of days to retain data (default from settings)
    /// - Returns: Number of log entries deleted
    public func applyDataRetentionPolicy(retentionDays: Int? = nil) throws -> Int {
        let days = retentionDays ?? UserDefaults.standard.integer(forKey: "dataRetentionDays")
        guard days > 0 else {
            SMLogger.pipeline.warning("Data retention policy disabled (0 days)")
            return 0
        }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let logs = listLogFiles()

        var deletedCount = 0
        for logFile in logs {
            // Extract date from filename (audit-YYYY-MM-DD.csv)
            let filename = logFile.lastPathComponent
            if let dateString = filename.split(separator: "-").dropFirst().prefix(3).joined(separator: "-").split(separator: ".").first,
               let fileDate = dateFormatter.date(from: String(dateString)) {
                if fileDate < cutoffDate {
                    // Count entries before deletion
                    if let content = try? String(contentsOf: logFile, encoding: .utf8) {
                        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty && !$0.hasPrefix("timestamp,") }
                        deletedCount += lines.count
                    }

                    try? FileManager.default.removeItem(at: logFile)
                    SMLogger.pipeline.info("Deleted old audit log: \(filename)")
                }
            }
        }

        if deletedCount > 0 {
            SMLogger.pipeline.info("Data retention policy applied: deleted \(deletedCount) entries older than \(days) days")
        }

        return deletedCount
    }

    /// Generate compliance report for auditing purposes.
    /// Includes data handling summary, retention status, and access patterns.
    /// - Returns: Compliance report as dictionary
    public func generateComplianceReport() -> [String: Any] {
        let logs = listLogFiles()
        var report: [String: Any] = [:]

        // 1. Data retention status
        let retentionDays = UserDefaults.standard.integer(forKey: "dataRetentionDays")
        let oldestLog = logs.last
        let newestLog = logs.first

        report["data_retention"] = [
            "retention_policy_days": retentionDays,
            "oldest_log_date": oldestLog?.lastPathComponent ?? "none",
            "newest_log_date": newestLog?.lastPathComponent ?? "none",
            "total_log_files": logs.count
        ]

        // 2. Action breakdown
        var actionCounts: [String: Int] = [:]
        var appCounts: [String: Int] = [:]
        var totalEntries = 0

        for logFile in logs {
            if let content = try? String(contentsOf: logFile, encoding: .utf8) {
                let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty && !$0.hasPrefix("timestamp,") }
                totalEntries += lines.count

                for line in lines {
                    let fields = parseCSVLine(line)
                    if fields.count >= 3 {
                        let action = fields[1]
                        let app = fields[2]
                        actionCounts[action, default: 0] += 1
                        appCounts[app, default: 0] += 1
                    }
                }
            }
        }

        report["action_breakdown"] = actionCounts
        report["top_apps"] = Array(appCounts.sorted { $0.value > $1.value }.prefix(10))
        report["total_entries"] = totalEntries

        // 3. Privacy controls status
        report["privacy_controls"] = [
            "audit_logging_enabled": UserDefaults.standard.bool(forKey: "privacyAuditLogEnabled"),
            "compliance_mode_enabled": UserDefaults.standard.bool(forKey: "complianceMode"),
            "data_encryption_enabled": UserDefaults.standard.bool(forKey: "encryptionEnabled")
        ]

        // 4. Report metadata
        report["report_generated_at"] = ISO8601DateFormatter().string(from: Date())
        report["report_version"] = "1.0"

        return report
    }

    // MARK: - Private

    private func currentLogFile() -> URL {
        let filename = "audit-\(Date().dateFolderName).csv"
        return logDirectory.appendingPathComponent(filename)
    }

    private func parseCSVLine(_ line: String) -> [String] {
        // Simple CSV parser (handles quoted fields)
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false

        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }

        fields.append(currentField)
        return fields
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

// MARK: - UserDefaults Extensions

extension UserDefaults {
    /// Whether compliance mode is enabled (stricter privacy controls).
    public var complianceMode: Bool {
        get { bool(forKey: "complianceMode") }
        set { set(newValue, forKey: "complianceMode") }
    }

    /// Data retention policy in days (0 = keep forever).
    public var dataRetentionDays: Int {
        get { integer(forKey: "dataRetentionDays") }
        set { set(newValue, forKey: "dataRetentionDays") }
    }

    /// Data retention policy string representation.
    public var dataRetentionPolicy: String {
        let days = dataRetentionDays
        if days == 0 {
            return "indefinite"
        } else if days <= 30 {
            return "30_days"
        } else if days <= 90 {
            return "90_days"
        } else if days <= 365 {
            return "1_year"
        } else {
            return "custom_\(days)_days"
        }
    }
}
