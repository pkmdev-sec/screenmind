import Foundation
import ScreenCaptureKit
import CoreGraphics
import CoreMedia
import AppKit
import Shared

/// Captures screen content using ScreenCaptureKit with adaptive intervals.
public actor ScreenCaptureActor {
    private var stream: SCStream?
    private var frameHandler: FrameHandler?
    private var isCapturing = false
    private var continuation: AsyncStream<CapturedFrame>.Continuation?
    private let configuration: CaptureConfiguration
    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?

    public init(configuration: CaptureConfiguration = CaptureConfiguration()) {
        self.configuration = configuration
    }

    /// Returns an async stream of captured frames.
    public func frames() -> AsyncStream<CapturedFrame> {
        AsyncStream(CapturedFrame.self, bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.continuation = continuation
            continuation.onTermination = { @Sendable _ in
                Task { await self.stop() }
            }
        }
    }

    /// Start capturing the screen.
    public func start() async throws {
        guard !isCapturing else { return }

        SMLogger.capture.info("Requesting shareable content...")
        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            SMLogger.capture.info("Got \(content.displays.count, privacy: .public) displays, \(content.windows.count, privacy: .public) windows")
        } catch {
            let msg = String(describing: error)
            SMLogger.capture.error("SCShareableContent failed: \(msg, privacy: .public)")
            throw error
        }
        guard let display = content.displays.first else {
            SMLogger.capture.error("No displays found")
            return
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])

        let streamConfig = SCStreamConfiguration()
        let scale = display.width > Int(configuration.maxWidth)
            ? Double(configuration.maxWidth) / Double(display.width)
            : 1.0
        streamConfig.width = Int(Double(display.width) * scale)
        streamConfig.height = Int(Double(display.height) * scale)
        streamConfig.pixelFormat = kCVPixelFormatType_32BGRA
        let interval = configuration.activeInterval
        streamConfig.minimumFrameInterval = CMTime(seconds: interval, preferredTimescale: 1)
        streamConfig.showsCursor = false

        let handler = FrameHandler { [weak self] image in
            guard let self else { return }
            Task { await self.handleFrame(image) }
        }
        self.frameHandler = handler // Retain handler — SCStream holds a weak reference

        let stream = SCStream(filter: filter, configuration: streamConfig, delegate: nil)
        try stream.addStreamOutput(handler, type: .screen, sampleHandlerQueue: .global(qos: .utility))
        try await stream.startCapture()

        self.stream = stream
        self.isCapturing = true
        setupSleepWakeObservers()
        SMLogger.capture.info("Screen capture started (\(streamConfig.width)x\(streamConfig.height))")
    }

    /// Stop capturing.
    public func stop() {
        guard isCapturing else { return }
        Task {
            try? await stream?.stopCapture()
        }
        stream = nil
        frameHandler = nil
        isCapturing = false
        continuation?.finish()
        continuation = nil
        removeSleepWakeObservers()
        SMLogger.capture.info("Screen capture stopped")
    }

    private func handleFrame(_ image: CGImage) {
        let app = NSWorkspace.shared.frontmostApplication
        let pid = app?.processIdentifier

        // Get frontmost window info and crop to just that window
        let windowInfo = pid.flatMap { Self.frontmostWindowInfo(for: $0) }
        let finalImage: CGImage
        if let bounds = windowInfo?.bounds,
           let cropped = Self.cropToWindow(image: image, windowBounds: bounds) {
            finalImage = cropped
        } else {
            finalImage = image
        }

        let frame = CapturedFrame(
            image: finalImage,
            appName: app?.localizedName ?? "Unknown",
            windowTitle: windowInfo?.title,
            bundleIdentifier: app?.bundleIdentifier
        )
        continuation?.yield(frame)
    }

    // MARK: - Window Detection & Cropping

    private struct WindowInfo {
        let bounds: CGRect
        let title: String?
    }

    /// Get the frontmost window bounds and title for the given process.
    private static func frontmostWindowInfo(for pid: pid_t) -> WindowInfo? {
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return nil
        }

        for window in windowList {
            guard let ownerPID = window[kCGWindowOwnerPID as String] as? pid_t,
                  ownerPID == pid,
                  let layer = window[kCGWindowLayer as String] as? Int,
                  layer == 0, // Normal windows only (skip menu bar, overlays)
                  let boundsDict = window[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) else {
                continue
            }
            // Skip tiny windows (status items, tooltips)
            guard bounds.width > 100, bounds.height > 100 else { continue }
            let title = window[kCGWindowName as String] as? String
            return WindowInfo(bounds: bounds, title: title)
        }
        return nil
    }

    /// Crop the full-display image to just the frontmost window area.
    private static func cropToWindow(image: CGImage, windowBounds: CGRect) -> CGImage? {
        // CGDisplayBounds gives display dimensions in the same coordinate space as CGWindowList
        let displayBounds = CGDisplayBounds(CGMainDisplayID())
        guard displayBounds.width > 0, displayBounds.height > 0 else { return nil }

        // Scale from display coordinates to captured image pixels
        let scaleX = Double(image.width) / displayBounds.width
        let scaleY = Double(image.height) / displayBounds.height

        let cropRect = CGRect(
            x: (windowBounds.origin.x - displayBounds.origin.x) * scaleX,
            y: (windowBounds.origin.y - displayBounds.origin.y) * scaleY,
            width: windowBounds.width * scaleX,
            height: windowBounds.height * scaleY
        )

        // Clamp to image bounds
        let imageRect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        let clamped = cropRect.intersection(imageRect)
        guard !clamped.isEmpty, clamped.width > 50, clamped.height > 50 else { return nil }

        return image.cropping(to: clamped)
    }

    private nonisolated func setupSleepWakeObservers() {
        let ws = NSWorkspace.shared.notificationCenter
        Task { @MainActor in
            let sleepObs = ws.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { _ in
                Task { await self.stop() }
            }
            let wakeObs = ws.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { _ in
                Task { try? await self.start() }
            }
            await self.storeObservers(sleep: sleepObs, wake: wakeObs)
        }
    }

    private func storeObservers(sleep: NSObjectProtocol, wake: NSObjectProtocol) {
        sleepObserver = sleep
        wakeObserver = wake
    }

    private nonisolated func removeSleepWakeObservers() {
        Task {
            let (s, w) = await (self.sleepObserver, self.wakeObserver)
            let ws = NSWorkspace.shared.notificationCenter
            if let s { ws.removeObserver(s) }
            if let w { ws.removeObserver(w) }
        }
    }
}

// MARK: - Frame Handler

private final class FrameHandler: NSObject, SCStreamOutput, @unchecked Sendable {
    private static let sharedContext = CIContext()
    private let onFrame: @Sendable (CGImage) -> Void

    init(onFrame: @escaping @Sendable (CGImage) -> Void) {
        self.onFrame = onFrame
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen,
              let pixelBuffer = sampleBuffer.imageBuffer else { return }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = Self.sharedContext.createCGImage(ciImage, from: ciImage.extent) else { return }

        onFrame(cgImage)
    }
}
