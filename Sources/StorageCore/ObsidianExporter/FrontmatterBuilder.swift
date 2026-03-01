import Foundation
import Shared

/// Builds YAML frontmatter for Obsidian-compatible markdown notes.
public enum FrontmatterBuilder {

    /// Generate YAML frontmatter string for a note.
    public static func build(
        title: String,
        category: String,
        tags: [String],
        appName: String,
        windowTitle: String?,
        confidence: Double,
        createdAt: Date
    ) -> String {
        var lines = [
            "---",
            "title: \"\(escapeYAML(title))\"",
            "date: \(createdAt.iso8601String)",
            "category: \(category)",
            "app: \(appName)",
            "source: \(AppConstants.Obsidian.sourceTag)",
            "confidence: \(String(format: "%.2f", confidence))",
        ]

        if let windowTitle {
            lines.append("window: \"\(escapeYAML(windowTitle))\"")
        }

        if !tags.isEmpty {
            lines.append("tags:")
            for tag in tags {
                lines.append("  - \(tag)")
            }
        }

        lines.append("---")
        return lines.joined(separator: "\n")
    }

    private static func escapeYAML(_ text: String) -> String {
        text.replacingOccurrences(of: "\"", with: "\\\"")
    }
}
