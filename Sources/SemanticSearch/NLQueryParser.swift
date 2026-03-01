import Foundation
import Shared

/// Parses natural language search queries into structured filters.
public struct NLQueryParser: Sendable {

    /// Parsed search filter.
    public struct SearchFilter: Sendable {
        public var dateRange: DateRange?
        public var category: String?
        public var appName: String?
        public var semanticQuery: String
        public var timeOfDay: TimeOfDay?

        public init(semanticQuery: String = "") {
            self.semanticQuery = semanticQuery
        }
    }

    public enum DateRange: Sendable {
        case today
        case yesterday
        case lastWeek
        case lastMonth
        case custom(from: Date, to: Date)

        public var dates: (from: Date, to: Date) {
            let cal = Calendar.current
            let now = Date.now
            switch self {
            case .today:
                return (cal.startOfDay(for: now), now)
            case .yesterday:
                let yesterday = cal.date(byAdding: .day, value: -1, to: now)!
                return (cal.startOfDay(for: yesterday), cal.startOfDay(for: now))
            case .lastWeek:
                return (cal.date(byAdding: .day, value: -7, to: now)!, now)
            case .lastMonth:
                return (cal.date(byAdding: .month, value: -1, to: now)!, now)
            case .custom(let from, let to):
                return (from, to)
            }
        }
    }

    public enum TimeOfDay: Sendable {
        case morning   // 6am-12pm
        case afternoon // 12pm-5pm
        case evening   // 5pm-9pm
        case night     // 9pm-6am
    }

    /// Parse a natural language query.
    public static func parse(_ query: String) -> SearchFilter {
        var filter = SearchFilter()
        var remaining = query.lowercased()

        // Date extraction
        if remaining.contains("today") {
            filter.dateRange = .today
            remaining = remaining.replacingOccurrences(of: "today", with: "")
        } else if remaining.contains("yesterday") {
            filter.dateRange = .yesterday
            remaining = remaining.replacingOccurrences(of: "yesterday", with: "")
        } else if remaining.contains("last week") || remaining.contains("this week") {
            filter.dateRange = .lastWeek
            remaining = remaining.replacingOccurrences(of: "last week", with: "").replacingOccurrences(of: "this week", with: "")
        } else if remaining.contains("last month") || remaining.contains("this month") {
            filter.dateRange = .lastMonth
            remaining = remaining.replacingOccurrences(of: "last month", with: "").replacingOccurrences(of: "this month", with: "")
        }

        // Time of day extraction
        if remaining.contains("morning") {
            filter.timeOfDay = .morning
            remaining = remaining.replacingOccurrences(of: "morning", with: "").replacingOccurrences(of: "in the ", with: "")
        } else if remaining.contains("afternoon") {
            filter.timeOfDay = .afternoon
            remaining = remaining.replacingOccurrences(of: "afternoon", with: "").replacingOccurrences(of: "in the ", with: "")
        } else if remaining.contains("evening") {
            filter.timeOfDay = .evening
            remaining = remaining.replacingOccurrences(of: "evening", with: "").replacingOccurrences(of: "in the ", with: "")
        }

        // Category extraction
        let categoryPatterns: [(keywords: [String], category: String)] = [
            (["coding", "code", "programming", "debug"], "coding"),
            (["meeting", "call", "standup", "sync"], "meeting"),
            (["research", "reading", "article", "paper"], "research"),
            (["email", "message", "chat", "slack"], "communication"),
            (["terminal", "shell", "command line", "bash"], "terminal"),
        ]
        for (keywords, category) in categoryPatterns {
            for keyword in keywords {
                if remaining.contains(keyword) {
                    filter.category = category
                    break
                }
            }
            if filter.category != nil { break }
        }

        // Clean up filler words
        let fillerWords = ["what", "was", "i", "working", "on", "show", "me", "find", "all", "notes", "about", "from", "the", "at", "in", "my", "a", "an"]
        let words = remaining.split(separator: " ").map(String.init)
        let meaningful = words.filter { !fillerWords.contains($0) && $0.count > 1 }
        filter.semanticQuery = meaningful.joined(separator: " ").trimmingCharacters(in: .whitespaces)

        return filter
    }
}
