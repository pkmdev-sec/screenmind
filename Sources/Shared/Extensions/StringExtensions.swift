import Foundation

public extension String {
    /// Truncate to a maximum length with ellipsis.
    func truncated(to maxLength: Int) -> String {
        if count <= maxLength { return self }
        return String(prefix(maxLength - 1)) + "…"
    }

    /// Convert to a safe filename (remove special characters).
    var safeFilename: String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ "))
        return components(separatedBy: allowed.inverted)
            .joined()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()
    }

    /// Convert to Obsidian-compatible tag format.
    var obsidianTag: String {
        lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-")).inverted)
            .joined()
    }
}
