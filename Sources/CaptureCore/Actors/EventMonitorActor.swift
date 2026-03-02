import Foundation
import AppKit
import Shared

/// Monitors OS-level events and emits CaptureEvent triggers via AsyncStream.
public actor EventMonitorActor {
    private var continuation: AsyncStream<CaptureEvent>.Continuation?
    private var keyMonitor: Any?
    private var scrollMonitor: Any?
    private var clickMonitor: Any?
    private var workspaceObserver: NSObjectProtocol?
    private var lastCaptureTime: Date = .distantPast
    private var lastAppBundleID: String?
    private var lastKeyTime: Date = .distantPast
    private var lastScrollTime: Date = .distantPast
    private var lastClipboardCount = 0
    private var typingTimer: Task<Void, Never>?
    private var scrollTimer: Task<Void, Never>?
    private var idleTimer: Task<Void, Never>?
    private var clipboardPoller: Task<Void, Never>?
    private let minDebounceInterval: TimeInterval
    private let typingPauseThreshold: TimeInterval
    private let scrollStopThreshold: TimeInterval

    public init(configuration: CaptureConfiguration) {
        self.minDebounceInterval = configuration.minDebounceInterval
        self.typingPauseThreshold = configuration.typingPauseThreshold
        self.scrollStopThreshold = configuration.scrollStopThreshold
    }

    /// Returns an async stream of capture events.
    public func events() -> AsyncStream<CaptureEvent> {
        AsyncStream(CaptureEvent.self, bufferingPolicy: .bufferingNewest(1)) { continuation in
            Task {
                await self.setContinuation(continuation)
                await self.startMonitoring()
            }
            continuation.onTermination = { @Sendable _ in
                Task { await self.stopMonitoring() }
            }
        }
    }

    private func setContinuation(_ continuation: AsyncStream<CaptureEvent>.Continuation) {
        self.continuation = continuation
    }

    /// Start monitoring all event sources.
    private func startMonitoring() {
        setupWorkspaceObserver()
        setupEventMonitors()
        startClipboardPoller()
        startIdleTimer()
        lastClipboardCount = NSPasteboard.general.changeCount
        SMLogger.capture.info("EventMonitor started")
    }

    /// Stop all monitoring.
    private func stopMonitoring() {
        if let observer = workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            workspaceObserver = nil
        }
        removeEventMonitors()
        typingTimer?.cancel()
        scrollTimer?.cancel()
        idleTimer?.cancel()
        clipboardPoller?.cancel()
        typingTimer = nil
        scrollTimer = nil
        idleTimer = nil
        clipboardPoller = nil
        continuation?.finish()
        continuation = nil
        SMLogger.capture.info("EventMonitor stopped")
    }

    // MARK: - Event Sources

    private func setupWorkspaceObserver() {
        Task { @MainActor in
            let observer = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                      let bundleID = app.bundleIdentifier else { return }
                Task { await self?.handleAppSwitch(bundleID: bundleID) }
            }
            await self.storeWorkspaceObserver(observer)
        }
    }

    private func storeWorkspaceObserver(_ observer: NSObjectProtocol) {
        self.workspaceObserver = observer
    }

    private func setupEventMonitors() {
        Task { @MainActor in
            // Key events
            let keyMon = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] _ in
                Task { await self?.handleKeyPress() }
            }
            // Scroll events
            let scrollMon = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] _ in
                Task { await self?.handleScroll() }
            }
            // Click events (immediate capture with debounce)
            let clickMon = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                Task { await self?.handleClick() }
            }
            await self.storeEventMonitors(key: keyMon, scroll: scrollMon, click: clickMon)
        }
    }

    private func storeEventMonitors(key: Any?, scroll: Any?, click: Any?) {
        self.keyMonitor = key
        self.scrollMonitor = scroll
        self.clickMonitor = click
    }

    private func removeEventMonitors() {
        Task { @MainActor in
            let (key, scroll, click) = await (self.keyMonitor, self.scrollMonitor, self.clickMonitor)
            if let key { NSEvent.removeMonitor(key) }
            if let scroll { NSEvent.removeMonitor(scroll) }
            if let click { NSEvent.removeMonitor(click) }
        }
    }

    private func startClipboardPoller() {
        clipboardPoller = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                await self?.checkClipboard()
            }
        }
    }

    private func startIdleTimer() {
        idleTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                await self?.emitIfDebounced(.idle)
            }
        }
    }

    // MARK: - Event Handlers

    private func handleAppSwitch(bundleID: String) {
        guard bundleID != lastAppBundleID else { return }
        lastAppBundleID = bundleID
        emitIfDebounced(.appSwitch(bundleID: bundleID))
    }

    private func handleKeyPress() {
        lastKeyTime = .now
        // Cancel existing timer
        typingTimer?.cancel()
        // Start new timer to detect typing pause
        typingTimer = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(await self.typingPauseThreshold))
            await self.emitIfDebounced(.typingPause)
        }
    }

    private func handleScroll() {
        lastScrollTime = .now
        // Cancel existing timer
        scrollTimer?.cancel()
        // Start new timer to detect scroll stop
        scrollTimer = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(await self.scrollStopThreshold))
            await self.emitIfDebounced(.scrollStop)
        }
    }

    private func handleClick() {
        // Immediate capture on click, but still debounced
        emitIfDebounced(.manual)
    }

    private func checkClipboard() {
        let currentCount = NSPasteboard.general.changeCount
        if currentCount != lastClipboardCount {
            lastClipboardCount = currentCount
            emitIfDebounced(.clipboard)
        }
    }

    // MARK: - Debouncing

    private func emitIfDebounced(_ event: CaptureEvent) {
        let now = Date.now
        let elapsed = now.timeIntervalSince(lastCaptureTime)
        guard elapsed >= minDebounceInterval else { return }
        lastCaptureTime = now
        continuation?.yield(event)
    }
}
