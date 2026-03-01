import Foundation

public extension Date {
    /// ISO 8601 formatted string for Obsidian frontmatter.
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }

    /// Formatted as "YYYY-MM-DD" for directory naming.
    var dateFolderName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

    /// Human-readable relative time ("2 min ago", "1 hr ago").
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: .now)
    }
}
