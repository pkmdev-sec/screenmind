import Foundation
import SwiftUI
import SwiftData
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

    private var pipeline: PipelineCoordinator?
    private var retryTask: Task<Void, Never>?

    public init() {}

    /// Configure the pipeline with required dependencies.
    public func configure(modelContainer: ModelContainer) {
        guard pipeline == nil else {
            SMLogger.general.info("Pipeline already configured")
            return
        }

        SMLogger.general.info("Attempting Keychain retrieval...")

        // Load API key from Keychain
        let apiKey: String
        do {
            guard let retrieved = try KeychainManager.retrieve(key: AppConstants.AI.keychainKey),
                  !retrieved.isEmpty else {
                SMLogger.ai.error("API key not found or empty in Keychain")
                configurationError = "API key not found — add in Settings"
                return
            }
            apiKey = retrieved
            configurationError = nil
            let masked = String(apiKey.prefix(8)) + "..."
            SMLogger.general.info("API key loaded: \(masked, privacy: .private)")
        } catch {
            let msg = String(describing: error)
            SMLogger.ai.error("Keychain retrieval failed: \(msg, privacy: .public)")
            configurationError = "Keychain error: \(msg)"
            return
        }

        // Read excluded apps from UserDefaults
        let excludedAppsString = UserDefaults.standard.string(forKey: "excludedApps") ?? ""
        let excludedBundleIDs = Set(excludedAppsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })

        let captureConfig = CaptureConfiguration(excludedBundleIDs: excludedBundleIDs)
        let provider = ClaudeProvider(apiKey: apiKey)
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

    public func startMonitoring() {
        isMonitoring = true
        isPaused = false
        configurationError = nil
        SMLogger.ui.info("Monitoring started")

        retryTask = Task {
            // Keep retrying until Screen Recording is granted (max 10 attempts)
            var attempt = 0
            let maxAttempts = 10
            while isMonitoring && !Task.isCancelled {
                attempt += 1
                do {
                    try await pipeline?.start()
                    permissionGranted = true
                    configurationError = nil
                    SMLogger.ui.info("Pipeline running (attempt \(attempt, privacy: .public))")
                    return
                } catch {
                    let msg = String(describing: error)
                    if attempt <= 3 {
                        SMLogger.ui.error("Pipeline attempt \(attempt, privacy: .public): \(msg, privacy: .public)")
                    }
                    if attempt >= maxAttempts {
                        configurationError = "Screen Recording permission denied — grant in System Settings"
                        isMonitoring = false
                        SMLogger.ui.error("Max attempts reached — stopping retry")
                        return
                    }
                    try? await Task.sleep(for: .seconds(attempt <= 3 ? 10 : 30))
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
}
