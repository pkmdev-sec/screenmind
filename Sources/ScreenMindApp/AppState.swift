import Foundation
import SwiftUI
import SwiftData
import CoreGraphics
import Shared
import PipelineCore
import AIProcessing
import CaptureCore
import StorageCore

/// Central observable state for the ScreenMind app.
@MainActor
@Observable
public final class AppState {
    public var isMonitoring = false
    public var isPaused = false
    public var captureInterval: TimeInterval = AppConstants.Capture.defaultInterval
    public var lastCaptureDate: Date?
    public var noteCountToday: Int = 0
    public var currentApp: String = ""
    public var permissionGranted = false
    public var configurationError: String?
    public var pipelineStatus: String = ""

    private var pipeline: PipelineCoordinator?
    private var retryTask: Task<Void, Never>?

    public init() {}

    /// Configure the pipeline with required dependencies.
    public func configure(modelContainer: ModelContainer) {
        guard pipeline == nil else {
            SMLogger.general.info("Pipeline already configured")
            return
        }

        SMLogger.general.info("Configuring AI provider...")

        // Build provider from settings (supports Claude, OpenAI, Ollama, Gemini, Custom)
        guard let provider = AIProviderFactory.createProvider() else {
            let providerType = UserDefaults.standard.string(forKey: "aiProviderType") ?? "Claude"
            configurationError = "\(providerType) API key not found — add in Settings"
            SMLogger.ai.error("Failed to create AI provider: \(providerType)")
            return
        }
        configurationError = nil
        let providerType = UserDefaults.standard.string(forKey: "aiProviderType") ?? "Claude"
        SMLogger.general.info("AI provider configured: \(providerType)")

        // Read excluded apps from UserDefaults
        let excludedAppsString = UserDefaults.standard.string(forKey: "excludedApps") ?? ""
        let excludedBundleIDs = Set(excludedAppsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })

        // Read user-configured capture intervals from Settings
        let activeInterval = UserDefaults.standard.double(forKey: "captureActiveInterval")
        let idleInterval = UserDefaults.standard.double(forKey: "captureIdleInterval")
        let captureConfig = CaptureConfiguration(
            activeInterval: activeInterval > 0 ? activeInterval : AppConstants.Capture.activeInterval,
            idleInterval: idleInterval > 0 ? idleInterval : AppConstants.Capture.idleInterval,
            excludedBundleIDs: excludedBundleIDs
        )
        self.pipeline = PipelineCoordinator(
            captureConfig: captureConfig,
            aiProvider: provider,
            modelContainer: modelContainer,
            onNoteSaved: { [weak self] title, appName in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.noteCountToday += 1
                    self.lastCaptureDate = Date()
                    self.currentApp = appName
                }
            }
        )
        SMLogger.general.info("Pipeline configured successfully")
    }

    /// Reconfigure the pipeline (e.g. after changing AI provider).
    public func reconfigure(modelContainer: ModelContainer) {
        let wasMonitoring = isMonitoring
        if wasMonitoring { stopMonitoring() }
        pipeline = nil
        configure(modelContainer: modelContainer)
        if wasMonitoring { startMonitoring() }
    }

    public func startMonitoring() {
        // Gate on Screen Recording permission BEFORE touching ScreenCaptureKit.
        // This prevents repeated system dialogs from the retry loop.
        guard CGPreflightScreenCaptureAccess() else {
            permissionGranted = false
            configurationError = "Screen Recording permission required — grant in System Settings > Privacy & Security > Screen Recording, then click Start Monitoring"
            SMLogger.ui.warning("Screen Recording not authorized — skipping pipeline start")
            return
        }

        isMonitoring = true
        isPaused = false
        configurationError = nil
        permissionGranted = true
        pipelineStatus = "Starting..."
        SMLogger.ui.info("Monitoring started")

        retryTask = Task {
            do {
                try await pipeline?.start()
                await MainActor.run { self.pipelineStatus = "Capturing" }
                SMLogger.ui.info("Pipeline running")
            } catch {
                let msg = String(describing: error)
                SMLogger.ui.error("Pipeline start failed: \(msg, privacy: .public)")
                await MainActor.run {
                    self.configurationError = "Pipeline error: \(msg)"
                    self.isMonitoring = false
                    self.pipelineStatus = ""
                }
            }
        }
    }

    public func stopMonitoring() {
        isMonitoring = false
        retryTask?.cancel()
        retryTask = nil
        SMLogger.ui.info("Monitoring stopped")

        Task {
            await pipeline?.stop()
        }
    }

    public func togglePause() {
        isPaused.toggle()
        SMLogger.ui.info("Monitoring \(self.isPaused ? "paused" : "resumed")")

        Task {
            await pipeline?.setPaused(isPaused)
        }
    }

    /// Trigger a manual capture — takes a screenshot immediately and processes it through the pipeline.
    public func manualCapture() {
        guard isMonitoring else {
            configurationError = "Start monitoring first to use manual capture"
            return
        }

        pipelineStatus = "Manual capture..."
        Task {
            await pipeline?.captureNow()
            await MainActor.run {
                self.pipelineStatus = "Capturing"
            }
        }
    }
}
