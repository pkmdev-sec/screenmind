import Foundation
import SwiftData

/// SwiftData model for app context (which app was being used).
@Model
public final class AppContextModel {
    public var id: UUID
    public var appName: String
    public var bundleIdentifier: String?
    public var totalNotes: Int
    public var lastSeenAt: Date

    @Relationship(inverse: \NoteModel.appContext)
    public var notes: [NoteModel]

    public init(
        appName: String,
        bundleIdentifier: String? = nil
    ) {
        self.id = UUID()
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.totalNotes = 0
        self.lastSeenAt = .now
        self.notes = []
    }
}
