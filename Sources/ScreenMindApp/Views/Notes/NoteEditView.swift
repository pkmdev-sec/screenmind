import SwiftUI
import SwiftData
import StorageCore
import Shared

/// Inline note editor — edit title, summary, details, tags after creation.
struct NoteEditView: View {
    @Bindable var note: NoteModel
    @Environment(\.modelContext) private var modelContext
    @State private var isDirty = false
    @State private var saveTask: Task<Void, Never>?
    @State private var newTag = ""
    @State private var isPreviewMode = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Spacer()

                Picker("", selection: $isPreviewMode) {
                    Label("Edit", systemImage: "pencil").tag(false)
                    Label("Preview", systemImage: "eye").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if isPreviewMode {
                        previewContent
                    } else {
                        editContent
                    }
                }
                .padding(24)
            }
        }
        .background(.background)
        .onKeyPress(characters: CharacterSet(charactersIn: "b")) { press in
            if press.modifiers.contains(.command) && !isPreviewMode {
                wrapSelectedText(with: "**")
                return .handled
            }
            return .ignored
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "i")) { press in
            if press.modifiers.contains(.command) && !isPreviewMode {
                wrapSelectedText(with: "*")
                return .handled
            }
            return .ignored
        }
    }

    private var editContent: some View {
        Group {
                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("Title")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextField("Note title", text: $note.title)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 16, weight: .semibold))
                        .onChange(of: note.title) { _, _ in markDirty() }
                }

                // Summary
                VStack(alignment: .leading, spacing: 4) {
                    Text("Summary")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextEditor(text: $note.summary)
                        .font(.system(size: 13))
                        .frame(minHeight: 60, maxHeight: 120)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .onChange(of: note.summary) { _, _ in markDirty() }
                }

                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text("Details")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextEditor(text: $note.details)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(minHeight: 100, maxHeight: 300)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .onChange(of: note.details) { _, _ in markDirty() }
                }

                // Tags
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 6) {
                        ForEach(note.tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text("#\(tag)")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                Button {
                                    note.tags.removeAll { $0 == tag }
                                    markDirty()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 10))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                        }
                    }

                    HStack {
                        TextField("Add tag...", text: $newTag)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11))
                            .onSubmit { addTag() }
                        Button("Add") { addTag() }
                            .controlSize(.small)
                            .disabled(newTag.isEmpty)
                    }
                }

                // Category
                VStack(alignment: .leading, spacing: 4) {
                    Text("Category")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Picker("", selection: $note.category) {
                        Text("Coding").tag("coding")
                        Text("Research").tag("research")
                        Text("Meeting").tag("meeting")
                        Text("Communication").tag("communication")
                        Text("Reading").tag("reading")
                        Text("Terminal").tag("terminal")
                        Text("Other").tag("other")
                    }
                    .labelsHidden()
                    .onChange(of: note.category) { _, _ in markDirty() }
                }

                // Metadata (read-only)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Metadata")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 16) {
                        Label(note.appName, systemImage: "app.fill")
                        if let window = note.windowTitle {
                            Label(window, systemImage: "macwindow")
                                .lineLimit(1)
                        }
                        Text(note.createdAt, format: .dateTime)
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                }

                // Save indicator
                if isDirty {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Saving...")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
        }
    }

    private var previewContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text(note.title)
                .font(.system(size: 22, weight: .bold))

            Divider()

            // Summary
            Text("Summary")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(renderMarkdown(note.summary))
                .font(.system(size: 14))
                .textSelection(.enabled)

            Divider()

            // Details
            Text("Details")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(renderMarkdown(note.details))
                .font(.system(size: 13))
                .textSelection(.enabled)

            Divider()

            // Tags
            HStack(spacing: 6) {
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

            // Metadata
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 16) {
                    Label(note.appName, systemImage: "app.fill")
                    if let window = note.windowTitle {
                        Label(window, systemImage: "macwindow")
                            .lineLimit(1)
                    }
                    Text(note.createdAt, format: .dateTime)
                }
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            }
        }
    }

    private func markDirty() {
        isDirty = true
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            try? modelContext.save()
            await MainActor.run { isDirty = false }
        }
    }

    private func addTag() {
        let tag = newTag.lowercased().trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "-")
        guard !tag.isEmpty, !note.tags.contains(tag) else { return }
        note.tags.append(tag)
        newTag = ""
        markDirty()
    }

    /// Simple markdown renderer using AttributedString.
    private func renderMarkdown(_ text: String) -> AttributedString {
        do {
            return try AttributedString(markdown: text)
        } catch {
            return AttributedString(text)
        }
    }

    /// Wrap selected text with markdown syntax (basic implementation).
    /// Note: This is a simplified version. Full text selection handling would require
    /// custom TextEditor or NSTextView wrapper.
    private func wrapSelectedText(with wrapper: String) {
        // In a production implementation, this would:
        // 1. Get the current selection range from the TextEditor
        // 2. Wrap the selected text with the wrapper
        // 3. Update the text and maintain selection
        // For now, this is a placeholder for the keyboard shortcut registration
        markDirty()
    }
}
