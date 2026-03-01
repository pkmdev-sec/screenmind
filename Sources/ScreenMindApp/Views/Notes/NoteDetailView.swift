import SwiftUI
import StorageCore
import Shared

/// Full note detail view — title, summary, details, metadata, tags.
struct NoteDetailView: View {
    let note: NoteModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(note.title)
                        .font(.system(size: 22, weight: .bold))

                    HStack(spacing: 12) {
                        CategoryBadge(category: note.category)
                        ConfidenceIndicator(confidence: note.confidence)

                        Spacer()

                        Text(note.createdAt, style: .date)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(note.createdAt, style: .time)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                }

                Divider()

                // App Context
                HStack(spacing: 12) {
                    Label(note.appName, systemImage: "app.fill")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))

                    if let windowTitle = note.windowTitle {
                        Label(windowTitle, systemImage: "macwindow")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                // Summary
                VStack(alignment: .leading, spacing: 6) {
                    Label("Summary", systemImage: "text.alignleft")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Text(note.summary)
                        .font(.system(size: 14))
                        .lineSpacing(4)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                }

                // Details
                if !note.details.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Details", systemImage: "list.bullet")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Text(note.details)
                            .font(.system(size: 13))
                            .lineSpacing(3)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                }

                // Tags
                if !note.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Tags", systemImage: "tag.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)

                        FlowLayout(spacing: 6) {
                            ForEach(note.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Obsidian Links
                if !note.obsidianLinks.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Related Topics", systemImage: "link")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)

                        FlowLayout(spacing: 6) {
                            ForEach(note.obsidianLinks, id: \.self) { link in
                                Text(link)
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.purple.opacity(0.1))
                                    .foregroundStyle(.purple)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Obsidian Export Status
                HStack(spacing: 6) {
                    Image(systemName: note.obsidianExported ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(note.obsidianExported ? .green : .orange)
                        .font(.system(size: 12))
                    Text(note.obsidianExported ? "Exported to Obsidian" : "Not yet exported")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
        .background(.background)
    }
}
