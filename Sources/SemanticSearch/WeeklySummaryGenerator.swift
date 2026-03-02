import Foundation
import Shared

/// Generates "This Week in Review" summaries from note data.
public struct WeeklySummaryGenerator: Sendable {

    /// Weekly summary data.
    public struct WeeklySummary: Sendable {
        public let weekStart: Date
        public let weekEnd: Date
        public let totalNotes: Int
        public let topApps: [(app: String, count: Int)]
        public let topCategories: [(category: String, count: Int)]
        public let topTags: [(tag: String, count: Int)]
        public let projectBreakdown: [(project: String, count: Int)]
        public let highlights: [String] // Top note titles
        public let notesPerDay: [String: Int] // "Mon" -> 12
    }

    /// Generate a weekly summary from note data.
    public static func generate(
        notes: [(title: String, category: String, appName: String, tags: [String], project: String?, createdAt: Date)]
    ) -> WeeklySummary {
        let calendar = Calendar.current
        let now = Date.now
        let weekStart = calendar.date(byAdding: .day, value: -7, to: now)!

        // App breakdown
        var appCounts: [String: Int] = [:]
        var categoryCounts: [String: Int] = [:]
        var tagCounts: [String: Int] = [:]
        var projectCounts: [String: Int] = [:]
        var dayCounts: [String: Int] = [:]
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        for note in notes {
            appCounts[note.appName, default: 0] += 1
            categoryCounts[note.category, default: 0] += 1
            for tag in note.tags { tagCounts[tag, default: 0] += 1 }
            if let project = note.project { projectCounts[project, default: 0] += 1 }
            let day = dayFormatter.string(from: note.createdAt)
            dayCounts[day, default: 0] += 1
        }

        let topApps = appCounts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
        let topCategories = categoryCounts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
        let topTags = tagCounts.sorted { $0.value > $1.value }.prefix(10).map { ($0.key, $0.value) }
        let projectBreakdown = projectCounts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
        let highlights = Array(notes.prefix(5).map(\.title))

        return WeeklySummary(
            weekStart: weekStart,
            weekEnd: now,
            totalNotes: notes.count,
            topApps: topApps,
            topCategories: topCategories,
            topTags: topTags,
            projectBreakdown: projectBreakdown,
            highlights: highlights,
            notesPerDay: dayCounts
        )
    }
}
