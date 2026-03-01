import SwiftUI
import StorageCore

/// A single card in the timeline grid showing a screenshot thumbnail + note metadata.
struct TimelineCardView: View {
    let note: NoteModel
    let thumbnail: NSImage?
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Screenshot thumbnail
            ZStack {
                if let thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 140)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 140)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundStyle(.tertiary)
                        }
                }

                // Category pill overlay
                VStack {
                    HStack {
                        Spacer()
                        CategoryBadge(category: note.category)
                            .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    }
                    Spacer()
                }
                .padding(8)
            }
            .frame(height: 140)
            .clipped()

            // Note info
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(2)

                Text(note.summary)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Label(note.appName, systemImage: "app.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)

                    Spacer()

                    Text(note.createdAt, style: .time)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(10)
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }
}
