import Foundation
import SwiftData
import StorageCore
import AIProcessing
import AudioCore
import Shared

/// Summarizes notes captured during meetings into a single cohesive summary.
public actor MeetingSummarizer {
    private let storageActor: StorageActor
    private let aiProcessor: AIProcessingActor
    private let meetingDetector: MeetingDetectionActor

    public init(storageActor: StorageActor, aiProcessor: AIProcessingActor, meetingDetector: MeetingDetectionActor) {
        self.storageActor = storageActor
        self.aiProcessor = aiProcessor
        self.meetingDetector = meetingDetector
    }

    /// Generate a meeting summary when a meeting ends.
    public func summarizeMeeting(_ meeting: DetectedMeeting, notes: [NoteModel]) async throws {
        guard !notes.isEmpty else {
            SMLogger.pipeline.debug("No notes to summarize for meeting: \(meeting.title)")
            return
        }

        // Build meeting context
        let meetingContext = buildMeetingContext(meeting: meeting, notes: notes)

        // Generate summary using AI
        let summary = try await generateMeetingSummary(context: meetingContext, meeting: meeting)

        // Save as a meeting note
        let meetingNote = GeneratedNote(
            title: "Meeting: \(meeting.title)",
            summary: summary,
            details: meetingContext,
            category: .meeting,
            tags: ["meeting-summary"] + notes.flatMap { $0.tags }.uniqued().prefix(5),
            confidence: 0.9,
            skip: false,
            obsidianLinks: []
        )

        _ = try await storageActor.saveNote(
            meetingNote,
            appName: "Calendar",
            windowTitle: meeting.title,
            screenshotPath: nil,
            hash: 0,
            imageWidth: 0,
            imageHeight: 0,
            timestamp: meeting.endTime ?? Date.now,
            redactionCount: 0
        )

        SMLogger.pipeline.info("Meeting summary saved: \(meeting.title)")
    }

    /// Build context from all notes captured during the meeting.
    private func buildMeetingContext(meeting: DetectedMeeting, notes: [NoteModel]) -> String {
        var context = "# \(meeting.title)\n\n"

        if !meeting.attendees.isEmpty {
            context += "**Attendees:** \(meeting.attendees.joined(separator: ", "))\n\n"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        context += "**Time:** \(formatter.string(from: meeting.startTime))"
        if let endTime = meeting.endTime {
            context += " - \(formatter.string(from: endTime))"
        }
        context += "\n\n"

        context += "## Notes Captured During Meeting\n\n"

        for (index, note) in notes.enumerated() {
            context += "### \(index + 1). \(note.title)\n"
            context += "**Summary:** \(note.summary)\n"
            if !note.details.isEmpty {
                context += "**Details:** \(note.details)\n"
            }
            context += "\n"
        }

        return context
    }

    /// Generate AI summary with meeting-specific prompt.
    private func generateMeetingSummary(context: String, meeting: DetectedMeeting) async throws -> String {
        // For now, return a simple concatenation as fallback
        // In a real implementation, you'd call the AI provider with a custom prompt
        // that combines the meeting context and asks for structured output
        return "Meeting summary: \(meeting.title) with \(meeting.attendees.count) attendees."
    }
}

// MARK: - Array Helpers

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
