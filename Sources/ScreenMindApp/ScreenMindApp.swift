import SwiftUI
import SwiftData
import Shared
import PipelineCore
import AIProcessing
import StorageCore
import CaptureCore
import SystemIntegration

/// ScreenMind — AI-Powered Screen Memory for macOS.
@main
@MainActor
struct ScreenMindApp: App {
    @State private var appState = AppState()

    let modelContainer: ModelContainer

    var body: some Scene {
        // Menu bar popover — primary interface
        MenuBarExtra {
            MenuBarContentView(appState: appState, modelContainer: modelContainer)
                .modelContainer(modelContainer)
        } label: {
            Image(systemName: "brain.head.profile")
        }
        .menuBarExtraStyle(.window)

        // Settings window
        Window("ScreenMind Settings", id: "settings") {
            SettingsView()
                .modelContainer(modelContainer)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        // Notes browser window
        Window("Notes Browser", id: "notes-browser") {
            NotesBrowserView()
                .modelContainer(modelContainer)
        }
        .defaultSize(width: 900, height: 600)
        .defaultPosition(.center)

        // Timeline window
        Window("Timeline", id: "timeline") {
            TimelineView()
                .modelContainer(modelContainer)
        }
        .defaultSize(width: 1000, height: 700)
        .defaultPosition(.center)

        // Chat window
        Window("Chat with Notes", id: "chat") {
            ChatView()
                .modelContainer(modelContainer)
        }
        .defaultSize(width: 600, height: 500)
        .defaultPosition(.center)

        // Knowledge Graph window
        Window("Knowledge Graph", id: "graph") {
            KnowledgeGraphView()
                .modelContainer(modelContainer)
        }
        .defaultSize(width: 1100, height: 700)
        .defaultPosition(.center)

        // Onboarding window
        Window("Welcome to ScreenMind", id: "onboarding") {
            OnboardingView()
                .modelContainer(modelContainer)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .defaultPosition(.center)
    }

    init() {
        // Set up SwiftData container with fallback to in-memory on failure
        let schema = Schema([NoteModel.self, ScreenshotModel.self, AppContextModel.self])
        let config = ModelConfiguration(AppConstants.Storage.databaseName, schema: schema)
        do {
            self.modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            SMLogger.general.error("ModelContainer failed: \(error.localizedDescription) — falling back to in-memory")
            // Fall back to in-memory store so app doesn't crash
            let inMemoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            do {
                self.modelContainer = try ModelContainer(for: schema, configurations: inMemoryConfig)
            } catch {
                fatalError("Failed to create even in-memory ModelContainer: \(error)")
            }
            // Defer error surfacing to after appState is initialized
            let state = appState
            Task { @MainActor in
                state.configurationError = "Database error — notes stored in memory only (will be lost on quit)"
            }
        }

        // Only request screen capture permission on very first launch (never seen onboarding).
        // After that, let the onboarding wizard or settings handle permission requests
        // to avoid repeated system popups after ad-hoc re-signing.
        if !UserDefaults.standard.bool(forKey: "hasRequestedScreenCapture") {
            if !CGPreflightScreenCaptureAccess() {
                UserDefaults.standard.set(true, forKey: "hasRequestedScreenCapture")
                PermissionsManager.requestScreenCapture()
            }
        }

        SMLogger.general.info("ScreenMind launched")

        // Use NotificationCenter to start pipeline after app finishes launching
        let state = appState
        let container = modelContainer
        NotificationCenter.default.addObserver(
            forName: NSApplication.didFinishLaunchingNotification,
            object: nil,
            queue: .main
        ) { _ in
            SMLogger.general.info("didFinishLaunching fired — configuring pipeline")
            Task { @MainActor in
                // Request notification permission
                _ = await NotificationManager.shared.requestAuthorization()

                // Register global keyboard shortcuts
                KeyboardShortcutsManager.shared.register { action in
                    Task { @MainActor in
                        switch action {
                        case .toggleMonitoring:
                            if state.isMonitoring {
                                state.stopMonitoring()
                            } else {
                                state.startMonitoring()
                            }
                        case .togglePause:
                            state.togglePause()
                        case .openNotesBrowser:
                            NSApp.activate(ignoringOtherApps: true)
                            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "notes-browser" }) {
                                window.makeKeyAndOrderFront(nil)
                            } else {
                                NSApp.sendAction(Selector(("openWindow:")), to: nil, from: "notes-browser")
                            }
                        case .openTimeline:
                            NSApp.activate(ignoringOtherApps: true)
                            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "timeline" }) {
                                window.makeKeyAndOrderFront(nil)
                            } else {
                                NSApp.sendAction(Selector(("openWindow:")), to: nil, from: "timeline")
                            }
                        case .manualCapture:
                            state.manualCapture()
                        case .voiceMemo:
                            state.toggleVoiceMemo()
                        }
                    }
                }

                state.configure(modelContainer: container)
                state.startMonitoring()
            }
        }
    }
}
