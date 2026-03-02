import SwiftUI
import SwiftData
import SemanticSearch
import AIProcessing
import Shared

/// Chat with your notes using RAG (Retrieval-Augmented Generation).
struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
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
        errorMessage = nil

        // Capture model container on MainActor BEFORE entering background Task
        // SwiftData modelContext is @MainActor isolated — accessing it from a
        // background Task causes EXC_BREAKPOINT (_dispatch_assert_queue_fail)
        let container = modelContext.container

        Task {
            do {
                // Initialize semantic search and chat actor
                let semanticSearch = SemanticSearchActor()
                try? await semanticSearch.setup()
                let chatActor = ChatActor(semanticSearch: semanticSearch)

                // Get RAG response with context from notes
                let chatResponse = try await chatActor.ask(question: query, modelContainer: container)

                // Check if AI provider is configured
                guard let aiProvider = AIProviderFactory.createProvider() else {
                    await MainActor.run {
                        let providerType = UserDefaults.standard.string(forKey: "aiProviderType") ?? "Claude"
                        messages.append(ChatMessage(role: .assistant, content: """
                        I found \(chatResponse.sourcesCount) relevant notes, but I need an AI provider to generate an answer.

                        Please configure \(providerType) API key in Settings > AI to enable chat.
                        """))
                        isProcessing = false
                    }
                    return
                }

                // Send RAG prompt to AI provider via generateNote (reuses the AI pipeline)
                let note = try await aiProvider.generateNote(
                    from: chatResponse.ragPrompt,
                    appName: "ScreenMind Chat",
                    windowTitle: "Chat",
                    lastNoteTitle: nil,
                    lastNoteApp: nil,
                    bundleID: "com.screenmind.app",
                    contextWindow: []
                )

                // Use the generated note's details as the chat response
                let aiResponse = note.skip ? "I couldn't generate a useful response for that query." : "\(note.summary)\n\n\(note.details)"

                await MainActor.run {
                    messages.append(ChatMessage(role: .assistant, content: aiResponse))
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(role: .assistant, content: """
                    Sorry, I encountered an error: \(error.localizedDescription)

                    Please check your AI provider settings and try again.
                    """))
                    isProcessing = false
                }
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
