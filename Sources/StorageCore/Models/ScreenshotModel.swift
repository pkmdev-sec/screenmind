import Foundation
import SwiftData

/// SwiftData model for stored screenshot metadata.
@Model
public final class ScreenshotModel {
    public var id: UUID
    public var filePath: String
    public var hash: Int64
    public var width: Int
    public var height: Int
    public var capturedAt: Date

    @Relationship(inverse: \NoteModel.screenshot)
    public var note: NoteModel?

    public init(
        filePath: String,
        hash: Int64,
        width: Int,
        height: Int,
        capturedAt: Date = .now
    ) {
        self.id = UUID()
        self.filePath = filePath
        self.hash = hash
        self.width = width
        self.height = height
        self.capturedAt = capturedAt
    }
}
