import Foundation
import AIProcessing

/// Test fixture factory for creating test data.
public enum TestFixtures {
    /// Create a test GeneratedNote with optional customizations.
    public static func makeGeneratedNote(
        title: String = "Test Note",
        summary: String = "Test summary",
        details: String = "Test details",
        category: NoteCategory = .other,
        tags: [String] = ["test"],
        confidence: Double = 0.9,
        skip: Bool = false,
        obsidianLinks: [String] = []
    ) -> GeneratedNote {
        return GeneratedNote(
            title: title,
            summary: summary,
            details: details,
            category: category,
            tags: tags,
            confidence: confidence,
            skip: skip,
            obsidianLinks: obsidianLinks
        )
    }
}
