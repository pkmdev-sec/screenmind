import Foundation
import SwiftData
import Shared
import AIProcessing

/// Actor-isolated persistence layer for notes and screenshots.
@ModelActor
public actor StorageActor {
    private let obsidianWriter = ObsidianNoteWriter()
    private let summaryWriter = DailySummaryWriter()

    /// Save a generated note with optional screenshot data.
    public func saveNote(
        _ generatedNote: GeneratedNote,
        appName: String,
        windowTitle: String?,
        screenshotPath: String?,
        hash: UInt64,
        imageWidth: Int,
        imageHeight: Int,
        timestamp: Date
    ) throws -> NoteModel {
        let noteModel = NoteModel(
            title: generatedNote.title,
            summary: generatedNote.summary,
            details: generatedNote.details,
            category: generatedNote.category.rawValue,
            tags: generatedNote.tags,
            confidence: generatedNote.confidence,
            appName: appName,
            windowTitle: windowTitle,
            obsidianLinks: generatedNote.obsidianLinks
        )

        if let path = screenshotPath {
            let screenshotModel = ScreenshotModel(
                filePath: path,
                hash: Int64(bitPattern: hash),
                width: imageWidth,
                height: imageHeight,
                capturedAt: timestamp
            )
            noteModel.screenshot = screenshotModel
            modelContext.insert(screenshotModel)
        }

        let appContext = try findOrCreateAppContext(appName: appName)
        appContext.totalNotes += 1
        appContext.lastSeenAt = timestamp
        noteModel.appContext = appContext

        modelContext.insert(noteModel)
        try modelContext.save()

        // Export to Obsidian
        do {
            _ = try obsidianWriter.write(
                note: generatedNote,
                appName: appName,
                windowTitle: windowTitle,
                timestamp: timestamp
            )
            noteModel.obsidianExported = true
            try modelContext.save()
        } catch {
            SMLogger.storage.warning("Obsidian export failed: \(error.localizedDescription)")
        }

        SMLogger.storage.info("Note saved: \(generatedNote.title)")
        return noteModel
    }

    /// Fetch notes for a date range.
    public func fetchNotes(from startDate: Date, to endDate: Date) throws -> [NoteModel] {
        let descriptor = FetchDescriptor<NoteModel>(
            predicate: #Predicate { note in
                note.createdAt >= startDate && note.createdAt <= endDate
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch today's notes.
    public func fetchTodayNotes() throws -> [NoteModel] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return try fetchNotes(from: startOfDay, to: endOfDay)
    }

    /// Search notes by text query.
    public func searchNotes(query: String) throws -> [NoteModel] {
        let descriptor = FetchDescriptor<NoteModel>(
            predicate: #Predicate { note in
                note.title.localizedStandardContains(query) ||
                note.summary.localizedStandardContains(query) ||
                note.details.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get total note count.
    public func noteCount() throws -> Int {
        let descriptor = FetchDescriptor<NoteModel>()
        return try modelContext.fetchCount(descriptor)
    }

    /// Delete all notes and screenshots from SwiftData.
    public func deleteAllNotes() throws -> Int {
        let noteDescriptor = FetchDescriptor<NoteModel>()
        let notes = try modelContext.fetch(noteDescriptor)
        let screenshotDescriptor = FetchDescriptor<ScreenshotModel>()
        let screenshots = try modelContext.fetch(screenshotDescriptor)
        let appContextDescriptor = FetchDescriptor<AppContextModel>()
        let appContexts = try modelContext.fetch(appContextDescriptor)

        let count = notes.count
        for note in notes { modelContext.delete(note) }
        for screenshot in screenshots { modelContext.delete(screenshot) }
        for ctx in appContexts { modelContext.delete(ctx) }
        try modelContext.save()
        SMLogger.storage.info("Deleted all data: \(count) notes, \(screenshots.count) screenshots")
        return count
    }

    /// Delete notes older than retention period.
    public func pruneOldNotes(olderThan days: Int = AppConstants.Storage.retentionDays) throws -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now)!
        let descriptor = FetchDescriptor<NoteModel>(
            predicate: #Predicate { note in
                note.createdAt < cutoff
            }
        )
        let oldNotes = try modelContext.fetch(descriptor)
        for note in oldNotes {
            modelContext.delete(note)
        }
        try modelContext.save()
        SMLogger.storage.info("Pruned \(oldNotes.count) notes older than \(days) days")
        return oldNotes.count
    }

    /// Generate daily summary in Obsidian.
    public func writeDailySummary() throws {
        let todayNotes = try fetchTodayNotes()
        try summaryWriter.writeSummary(notes: todayNotes)
    }

    // MARK: - Private

    private func findOrCreateAppContext(appName: String) throws -> AppContextModel {
        let descriptor = FetchDescriptor<AppContextModel>(
            predicate: #Predicate { ctx in
                ctx.appName == appName
            }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        let newContext = AppContextModel(appName: appName)
        modelContext.insert(newContext)
        return newContext
    }
}
