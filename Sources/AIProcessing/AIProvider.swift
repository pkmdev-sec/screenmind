import Foundation
import Shared
import OCRProcessing

/// Protocol for AI note generation providers.
public protocol AIProvider: Sendable {
    /// Whether this provider supports vision (image input).
    var supportsVision: Bool { get }

    /// Generate a structured note from OCR text and app context.
    func generateNote(from ocrText: String, appName: String, windowTitle: String?, lastNoteTitle: String?, lastNoteApp: String?, bundleID: String?, contextWindow: [(title: String, summary: String, timestamp: Date)]) async throws -> GeneratedNote

    /// Generate a note with optional image data (for vision-enabled providers).
    func generateNote(from ocrText: String, appName: String, windowTitle: String?, lastNoteTitle: String?, lastNoteApp: String?, bundleID: String?, imageData: Data?, contextWindow: [(title: String, summary: String, timestamp: Date)]) async throws -> GeneratedNote
}

// MARK: - Default Implementations

public extension AIProvider {
    /// Default: no vision support
    var supportsVision: Bool { false }

    /// Default: ignore imageData and call text-only version
    func generateNote(from ocrText: String, appName: String, windowTitle: String?, lastNoteTitle: String?, lastNoteApp: String?, bundleID: String?, imageData: Data?, contextWindow: [(title: String, summary: String, timestamp: Date)] = []) async throws -> GeneratedNote {
        return try await generateNote(from: ocrText, appName: appName, windowTitle: windowTitle, lastNoteTitle: lastNoteTitle, lastNoteApp: lastNoteApp, bundleID: bundleID, contextWindow: contextWindow)
    }
}

/// A note generated from screen content analysis.
public struct GeneratedNote: Sendable, Codable {
    public let title: String
    public let summary: String
    public let details: String
    public let category: NoteCategory
    public let tags: [String]
    public let confidence: Double
    public let skip: Bool
    public let obsidianLinks: [String]

    public init(title: String, summary: String, details: String, category: NoteCategory, tags: [String], confidence: Double, skip: Bool, obsidianLinks: [String]) {
        self.title = title
        self.summary = summary
        self.details = details
        self.category = category
        self.tags = tags
        self.confidence = confidence
        self.skip = skip
        self.obsidianLinks = obsidianLinks
    }

    enum CodingKeys: String, CodingKey {
        case title, summary, details, category, tags, confidence, skip
        case obsidianLinks = "obsidian_links"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
        self.details = try container.decodeIfPresent(String.self, forKey: .details) ?? ""
        // Fallback to .other for unknown categories
        if let rawCategory = try? container.decode(String.self, forKey: .category),
           let cat = NoteCategory(rawValue: rawCategory) {
            self.category = cat
        } else {
            self.category = .other
        }
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        self.confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0.5
        self.skip = try container.decodeIfPresent(Bool.self, forKey: .skip) ?? false
        self.obsidianLinks = try container.decodeIfPresent([String].self, forKey: .obsidianLinks) ?? []
    }
}

/// Categories for captured notes.
public enum NoteCategory: String, Sendable, Codable, CaseIterable {
    case meeting
    case research
    case coding
    case communication
    case reading
    case terminal
    case other
}

/// AI processing orchestrator with rate limiting and queueing.
public actor AIProcessingActor {
    private let provider: any AIProvider
    private var requestCount: Int = 0
    private var hourStart: Date = .now
    private let maxRequestsPerHour: Int

    public init(provider: any AIProvider, maxRequestsPerHour: Int = AppConstants.AI.rateLimitPerHour) {
        self.provider = provider
        self.maxRequestsPerHour = maxRequestsPerHour
    }

    /// Generate a note from recognized text, respecting rate limits.
    public func generateNote(from recognizedText: RecognizedText, lastNoteTitle: String? = nil, lastNoteApp: String? = nil, bundleID: String? = nil, imageData: Data? = nil, contextWindow: [(title: String, summary: String, timestamp: Date)] = []) async throws -> GeneratedNote? {
        // Rate limit check
        if Date.now.timeIntervalSince(hourStart) > 3600 {
            requestCount = 0
            hourStart = .now
        }

        guard requestCount < maxRequestsPerHour else {
            SMLogger.ai.warning("Rate limit reached (\(self.maxRequestsPerHour)/hr)")
            return nil
        }

        requestCount += 1
        SMLogger.ai.debug("AI request #\(self.requestCount) — app: \(recognizedText.appName)")

        let note = try await provider.generateNote(
            from: recognizedText.text,
            appName: recognizedText.appName,
            windowTitle: recognizedText.windowTitle,
            lastNoteTitle: lastNoteTitle,
            lastNoteApp: lastNoteApp,
            bundleID: bundleID,
            imageData: imageData,
            contextWindow: contextWindow
        )

        // AI decided this frame should be skipped
        if note.skip {
            SMLogger.ai.debug("AI skipped frame: \(note.title)")
            return nil
        }

        SMLogger.ai.info("Generated note: \(note.title) [\(note.category.rawValue)]")
        return note
    }

    public var currentUsage: (requests: Int, limit: Int) {
        (requestCount, maxRequestsPerHour)
    }
}
