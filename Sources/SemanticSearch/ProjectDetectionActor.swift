import Foundation
import Shared

/// Auto-detects project/workspace from note context.
public actor ProjectDetectionActor {
    private var projectCache: [String: String] = [:] // appName+windowTitle -> project

    public init() {}

    /// Detect project name from note metadata.
    public func detectProject(appName: String, windowTitle: String?) -> String? {
        // Check cache first
        let cacheKey = "\(appName)|\(windowTitle ?? "")"
        if let cached = projectCache[cacheKey] { return cached }

        var project: String?

        // Heuristic 1: Window title contains project separator
        if let windowTitle {
            // Xcode: "AppState.swift — ScreenMind"
            // VS Code: "AppState.swift - ScreenMind"
            // IntelliJ: "ScreenMind [~/screenmind]"
            let separators = [" — ", " - ", " – "]
            for sep in separators {
                let parts = windowTitle.components(separatedBy: sep)
                if parts.count >= 2 {
                    project = parts.last?.trimmingCharacters(in: .whitespaces)
                    break
                }
            }

            // Bracket pattern: "Project [path]"
            if project == nil, let bracketStart = windowTitle.firstIndex(of: "["),
               let bracketEnd = windowTitle.firstIndex(of: "]") {
                let path = String(windowTitle[windowTitle.index(after: bracketStart)..<bracketEnd])
                project = URL(fileURLWithPath: path).lastPathComponent
            }
        }

        // Heuristic 2: App-specific patterns
        if project == nil {
            switch appName.lowercased() {
            case "xcode":
                // Extract from "filename — ProjectName" pattern
                project = windowTitle?.components(separatedBy: " — ").last?.trimmingCharacters(in: .whitespaces)
            case "terminal", "iterm2", "warp":
                // Extract from directory in prompt (simplified)
                project = windowTitle?.components(separatedBy: ":").last?
                    .trimmingCharacters(in: .whitespaces)
                    .components(separatedBy: "/").last
            default:
                break
            }
        }

        // Cache the result
        if let project, !project.isEmpty {
            projectCache[cacheKey] = project
            // Keep cache bounded
            if projectCache.count > 500 {
                projectCache.removeAll()
            }
        }

        return project
    }
}
