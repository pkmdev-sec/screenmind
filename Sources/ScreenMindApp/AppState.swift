import Foundation
import SwiftUI
import SwiftData
import CoreGraphics
import Shared
import PipelineCore
import AIProcessing
import CaptureCore
import StorageCore
import SystemIntegration

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
    public var apiServerRunning = false

    private var pipeline: PipelineCoordinator?
    private var retryTask: Task<Void, Never>?
    private var storedModelContainer: ModelContainer?

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
        self.storedModelContainer = modelContainer
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

    /// Start the local REST API server.
    public func startAPIServer() {
        guard let container = storedModelContainer else { return }
        let containerRef = container

        Task {
            let server = APIServer.shared
            await server.setQueryHandler { request in
                await Self.handleAPIRequest(request, container: containerRef)
            }
            do {
                try await server.start()
                await MainActor.run { self.apiServerRunning = true }
            } catch {
                let msg = error.localizedDescription
                SMLogger.ui.error("API server failed to start: \(msg)")
                await MainActor.run {
                    self.apiServerRunning = false
                    self.configurationError = "API server failed: port 9876 may be in use"
                }
            }
        }
    }

    /// Stop the local REST API server.
    public func stopAPIServer() {
        Task {
            await APIServer.shared.stop()
            await MainActor.run { self.apiServerRunning = false }
        }
    }

    /// Handle incoming API requests.
    private static func handleAPIRequest(_ request: APIRequest, container: ModelContainer) async -> APIResponse {
        let storage = StorageActor(modelContainer: container)

        switch request.path {
        case "/api/notes":
            let query = request.params["q"] ?? ""
            let limit = Int(request.params["limit"] ?? "20") ?? 20
            guard let notes = try? await storage.searchNotes(query: query, category: request.params["category"], from: nil, to: nil, appName: request.params["app"], limit: limit) else {
                return APIResponse(status: 500, body: ["error": "Failed to query notes"])
            }
            let noteData: [[String: Any]] = notes.map { note in
                ["id": note.id.uuidString, "title": note.title, "summary": note.summary,
                 "category": note.category, "tags": note.tags, "app": note.appName,
                 "confidence": note.confidence, "created": note.createdAt.iso8601String]
            }
            return APIResponse(status: 200, body: ["notes": noteData, "count": noteData.count])

        case "/api/notes/today":
            guard let notes = try? await storage.fetchTodayNotes() else {
                return APIResponse(status: 500, body: ["error": "Failed to fetch notes"])
            }
            let noteData: [[String: Any]] = notes.map { note in
                ["id": note.id.uuidString, "title": note.title, "summary": note.summary,
                 "category": note.category, "app": note.appName, "created": note.createdAt.iso8601String]
            }
            return APIResponse(status: 200, body: ["notes": noteData, "count": noteData.count])

        case "/api/stats":
            let totalNotes = (try? await storage.noteCount()) ?? 0
            let todayNotes = (try? await storage.fetchTodayNotes())?.count ?? 0
            let monitor = ResourceMonitor.shared
            let resources = await monitor.currentResources()
            let throughput = await monitor.currentThroughput()
            return APIResponse(status: 200, body: [
                "total_notes": totalNotes, "today_notes": todayNotes,
                "cpu_percent": resources.cpuPercent, "memory_mb": resources.memoryMB,
                "battery": resources.batteryLevel, "notes_per_hour": throughput.notesPerHour,
                "frames_captured": throughput.totalFramesCaptured,
                "notes_generated": throughput.notesGenerated
            ])

        case "/api/apps":
            let apps = (try? await storage.distinctAppNames()) ?? []
            return APIResponse(status: 200, body: ["apps": apps])

        case "/api/health":
            return APIResponse(status: 200, body: ["status": "ok", "version": "1.0.0"])

        default:
            return APIResponse(status: 404, body: [
                "error": "Not found",
                "endpoints": ["/api/notes", "/api/notes/today", "/api/stats", "/api/apps", "/api/health"]
            ])
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
