import Foundation

/// App-wide constants for ScreenMind.
public enum AppConstants {
    public static let bundleIdentifier = "com.screenmind.app"
    public static let appName = "ScreenMind"

    // MARK: - Capture
    public enum Capture {
        public static let activeInterval: TimeInterval = 5
        public static let idleInterval: TimeInterval = 30
        public static let defaultInterval: TimeInterval = 15
    }

    // MARK: - Change Detection
    public enum Detection {
        public static let defaultThreshold: Double = 0.30
        public static let rollingWindowSize = 3
    }

    // MARK: - AI
    public enum AI {
        public static let apiBaseURL = "https://api.anthropic.com/v1/messages"
        public static let modelName = "claude-sonnet-4-6"
        public static let anthropicVersion = "2023-06-01"
        public static let maxTokens = 1024
        public static let temperature = 0.3
        public static let maxConcurrentRequests = 2
        public static let rateLimitPerHour = 60
        public static let keychainKey = "com.screenmind.anthropic-api-key"
    }

    // MARK: - Storage
    public enum Storage {
        public static let quotaBytes: Int64 = 1_073_741_824 // 1 GB
        public static let retentionDays = 30
        public static let screenshotDirectory = "Screenshots"
        public static let databaseName = "ScreenMind.store"
    }

    // MARK: - Obsidian
    public enum Obsidian {
        public static let defaultVaultPath = "~/Desktop/pkmdev-notes"
        public static let subfolder = "ScreenMind"
        public static let sourceTag = "screenmind"
    }

    // MARK: - Pipeline
    public enum Pipeline {
        public static let maxLatencySeconds: TimeInterval = 10
        public static let ocrQueueDepth = 5
        public static let minNoteCooldownSeconds: TimeInterval = 60
        public static let recentTextBufferSize = 20
        public static let textSampleLength = 500
        public static let textSimilarityThreshold: Double = 0.55
    }

    // MARK: - Resource Targets
    public enum Resources {
        public static let maxRAMMB = 100
        public static let maxCPUPercent = 5.0
        public static let maxBatteryDrainPerHour = 5.0
        public static let lowBatteryPauseThreshold = 20
    }
}
