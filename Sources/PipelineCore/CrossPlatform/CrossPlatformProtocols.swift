import Foundation
import OCRProcessing
import AIProcessing

/// Cross-platform service protocols defining the Rust FFI boundary.
/// These protocols represent the minimal API surface that would be implemented
/// in Rust core library and exposed via FFI to Swift (macOS), Kotlin (Android),
/// C++ (Windows/Linux), and WASM (Web).
///
/// Architecture:
/// - Rust Core: Implements business logic, handles capture, OCR, AI, storage
/// - Platform Layers: Swift/Kotlin/C++ wrappers that call into Rust via FFI
/// - This file: Protocol definitions that both Rust and platform layers conform to

// MARK: - Screen Capture Service

/// Protocol for screen capture functionality across platforms.
/// Rust implementation would use platform-specific capture APIs:
/// - macOS: CGWindowListCreateImage
/// - Windows: Windows.Graphics.Capture
/// - Linux: XComposite/Wayland screenshoting
public protocol ScreenCaptureService: Sendable {
    /// Start capturing screens at the specified interval.
    /// - Parameter interval: Time between captures in seconds
    func startCapture(interval: TimeInterval) async throws

    /// Stop the capture loop.
    func stopCapture() async

    /// Capture a single frame immediately.
    /// - Returns: Raw image data (PNG format) and metadata
    func captureFrame() async throws -> CapturedFrameData

    /// Check if screen recording permission is granted (macOS/iOS specific).
    func hasScreenRecordingPermission() async -> Bool
}

/// Platform-independent captured frame data.
/// Designed to cross FFI boundary efficiently.
public struct CapturedFrameData: Sendable, Codable {
    /// PNG-encoded image data
    public let imageData: Data
    /// Width in pixels
    public let width: Int
    /// Height in pixels
    public let height: Int
    /// Timestamp of capture
    public let timestamp: Date
    /// Active application name (if available)
    public let appName: String?
    /// Active window title (if available)
    public let windowTitle: String?
    /// Bundle identifier (macOS/iOS)
    public let bundleID: String?

    public init(imageData: Data, width: Int, height: Int, timestamp: Date, appName: String?, windowTitle: String?, bundleID: String?) {
        self.imageData = imageData
        self.width = width
        self.height = height
        self.timestamp = timestamp
        self.appName = appName
        self.windowTitle = windowTitle
        self.bundleID = bundleID
    }
}

// MARK: - OCR Service

/// Protocol for optical character recognition across platforms.
/// Rust implementation would use platform-specific OCR:
/// - macOS/iOS: Vision framework via FFI
/// - Windows: Windows.Media.Ocr
/// - Linux: Tesseract
public protocol OCRService: Sendable {
    /// Extract text from image data.
    /// - Parameter imageData: PNG or JPEG encoded image
    /// - Returns: Recognized text with bounding boxes and confidence
    func extractText(from imageData: Data) async throws -> OCRResult

    /// Check if OCR is available on this platform.
    func isAvailable() async -> Bool
}

/// Platform-independent OCR result.
public struct OCRResult: Sendable, Codable {
    /// All recognized text concatenated
    public let fullText: String
    /// Individual text elements with positions
    public let elements: [OCRTextElement]
    /// Overall confidence (0.0 to 1.0)
    public let confidence: Double
    /// Processing time in milliseconds
    public let processingTimeMs: Int

    public init(fullText: String, elements: [OCRTextElement], confidence: Double, processingTimeMs: Int) {
        self.fullText = fullText
        self.elements = elements
        self.confidence = confidence
        self.processingTimeMs = processingTimeMs
    }
}

/// Individual recognized text element.
public struct OCRTextElement: Sendable, Codable {
    /// Recognized text
    public let text: String
    /// Bounding box (normalized 0.0 to 1.0)
    public let bounds: CGRect
    /// Confidence (0.0 to 1.0)
    public let confidence: Double

    public init(text: String, bounds: CGRect, confidence: Double) {
        self.text = text
        self.bounds = bounds
        self.confidence = confidence
    }
}

// MARK: - AI Service

/// Protocol for AI-powered note generation across platforms.
/// Rust implementation would handle HTTP requests to AI providers:
/// - Anthropic Claude
/// - OpenAI
/// - Local models via Ollama
public protocol AIService: Sendable {
    /// Generate a structured note from OCR text.
    /// - Parameters:
    ///   - text: Extracted text from screen
    ///   - context: Application context (name, window title, bundle ID)
    /// - Returns: Generated note with title, summary, category, tags
    func generateNote(from text: String, context: AppContextData) async throws -> AIGeneratedNote

