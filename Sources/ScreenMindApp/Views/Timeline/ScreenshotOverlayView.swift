import SwiftUI
import StorageCore

/// Full-screen overlay showing a screenshot with note details.
struct ScreenshotOverlayView: View {
    let note: NoteModel
    let onDismiss: () -> Void

    @State private var fullImage: NSImage?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(note.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                        HStack(spacing: 8) {
                            CategoryBadge(category: note.category)
                            Label(note.appName, systemImage: "app.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.7))
                            Text(note.createdAt, format: .dateTime.month().day().hour().minute())
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }

                    Spacer()

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape, modifiers: [])
                }
                .padding(16)
                .background(.ultraThinMaterial)

                // Screenshot
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Loading screenshot...")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let fullImage {
                    Image(nsImage: fullImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(8)
                } else {
                    ContentUnavailableView {
                        Label("Screenshot Not Available", systemImage: "photo.badge.exclamationmark")
                    } description: {
                        Text("The screenshot file may have been deleted.")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Note details bar
                HStack(alignment: .top, spacing: 16) {
                    // Summary
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Summary")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                        Text(note.summary)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Tags
                    if !note.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tags")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.6))
                            FlowLayout(spacing: 4) {
                                ForEach(note.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.white.opacity(0.15))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .frame(width: 200)
                    }

                    // Confidence
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Confidence")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                        ConfidenceIndicator(confidence: note.confidence)
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(40)
        }
        .task {
            loadFullImage()
        }
    }

    private func loadFullImage() {
        guard let screenshot = note.screenshot else {
            isLoading = false
            return
        }
        let path = screenshot.filePath
        if path.hasSuffix(".enc") {
            // Decrypt encrypted screenshot
            if let data = try? StorageCore.ScreenshotEncryptor.decryptFile(at: path) {
                fullImage = NSImage(data: data)
            }
        } else {
            fullImage = NSImage(contentsOfFile: path)
        }
        isLoading = false
    }
}
