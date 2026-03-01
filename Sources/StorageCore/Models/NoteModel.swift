import Foundation
import SwiftData

/// SwiftData model for persisted notes.
@Model
public final class NoteModel {
    public var id: UUID
    public var title: String
    public var summary: String
    public var details: String
    public var category: String
    public var tags: [String]
    public var confidence: Double
    public var appName: String
    public var windowTitle: String?
    public var createdAt: Date
    public var obsidianLinks: [String]
    public var obsidianExported: Bool
    public var redactionCount: Int = 0

    @Relationship(deleteRule: .cascade)
    public var screenshot: ScreenshotModel?

    @Relationship(deleteRule: .nullify)
    public var appContext: AppContextModel?

    public init(
        title: String,
        summary: String,
        details: String,
        category: String,
        tags: [String],
        confidence: Double,
        appName: String,
        windowTitle: String? = nil,
        obsidianLinks: [String] = [],
        obsidianExported: Bool = false,
        redactionCount: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.summary = summary
        self.details = details
        self.category = category
        self.tags = tags
        self.confidence = confidence
        self.appName = appName
        self.windowTitle = windowTitle
        self.createdAt = .now
        self.obsidianLinks = obsidianLinks
        self.obsidianExported = obsidianExported
        self.redactionCount = redactionCount
    }
}
