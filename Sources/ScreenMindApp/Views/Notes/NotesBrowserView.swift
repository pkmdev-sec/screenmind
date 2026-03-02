import SwiftUI
import SwiftData
import StorageCore
import Shared

/// Three-column notes browser — sidebar categories, note list, detail.
struct NotesBrowserView: View {
    @Query(sort: \NoteModel.createdAt, order: .reverse) private var allNotes: [NoteModel]
    @State private var selectedCategory: String? = nil
    @State private var selectedNote: NoteModel?
    @State private var searchText = ""
    @State private var showCommandPalette = false
    @AppStorage("vimModeEnabled") private var vimModeEnabled = false
    @FocusState private var isSearchFocused: Bool

    private let categories = ["All", "meeting", "research", "coding", "communication", "reading", "terminal", "other"]

    var body: some View {
        NavigationSplitView {
            // Sidebar — Categories
            List(selection: $selectedCategory) {
                ForEach(categories, id: \.self) { category in
                    Label {
                        HStack {
                            Text(category == "All" ? "All Notes" : category.capitalized)
                            Spacer()
                            Text("\(noteCount(for: category))")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.quaternary, in: Capsule())
                        }
                    } icon: {
                        Image(systemName: categoryIcon(category))
                            .foregroundStyle(categoryColor(category))
                    }
                    .tag(category)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
        } content: {
            // Content — Note List
            List(selection: $selectedNote) {
                ForEach(filteredNotes) { note in
                    NoteCellView(note: note)
                        .tag(note)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
            .searchable(text: $searchText, prompt: "Search notes...")
            .focused($isSearchFocused)
            .overlay {
                if filteredNotes.isEmpty {
                    ContentUnavailableView {
                        Label("No Notes", systemImage: "note.text")
                    } description: {
                        Text(searchText.isEmpty ? "Notes will appear here as ScreenMind captures your screen." : "No notes match your search.")
                    }
                }
            }
        } detail: {
            // Detail — Note View
            if let note = selectedNote {
                NoteDetailView(note: note)
            } else {
                ContentUnavailableView {
                    Label("Select a Note", systemImage: "sidebar.left")
                } description: {
                    Text("Choose a note from the list to view its details.")
                }
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .onKeyPress(keys: [.return]) { _ in
            if selectedNote != nil, !isSearchFocused {
                // Enter opens detail (already shown in split view, but could trigger focus)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(keys: [.escape]) { _ in
            if isSearchFocused {
                isSearchFocused = false
                return .handled
            }
            return .ignored
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "/")) { _ in
            isSearchFocused = true
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "k")) { press in
            if press.modifiers.contains(.command) {
                showCommandPalette = true
                return .handled
            }
            if vimModeEnabled && !isSearchFocused {
                selectPreviousNote()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "j")) { _ in
            if vimModeEnabled && !isSearchFocused {
                selectNextNote()
                return .handled
            }
            return .ignored
        }
        .overlay {
            if showCommandPalette {
                CommandPaletteView(isPresented: $showCommandPalette) { action in
                    handleCommandAction(action)
                }
            }
        }
    }

    private var filteredNotes: [NoteModel] {
        var notes = allNotes

        if let category = selectedCategory, category != "All" {
            notes = notes.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            notes = notes.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.summary.localizedCaseInsensitiveContains(searchText) ||
                $0.details.localizedCaseInsensitiveContains(searchText)
            }
        }

        return notes
    }

    private func noteCount(for category: String) -> Int {
        if category == "All" { return allNotes.count }
        return allNotes.filter { $0.category == category }.count
    }

    private func categoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "all": return "tray.full.fill"
        case "meeting": return "person.3.fill"
        case "research": return "magnifyingglass"
        case "coding": return "chevron.left.forwardslash.chevron.right"
        case "communication": return "bubble.left.and.bubble.right.fill"
        case "reading": return "book.fill"
        case "terminal": return "terminal.fill"
        case "other": return "square.grid.2x2"
        default: return "square.grid.2x2"
        }
    }

    private func categoryColor(_ category: String) -> Color {
        switch category.lowercased() {
        case "all": return .accentColor
        case "meeting": return .purple
        case "research": return .blue
        case "coding": return .green
        case "communication": return .orange
        case "reading": return .cyan
        case "terminal": return .gray
        default: return .secondary
        }
    }

    // MARK: - Keyboard Navigation

    private func selectNextNote() {
        guard !filteredNotes.isEmpty else { return }
        if let current = selectedNote, let index = filteredNotes.firstIndex(where: { $0.id == current.id }) {
            let nextIndex = min(index + 1, filteredNotes.count - 1)
            selectedNote = filteredNotes[nextIndex]
        } else {
            selectedNote = filteredNotes.first
        }
    }

    private func selectPreviousNote() {
        guard !filteredNotes.isEmpty else { return }
        if let current = selectedNote, let index = filteredNotes.firstIndex(where: { $0.id == current.id }) {
            let prevIndex = max(index - 1, 0)
            selectedNote = filteredNotes[prevIndex]
        } else {
            selectedNote = filteredNotes.first
        }
    }

    private func handleCommandAction(_ action: CommandPaletteView.CommandAction) {
        switch action {
        case .openSettings:
            NSApp.sendAction(Selector(("openWindow:")), to: nil, from: "settings")
        case .searchNotes:
            isSearchFocused = true
        case .openBrowser:
            // Already in browser
            break
        case .openTimeline:
            NSApp.sendAction(Selector(("openWindow:")), to: nil, from: "timeline")
        case .openChat:
            NSApp.sendAction(Selector(("openWindow:")), to: nil, from: "chat")
        case .openGraph:
            NSApp.sendAction(Selector(("openWindow:")), to: nil, from: "graph")
        case .quit:
            NSApp.terminate(nil)
        default:
            // Other actions not applicable in browser context
            break
        }
    }
}
