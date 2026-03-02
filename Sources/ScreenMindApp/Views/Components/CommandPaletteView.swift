import SwiftUI

/// Command palette overlay triggered with Cmd+K.
struct CommandPaletteView: View {
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var selectedIndex = 0
    @Environment(\.dismiss) private var dismiss

    var onAction: (CommandAction) -> Void

    enum CommandAction: String, CaseIterable, Identifiable {
        case openSettings = "Open Settings"
        case searchNotes = "Search Notes"
        case manualCapture = "Manual Capture"
        case toggleMonitoring = "Toggle Monitoring"
        case pauseResume = "Pause / Resume"
        case openBrowser = "Open Notes Browser"
        case openTimeline = "Open Timeline"
        case openChat = "Open AI Chat"
        case openGraph = "Open Knowledge Graph"
        case voiceMemo = "Record Voice Memo"
        case quit = "Quit ScreenMind"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .openSettings: return "gear"
            case .searchNotes: return "magnifyingglass"
            case .manualCapture: return "camera.fill"
            case .toggleMonitoring: return "power"
            case .pauseResume: return "pause.fill"
            case .openBrowser: return "note.text"
            case .openTimeline: return "calendar"
            case .openChat: return "bubble.left.and.bubble.right.fill"
            case .openGraph: return "circle.hexagongrid.fill"
            case .voiceMemo: return "mic.fill"
            case .quit: return "xmark.circle.fill"
            }
        }

        var shortcut: String {
            switch self {
            case .openSettings: return "Cmd+,"
            case .searchNotes: return "Cmd+F"
            case .manualCapture: return "Cmd+Opt+Shift+C"
            case .toggleMonitoring: return "Cmd+Shift+N"
            case .pauseResume: return "Cmd+Shift+P"
            case .openBrowser: return "Cmd+Shift+S"
            case .openTimeline: return "Cmd+Shift+T"
            case .openChat: return "Cmd+Shift+H"
            case .openGraph: return "Cmd+Shift+G"
            case .voiceMemo: return "Cmd+Opt+Shift+V"
            case .quit: return "Cmd+Q"
            }
        }
    }

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // Command palette
            VStack(spacing: 0) {
                // Search field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 14))

                    TextField("Type a command or search...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .focused($isSearchFieldFocused)
                        .onSubmit {
                            executeSelectedCommand()
                        }
                }
                .padding(12)
                .background(.ultraThinMaterial)

                Divider()

                // Commands list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredCommands.enumerated()), id: \.element) { index, command in
                            CommandRow(
                                command: command,
                                isSelected: index == selectedIndex
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                executeCommand(command)
                            }
                            .background(index == selectedIndex ? Color.accentColor.opacity(0.15) : Color.clear)
                        }
                    }
                }
                .frame(maxHeight: 400)
                .background(.regularMaterial)
            }
            .frame(width: 540)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        }
        .onAppear {
            isSearchFieldFocused = true
        }
        .onKeyPress(.upArrow) {
            selectedIndex = max(0, selectedIndex - 1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            selectedIndex = min(filteredCommands.count - 1, selectedIndex + 1)
            return .handled
        }
        .onKeyPress(.escape) {
            isPresented = false
            return .handled
        }
        .onKeyPress(.return) {
            executeSelectedCommand()
            return .handled
        }
    }

    @FocusState private var isSearchFieldFocused: Bool

    private var filteredCommands: [CommandAction] {
        if searchText.isEmpty {
            return CommandAction.allCases
        }
        return CommandAction.allCases.filter { command in
            command.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func executeSelectedCommand() {
        guard selectedIndex < filteredCommands.count else { return }
        executeCommand(filteredCommands[selectedIndex])
    }

    private func executeCommand(_ command: CommandAction) {
        isPresented = false
        onAction(command)
    }
}

/// Single command row in the palette.
private struct CommandRow: View {
    let command: CommandPaletteView.CommandAction
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: command.icon)
                .font(.system(size: 14))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .frame(width: 20)

            Text(command.rawValue)
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? .primary : .primary)

            Spacer()

            Text(command.shortcut)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
