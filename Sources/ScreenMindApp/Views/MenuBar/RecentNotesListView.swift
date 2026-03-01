import SwiftUI
import SwiftData
import StorageCore

/// Compact list of recent notes for the menu bar popover.
struct RecentNotesListView: View {
    @Query(sort: \NoteModel.createdAt, order: .reverse, animation: .default)
    private var recentNotes: [NoteModel]

    @Environment(\.openWindow) private var openWindow
    @State private var hoveredNoteID: UUID?

    private var displayNotes: [NoteModel] {
        Array(recentNotes.prefix(8))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if displayNotes.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "note.text")
                            .font(.system(size: 20))
                            .foregroundStyle(.tertiary)
                        Text("No notes yet")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
            } else {
                ForEach(displayNotes) { note in
                    Button {
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "notes-browser")
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(categoryColor(note.category))
                                .frame(width: 6, height: 6)

                            Text(note.title)
                                .font(.system(size: 12))
                                .lineLimit(1)
                                .foregroundStyle(.primary)

                            Spacer()

                            Text(note.createdAt.relativeString)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .contentShape(Rectangle())
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.quaternary.opacity(hoveredNoteID == note.id ? 0.6 : 0))
                        )
                        .onHover { hoveredNoteID = $0 ? note.id : nil }
                    }
                    .buttonStyle(.plain)

                    if note.id != displayNotes.last?.id {
                        Divider()
                            .padding(.horizontal, 8)
                    }
                }
            }
        }
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
