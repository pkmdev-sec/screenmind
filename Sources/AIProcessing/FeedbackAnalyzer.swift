import Foundation

/// Protocol for notes with rating information (avoids circular dependency).
public protocol RatedNote {
    var userRating: Int? { get }
    var summary: String { get }
    var details: String { get }
    var category: String { get }
    var tags: [String] { get }
}

/// Analyzes user feedback patterns to adapt AI prompts.
public actor FeedbackAnalyzer {
    public init() {}

    /// Analyze rated notes to extract prompt modifiers.
    public func analyzePatterns(from notes: [any RatedNote]) -> [String] {
        var modifiers: [String] = []

        let ratedNotes = notes.filter { $0.userRating != nil }
        guard ratedNotes.count >= 5 else {
            // Need at least 5 rated notes for meaningful analysis
            return []
        }

        let upvoted = ratedNotes.filter { $0.userRating == 1 }
        let downvoted = ratedNotes.filter { $0.userRating == -1 }

        // Analyze summary length preference
        if !upvoted.isEmpty {
            let avgUpvotedSummaryLength = upvoted.map { $0.summary.count }.reduce(0, +) / upvoted.count
            let avgDownvotedSummaryLength = downvoted.isEmpty ? 0 : downvoted.map { $0.summary.count }.reduce(0, +) / downvoted.count

            if avgUpvotedSummaryLength < 100 && avgDownvotedSummaryLength > 150 {
                modifiers.append("User prefers concise summaries (1 sentence max).")
            } else if avgUpvotedSummaryLength > 200 {
                modifiers.append("User prefers detailed summaries with more context.")
            }
        }

        // Analyze detail level preference
        if !upvoted.isEmpty {
            let avgUpvotedDetailsLength = upvoted.map { $0.details.count }.reduce(0, +) / upvoted.count
            let avgDownvotedDetailsLength = downvoted.isEmpty ? 0 : downvoted.map { $0.details.count }.reduce(0, +) / downvoted.count

            if avgUpvotedDetailsLength > avgDownvotedDetailsLength + 100 {
                modifiers.append("User values comprehensive details with specific data points.")
            } else if avgUpvotedDetailsLength < 100 {
                modifiers.append("User prefers minimal details, only key takeaways.")
            }
        }

        // Analyze category preferences
        let categoryRatings: [String: (up: Int, down: Int)] = ratedNotes.reduce(into: [:]) { acc, note in
            let key = note.category
            let current = acc[key] ?? (up: 0, down: 0)
            if note.userRating == 1 {
                acc[key] = (up: current.up + 1, down: current.down)
            } else if note.userRating == -1 {
                acc[key] = (up: current.up, down: current.down + 1)
            }
        }

        for (category, ratings) in categoryRatings {
            if ratings.up > ratings.down + 2 {
                modifiers.append("User particularly values '\(category)' notes — prioritize these.")
            } else if ratings.down > ratings.up + 2 {
                modifiers.append("User dislikes '\(category)' notes — be more selective.")
            }
        }

        // Analyze tag preferences
        var tagUpvotes: [String: Int] = [:]
        var tagDownvotes: [String: Int] = [:]

        for note in upvoted {
            for tag in note.tags {
                tagUpvotes[tag, default: 0] += 1
            }
        }

        for note in downvoted {
            for tag in note.tags {
                tagDownvotes[tag, default: 0] += 1
            }
        }

        let topUpvotedTags = tagUpvotes.sorted { $0.value > $1.value }.prefix(3)
        if !topUpvotedTags.isEmpty {
            let tags = topUpvotedTags.map { $0.key }.joined(separator: ", ")
            modifiers.append("User frequently upvotes notes with tags: \(tags).")
        }

        return modifiers
    }

    /// Save analyzed modifiers to UserDefaults.
    public func saveModifiers(_ modifiers: [String]) {
        guard let data = try? JSONEncoder().encode(modifiers) else { return }
        UserDefaults.standard.set(data, forKey: "aiFeedbackModifiers")
    }

    /// Load saved modifiers from UserDefaults.
    public static func loadModifiers() -> [String] {
        guard let data = UserDefaults.standard.data(forKey: "aiFeedbackModifiers"),
              let modifiers = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return modifiers
    }
}
