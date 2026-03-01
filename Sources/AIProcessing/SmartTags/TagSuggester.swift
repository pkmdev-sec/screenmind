import Foundation
import Shared

/// Suggests tags based on historical note patterns.
/// Learns from existing notes to suggest relevant tags for new content.
public struct TagSuggester: Sendable {

    /// Suggest tags for new content based on historical patterns.
    /// Analyzes app name, window title, and text content against stored tag frequencies.
    public static func suggest(
        appName: String,
        windowTitle: String?,
        textSample: String,
        existingTags: [String: Int] // tag -> frequency from history
    ) -> [String] {
        var suggestions: [(tag: String, score: Double)] = []

        let textLower = textSample.lowercased()
        let appLower = appName.lowercased()
        let windowLower = (windowTitle ?? "").lowercased()

        // 1. App-based tags (always suggest the app name as a tag)
        let appTag = appLower.replacingOccurrences(of: " ", with: "-")
        suggestions.append((appTag, 10.0))

        // 2. Content-based keyword detection
        let contentTags = detectContentTags(text: textLower, window: windowLower)
        for tag in contentTags {
            suggestions.append((tag, 5.0))
        }

        // 3. Historical frequency boost — tags used often get priority
        for (tag, freq) in existingTags {
            let tagLower = tag.lowercased()
            // Boost if tag appears in current content
            if textLower.contains(tagLower) || appLower.contains(tagLower) || windowLower.contains(tagLower) {
                suggestions.append((tag, Double(freq) * 2.0))
            }
        }

        // Deduplicate, sort by score, return top 5
        var seen = Set<String>()
        let unique = suggestions.filter { seen.insert($0.tag.lowercased()).inserted }
        return Array(unique.sorted { $0.score > $1.score }.prefix(5).map(\.tag))
    }

    /// Load tag frequencies from UserDefaults.
    public static func loadTagFrequencies() -> [String: Int] {
        guard let data = UserDefaults.standard.data(forKey: "smartTagFrequencies"),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return dict
    }

    /// Update tag frequencies after a note is saved.
    /// Thread-safe: uses a serial queue to prevent concurrent read-modify-write races.
    private static let writeQueue = DispatchQueue(label: "com.screenmind.tag-suggester")

    public static func recordTags(_ tags: [String]) {
        writeQueue.sync {
            var frequencies = loadTagFrequencies()
            for tag in tags {
                frequencies[tag, default: 0] += 1
            }
            // Keep only top 200 tags to prevent unbounded growth (amortized: only prune when > 210)
            if frequencies.count > 210 {
                let sorted = frequencies.sorted { $0.value > $1.value }
                frequencies = Dictionary(uniqueKeysWithValues: Array(sorted.prefix(200)).map { ($0.key, $0.value) })
            }
            if let data = try? JSONEncoder().encode(frequencies) {
                UserDefaults.standard.set(data, forKey: "smartTagFrequencies")
            }
        }
    }

    // MARK: - Content Detection

    /// Detect tags from text content using keyword patterns.
    private static func detectContentTags(text: String, window: String) -> [String] {
        var tags: [String] = []

        // Technology detection
        let techPatterns: [(keywords: [String], tag: String)] = [
            (["swift", "swiftui", "xcode", ".swift"], "swift"),
            (["python", ".py", "pip install", "django", "flask"], "python"),
            (["javascript", "typescript", ".js", ".ts", "node", "npm", "react", "vue"], "javascript"),
            (["rust", "cargo", ".rs"], "rust"),
            (["docker", "container", "kubernetes", "k8s"], "devops"),
            (["git ", "commit", "pull request", "merge", "branch"], "git"),
            (["api", "endpoint", "rest", "graphql", "fetch"], "api"),
            (["database", "sql", "postgres", "mysql", "mongodb", "redis"], "database"),
            (["test", "spec", "assert", "expect", "jest", "pytest"], "testing"),
            (["deploy", "ci/cd", "pipeline", "github actions"], "ci-cd"),
            (["figma", "sketch", "design", "wireframe", "prototype"], "design"),
            (["slack", "discord", "teams", "message"], "messaging"),
            (["email", "gmail", "outlook", "inbox"], "email"),
            (["claude", "gpt", "llm", "ai ", "prompt", "anthropic", "openai"], "ai"),
        ]

        for (keywords, tag) in techPatterns {
            if keywords.contains(where: { text.contains($0) || window.contains($0) }) {
                tags.append(tag)
            }
        }

        // URL detection
        if text.contains("http://") || text.contains("https://") {
            tags.append("web")
        }

        return tags
    }
}
