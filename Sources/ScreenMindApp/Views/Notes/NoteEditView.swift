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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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
            .padding(24)
        }
        .background(.background)
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
}
