import SwiftUI
import StorageCore

/// Compact note cell for lists — shows title, summary preview, category badge, and timestamp.
struct NoteCellView: View {
    let note: NoteModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(note.title)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)

            Text(note.summary)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                CategoryBadge(category: note.category)

                Spacer()

                Text(note.createdAt.relativeString)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