    /// Check if AI service is configured (API key present).
    func isConfigured() async -> Bool
}

/// Platform-independent application context.
public struct AppContextData: Sendable, Codable {
    public let appName: String
    public let windowTitle: String?
    public let bundleID: String?
    public let timestamp: Date

    public init(appName: String, windowTitle: String?, bundleID: String?, timestamp: Date) {
        self.appName = appName
        self.windowTitle = windowTitle
        self.bundleID = bundleID
        self.timestamp = timestamp
    }
}

/// Platform-independent generated note.
public struct AIGeneratedNote: Sendable, Codable {
    public let title: String
    public let summary: String
    public let details: String
    public let category: String
    public let tags: [String]
    public let confidence: Double
    public let shouldSkip: Bool

    public init(title: String, summary: String, details: String, category: String, tags: [String], confidence: Double, shouldSkip: Bool) {
        self.title = title
        self.summary = summary
        self.details = details
        self.category = category
        self.tags = tags
        self.confidence = confidence
        self.shouldSkip = shouldSkip
    }
}

// MARK: - Storage Service

/// Protocol for note and screenshot persistence across platforms.
/// Rust implementation would use:
/// - SQLite for structured data
/// - File system for screenshots
public protocol StorageService: Sendable {
    /// Save a note with optional screenshot.
    /// - Parameters:
    ///   - note: AI-generated note
    ///   - screenshot: Optional screenshot data
    /// - Returns: Unique note ID
    func saveNote(_ note: StoredNote, screenshot: Data?) async throws -> String

    /// Fetch notes in date range.
    func fetchNotes(from: Date, to: Date) async throws -> [StoredNote]

    /// Search notes by text query.
    func searchNotes(query: String, limit: Int) async throws -> [StoredNote]

    /// Delete note by ID.
    func deleteNote(id: String) async throws

    /// Get storage statistics.
    func getStorageStats() async throws -> StorageStats
}

/// Platform-independent stored note.
public struct StoredNote: Sendable, Codable, Identifiable {
    public let id: String
    public let title: String
    public let summary: String
    public let details: String
    public let category: String
    public let tags: [String]
    public let confidence: Double
    public let appName: String
    public let windowTitle: String?
    public let createdAt: Date
    public let hasScreenshot: Bool

    public init(id: String, title: String, summary: String, details: String, category: String, tags: [String], confidence: Double, appName: String, windowTitle: String?, createdAt: Date, hasScreenshot: Bool) {
        self.id = id
        self.title = title
        self.summary = summary
        self.details = details
        self.category = category
        self.tags = tags
        self.confidence = confidence
        self.appName = appName
        self.windowTitle = windowTitle
        self.createdAt = createdAt
        self.hasScreenshot = hasScreenshot
    }
}

/// Storage statistics.
public struct StorageStats: Sendable, Codable {
    public let totalNotes: Int
    public let totalScreenshots: Int
    public let diskUsageBytes: Int64
    public let quotaBytes: Int64

    public init(totalNotes: Int, totalScreenshots: Int, diskUsageBytes: Int64, quotaBytes: Int64) {
        self.totalNotes = totalNotes
        self.totalScreenshots = totalScreenshots
        self.diskUsageBytes = diskUsageBytes
        self.quotaBytes = quotaBytes
    }
}

// MARK: - Export Service

/// Protocol for exporting notes to external systems.
/// Rust implementation would handle:
/// - Markdown file generation
/// - JSON export
/// - Webhook calls
/// - Obsidian vault writing
public protocol ExportService: Sendable {
    /// Export notes in specified format.
    /// - Parameters:
    ///   - notes: Notes to export
    ///   - format: Export format (markdown, json, obsidian)
    ///   - destination: File path or URL
    func export(notes: [StoredNote], format: ExportFormat, destination: String) async throws

    /// Get list of available export formats.
    func availableFormats() async -> [ExportFormat]
}

/// Export formats supported across platforms.
public enum ExportFormat: String, Sendable, Codable, CaseIterable {
    case markdown
    case json
    case obsidian
    case notion
    case logseq
    case roamResearch = "roam"
}

// MARK: - User Defaults Keys

extension UserDefaults {
    /// Whether cross-platform mode is enabled (for future use).
    public var crossPlatformMode: Bool {
        get { bool(forKey: "crossPlatformMode") }
        set { set(newValue, forKey: "crossPlatformMode") }
    }
}
