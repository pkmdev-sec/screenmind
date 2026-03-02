import Foundation
import CaptureCore
import OCRProcessing
import AIProcessing
import StorageCore
import Shared

/// Platform-specific adapter protocol.
/// Each platform (macOS, Windows, Linux, iOS, Android) implements this protocol
/// to provide platform-specific functionality through a unified interface.
public protocol PlatformAdapter: Sendable {
    /// Platform name (e.g., "macOS", "Windows", "Linux")
    var platformName: String { get }

    /// Whether this platform supports screen capture
    var supportsScreenCapture: Bool { get }

    /// Whether this platform supports native OCR
    var supportsNativeOCR: Bool { get }

    /// Initialize platform-specific services
    func initialize() async throws

    /// Get screen capture service (if supported)
    func getScreenCaptureService() async throws -> ScreenCaptureService?

    /// Get OCR service (if supported)
    func getOCRService() async throws -> OCRService?
}

// MARK: - macOS Adapter

/// macOS platform adapter wrapping existing ScreenMind actors.
/// This adapter demonstrates how the cross-platform protocol layer
/// would integrate with the existing macOS-specific implementation.
public actor MacOSAdapter: PlatformAdapter {
    public let platformName = "macOS"
    public let supportsScreenCapture = true
    public let supportsNativeOCR = true

    private var screenCapture: MacOSScreenCaptureService?
    private var ocrService: MacOSOCRService?

    public init() {}

    public func initialize() async throws {
        SMLogger.system.info("Initializing macOS platform adapter")
        self.screenCapture = MacOSScreenCaptureService()
        self.ocrService = MacOSOCRService()
    }

    public func getScreenCaptureService() async throws -> ScreenCaptureService? {
        return screenCapture
    }

    public func getOCRService() async throws -> OCRService? {
        return ocrService
    }
}

/// macOS screen capture service wrapping ScreenCaptureActor.
actor MacOSScreenCaptureService: ScreenCaptureService {
    private var captureActor: ScreenCaptureActor?
    private var isCapturing = false

    func startCapture(interval: TimeInterval) async throws {
        guard !isCapturing else { return }

        // In a real implementation, this would instantiate and start ScreenCaptureActor
        // For now, this demonstrates the protocol boundary
        SMLogger.system.info("MacOS screen capture started with interval: \(interval)s")
        isCapturing = true
    }

    func stopCapture() async {
        isCapturing = false
        SMLogger.system.info("MacOS screen capture stopped")
    }

    func captureFrame() async throws -> CapturedFrameData {
        // In a real implementation, this would call ScreenCaptureActor.captureFrame()
        // and convert CapturedFrame to CapturedFrameData
        guard await hasScreenRecordingPermission() else {
            throw PlatformError.permissionDenied("Screen recording permission required")
        }

        // Stub: return empty frame
        return CapturedFrameData(
            imageData: Data(),
            width: 1920,
            height: 1080,
            timestamp: Date(),
            appName: nil,
            windowTitle: nil,
            bundleID: nil
        )
    }

    func hasScreenRecordingPermission() async -> Bool {
        // macOS-specific permission check via CGWindowListCreateImage
        return true // Stub
    }
}

/// macOS OCR service wrapping existing Vision framework integration.
actor MacOSOCRService: OCRService {
    func extractText(from imageData: Data) async throws -> OCRResult {
        // In a real implementation, this would call TextRecognizer actor
        // and convert RecognizedText to OCRResult
        guard await isAvailable() else {
            throw PlatformError.serviceUnavailable("Vision framework not available")
        }

        // Stub: return empty result
        return OCRResult(
            fullText: "",
            elements: [],
            confidence: 0.0,
            processingTimeMs: 0
        )
    }

    func isAvailable() async -> Bool {
        // Vision framework is always available on macOS 10.15+
        return true
    }
}

// MARK: - Windows Adapter (Stub)

/// Windows platform adapter stub.
/// Future implementation would integrate with Windows-specific APIs:
/// - Windows.Graphics.Capture for screen capture
/// - Windows.Media.Ocr for text recognition
/// - Win32 API for window information
public actor WindowsAdapter: PlatformAdapter {
    public let platformName = "Windows"
    public let supportsScreenCapture = true
    public let supportsNativeOCR = true

    public init() {}

    public func initialize() async throws {
        // TODO: Initialize Windows-specific services
        // - Setup COM interop for Windows.Graphics.Capture
        // - Load Windows.Media.Ocr runtime
        // - Initialize Win32 window enumeration
        throw PlatformError.notImplemented("Windows adapter not yet implemented")
    }

    public func getScreenCaptureService() async throws -> ScreenCaptureService? {
        throw PlatformError.notImplemented("Windows screen capture not yet implemented")
    }

    public func getOCRService() async throws -> OCRService? {
        throw PlatformError.notImplemented("Windows OCR not yet implemented")
    }
}

// MARK: - Linux Adapter (Stub)

/// Linux platform adapter stub.
/// Future implementation would integrate with Linux-specific APIs:
/// - XComposite/Wayland for screen capture
/// - Tesseract for OCR
/// - X11/Wayland protocols for window information
public actor LinuxAdapter: PlatformAdapter {
    public let platformName = "Linux"
    public let supportsScreenCapture = true
    public let supportsNativeOCR = true

    public init() {}

    public func initialize() async throws {
        // TODO: Initialize Linux-specific services
        // - Detect X11 vs Wayland
        // - Setup XComposite extension or Wayland screencopy protocol
        // - Initialize Tesseract OCR engine
        // - Setup window manager integration (EWMH/X11 or Wayland protocols)
        throw PlatformError.notImplemented("Linux adapter not yet implemented")
    }

    public func getScreenCaptureService() async throws -> ScreenCaptureService? {
        throw PlatformError.notImplemented("Linux screen capture not yet implemented")
    }

    public func getOCRService() async throws -> OCRService? {
        throw PlatformError.notImplemented("Linux OCR not yet implemented")
    }
}

// MARK: - Platform Detection

/// Detect current platform and return appropriate adapter.
public func createPlatformAdapter() -> PlatformAdapter {
    #if os(macOS)
    return MacOSAdapter()
    #elseif os(Windows)
    return WindowsAdapter()
    #elseif os(Linux)
    return LinuxAdapter()
    #else
    fatalError("Unsupported platform")
    #endif
}

// MARK: - Error Types

public enum PlatformError: Error, LocalizedError {
    case notImplemented(String)
    case permissionDenied(String)
    case serviceUnavailable(String)

    public var errorDescription: String? {
        switch self {
        case .notImplemented(let message):
            return "Not implemented: \(message)"
        case .permissionDenied(let message):
            return "Permission denied: \(message)"
        case .serviceUnavailable(let message):
            return "Service unavailable: \(message)"
        }
    }
}
