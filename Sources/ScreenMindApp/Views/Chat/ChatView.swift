import SwiftUI
import SemanticSearch
import Shared

/// Chat with your notes using RAG (Retrieval-Augmented Generation).
struct ChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isProcessing = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .foregroundStyle(.purple)
                    .font(.system(size: 16))
                Text("Chat with Your Notes")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button {
                    messages.removeAll()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear chat history")
                .disabled(messages.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)

            Divider()

            // Messages
            if messages.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            if isProcessing {
                                HStack(spacing: 6) {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Searching notes...")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(16)
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastID = messages.last?.id {
                            withAnimation { proxy.scrollTo(lastID, anchor: .bottom) }
                        }
                    }
                }
            }

            Divider()

            // Input
            HStack(spacing: 8) {
                TextField("Ask your notes...", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isInputFocused)
                    .onSubmit { sendMessage() }
                    .disabled(isProcessing)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(inputText.isEmpty ? Color.gray : Color.accentColor)
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty || isProcessing)
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear { isInputFocused = true }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "brain.head.profile")
                .font(.system(size: 40))
                .foregroundStyle(.linearGradient(
                    colors: [.purple, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("Ask Your Notes Anything")
                .font(.system(size: 18, weight: .semibold))

            Text("ScreenMind uses semantic search to find relevant notes\nand AI to generate answers from your captured context.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            VStack(alignment: .leading, spacing: 6) {
                exampleQuery("What was I working on yesterday afternoon?")
                exampleQuery("Summarize my meetings this week")
                exampleQuery("Find notes about Swift concurrency")
                exampleQuery("What decisions were made in the team sync?")
            }
            .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func exampleQuery(_ text: String) -> some View {
        Button {
            inputText = text
            sendMessage()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "sparkle")
                    .font(.system(size: 10))
                    .foregroundStyle(.purple)
                Text(text)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.regularMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Send

    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let query = inputText
        inputText = ""

        messages.append(ChatMessage(role: .user, content: query))
        isProcessing = true

        Task {
            // Parse NL query for context
            let filter = NLQueryParser.parse(query)

            // For now, add a placeholder response.
            // In production, this would call ChatActor -> SemanticSearch -> AIProvider
            let response = """
            I searched your notes for "\(filter.semanticQuery.isEmpty ? query : filter.semanticQuery)"\
            \(filter.dateRange != nil ? " with date filter" : "")\
            \(filter.category != nil ? " in category: \(filter.category!)" : "").

            [Semantic search is active — connect an AI provider in Settings > AI to get intelligent answers from your notes.]
            """

            try? await Task.sleep(for: .milliseconds(500))

            await MainActor.run {
                messages.append(ChatMessage(role: .assistant, content: response))
                isProcessing = false
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .assistant {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundStyle(.purple)
                    .frame(width: 24, height: 24)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 13))
                    .lineSpacing(3)
                    .textSelection(.enabled)
                    .padding(10)
                    .background(
                        message.role == .user
                            ? AnyShapeStyle(Color.accentColor.opacity(0.15))
                            : AnyShapeStyle(.regularMaterial)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(message.timestamp, style: .time)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.quaternary)
            }
            .frame(maxWidth: 400, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .user {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24, height: 24)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
}
