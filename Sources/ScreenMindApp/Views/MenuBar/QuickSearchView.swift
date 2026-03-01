import SwiftUI
import SwiftData
import StorageCore
import Shared

/// Quick search popover accessible from the menu bar.
struct QuickSearchView: View {
    @Query(sort: \NoteModel.createdAt, order: .reverse) private var allNotes: [NoteModel]
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @State private var selectedIndex = 0
    @Environment(\.openWindow) private var openWindow
    @State private var hoveredResultIndex: Int?

    private var searchResults: [NoteModel] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return Array(allNotes.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.summary.localizedCaseInsensitiveContains(query) ||
            $0.appName.localizedCaseInsensitiveContains(query) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }.prefix(10))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
                TextField("Search notes...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isSearchFocused)
                    .onSubmit {
                        if let result = searchResults[safe: selectedIndex] {
                            openNotesBrowser(for: result)
                        }
                    }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if !searchText.isEmpty {
                Divider()

                if searchResults.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundStyle(.tertiary)
                            Text("No results for \"\(searchText)\"")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 16)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, note in
                                Button {
                                    openNotesBrowser(for: note)
                                } label: {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(categoryColor(note.category))
                                            .frame(width: 6, height: 6)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(note.title)
                                                .font(.system(size: 12, weight: .medium))
                                                .lineLimit(1)
                                            Text(note.summary)
                                                .font(.system(size: 10))
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(note.appName)
                                                .font(.system(size: 10))
                                                .foregroundStyle(.tertiary)
                                            Text(note.createdAt.relativeString)
                                                .font(.system(size: 9, design: .monospaced))
                                                .foregroundStyle(.quaternary)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        index == selectedIndex ? Color.accentColor.opacity(0.15) :
                                        (hoveredResultIndex == index ? Color.accentColor.opacity(0.08) : Color.clear)
                                    )
                                    .contentShape(Rectangle())
                                    .onHover { hoveredResultIndex = $0 ? index : nil }
                                }
                                .buttonStyle(.plain)

                                if index < searchResults.count - 1 {
                                    Divider()
                                        .padding(.horizontal, 12)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 250)

                    Divider()

                    // Keyboard hints
                    HStack(spacing: 12) {
                        HStack(spacing: 2) {
                            Text("Enter")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 3))
                            Text("open")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Text("\(searchResults.count) results")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
            }
        }
        .onAppear {
            isSearchFocused = true
        }
    }

    private func openNotesBrowser(for note: NoteModel) {
        openWindow(id: "notes-browser")
    }

    private func categoryColor(_ category: String) -> Color {
        switch category.lowercased() {
        case "meeting": return .purple
        case "research": return .blue
        case "coding": return .green
        case "communication": return .orange
        case "reading": return .cyan
        case "terminal": return .gray
        default: return .secondary
        }
    }
}

// Safe array subscript
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
