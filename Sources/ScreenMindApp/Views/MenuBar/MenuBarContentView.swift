import SwiftUI
import SwiftData
import Shared
import StorageCore

/// The main popover content shown from the menu bar icon.
struct MenuBarContentView: View {
    @Bindable var appState: AppState
    let modelContainer: ModelContainer

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.openWindow) private var openWindow
    @State private var hoveredButton: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 24, height: 24)
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(appState.isMonitoring && !appState.isPaused ? 1.3 : 1.0)
                        .opacity(appState.isMonitoring && !appState.isPaused ? 0.7 : 1.0)
                        .animation(
                            appState.isMonitoring && !appState.isPaused
                                ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                                : .default,
                            value: appState.isMonitoring
                        )
                        .animation(
                            appState.isMonitoring && !appState.isPaused
                                ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                                : .default,
                            value: appState.isPaused
                        )
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("ScreenMind")
                        .font(.system(size: 13, weight: .semibold))
                    Text(statusText)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let lastCapture = appState.lastCaptureDate {
                    Text(lastCapture.relativeString)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()
                .padding(.horizontal, 8)

            // Stats bar
            HStack(spacing: 16) {
                Label("\(appState.noteCountToday)", systemImage: "note.text")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("notes today")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            Divider()
                .padding(.horizontal, 8)

            // Quick Search
            QuickSearchView()
                .padding(.vertical, 4)

            Divider()
                .padding(.horizontal, 8)

            // Recent Notes
            RecentNotesListView()
                .padding(.vertical, 4)
                .frame(maxHeight: 200)

            // Action buttons
            HStack(spacing: 0) {
                Button {
                    openWindowFront(id: "notes-browser")
                } label: {
                    HStack {
                        Label("Browse Notes", systemImage: "rectangle.grid.1x2")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.quaternary.opacity(hoveredButton == "browse" ? 0.8 : 0))
                    )
                    .onHover { hoveredButton = $0 ? "browse" : nil }
                }
                .buttonStyle(.plain)

                Button {
                    openWindowFront(id: "timeline")
                } label: {
                    HStack {
                        Label("Timeline", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text("T")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.quaternary.opacity(hoveredButton == "timeline" ? 0.8 : 0))
                    )
                    .onHover { hoveredButton = $0 ? "timeline" : nil }
                }
                .buttonStyle(.plain)

                Button {
                    openWindowFront(id: "chat")
                } label: {
                    HStack {
                        Label("Chat with Notes", systemImage: "bubble.left.and.text.bubble.right")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.quaternary.opacity(hoveredButton == "chat" ? 0.8 : 0))
                    )
                    .onHover { hoveredButton = $0 ? "chat" : nil }
                }
                .buttonStyle(.plain)
            }

            Divider()
                .padding(.horizontal, 8)

            // Controls
            VStack(spacing: 0) {
                Button {
                    if appState.isMonitoring {
                        appState.stopMonitoring()
                    } else {
                        appState.startMonitoring()
                    }
                } label: {
                    HStack {
                        Label(
                            appState.isMonitoring ? "Stop Monitoring" : "Start Monitoring",
                            systemImage: appState.isMonitoring ? "stop.circle.fill" : "play.circle.fill"
                        )
                        .font(.system(size: 12))
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.quaternary.opacity(hoveredButton == "toggle" ? 0.8 : 0))
                    )
                    .onHover { hoveredButton = $0 ? "toggle" : nil }
                }
                .buttonStyle(.plain)

                if appState.isMonitoring {
                    Button {
                        appState.toggleVoiceMemo()
                    } label: {
                        HStack {
                            Label(
                                appState.isRecordingVoiceMemo ? "Stop Recording" : "Voice Memo",
                                systemImage: appState.isRecordingVoiceMemo ? "stop.circle.fill" : "mic.fill"
                            )
                            .font(.system(size: 12))
                            .foregroundStyle(appState.isRecordingVoiceMemo ? .red : .primary)
                            Spacer()
                            Text("⌘⌥⇧V")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.quaternary.opacity(hoveredButton == "voicememo" ? 0.8 : 0))
                        )
                        .onHover { hoveredButton = $0 ? "voicememo" : nil }
                    }
                    .buttonStyle(.plain)

                    Button {
                        appState.manualCapture()
                    } label: {
                        HStack {
                            Label("Capture Now", systemImage: "camera.shutter.button")
                                .font(.system(size: 12))
                            Spacer()
                            Text("⌘⌥⇧C")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.quaternary.opacity(hoveredButton == "capture" ? 0.8 : 0))
                        )
                        .onHover { hoveredButton = $0 ? "capture" : nil }
                    }
                    .buttonStyle(.plain)

                    Button {
                        appState.togglePause()
                    } label: {
                        HStack {
                            Label(
                                appState.isPaused ? "Resume" : "Pause",
                                systemImage: appState.isPaused ? "play.fill" : "pause.fill"
                            )
                            .font(.system(size: 12))
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.quaternary.opacity(hoveredButton == "pause" ? 0.8 : 0))
                        )
                        .onHover { hoveredButton = $0 ? "pause" : nil }
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()
                .padding(.horizontal, 8)

            // Bottom actions
            VStack(spacing: 0) {
                Button {
                    openWindowFront(id: "settings")
                } label: {
                    HStack {
                        Label("Settings…", systemImage: "gear")
                            .font(.system(size: 12))
                        Spacer()
                        Text("⌘,")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.quaternary.opacity(hoveredButton == "settings" ? 0.8 : 0))
                    )
                    .onHover { hoveredButton = $0 ? "settings" : nil }
                }
                .buttonStyle(.plain)
                .keyboardShortcut(",", modifiers: .command)

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    HStack {
                        Label("Quit ScreenMind", systemImage: "power")
                            .font(.system(size: 12))
                        Spacer()
                        Text("⌘Q")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.quaternary.opacity(hoveredButton == "quit" ? 0.8 : 0))
                    )
                    .onHover { hoveredButton = $0 ? "quit" : nil }
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q", modifiers: .command)
            }
        }
        .padding(.vertical, 8)
        .frame(width: 280)
        .background(.ultraThinMaterial)
        .task {
            appState.configure(modelContainer: modelContainer)
            if !hasCompletedOnboarding {
                openWindowFront(id: "onboarding")
            }
        }
    }

    private var statusColor: Color {
        if appState.configurationError != nil { return .orange }
        if !appState.isMonitoring { return .red }
        if appState.isPaused { return .yellow }
        return .green
    }

    /// Open a window and bring the app to the foreground.
    /// Menu bar apps don't auto-activate, so windows open behind the current app without this.
    private func openWindowFront(id: String) {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: id)
    }

    private var statusText: String {
        if let error = appState.configurationError { return error }
        if !appState.isMonitoring { return "Stopped" }
        if appState.isPaused { return "Paused" }
        if !appState.pipelineStatus.isEmpty {
            return "Monitoring — \(appState.pipelineStatus)"
        }
        return "Monitoring"
    }
}
