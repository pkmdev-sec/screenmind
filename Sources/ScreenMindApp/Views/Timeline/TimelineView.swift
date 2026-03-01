import SwiftUI
import SwiftData
import StorageCore
import Shared

/// Visual timeline of captured screenshots with filtering, search, and gallery/list toggle.
struct TimelineView: View {
    @Query(sort: \NoteModel.createdAt, order: .reverse) private var allNotes: [NoteModel]
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var searchDebounceTask: Task<Void, Never>?
    @State private var selectedCategory: String = "All"
    @State private var selectedDateRange: DateRange = .today
    @State private var viewMode: ViewMode = .gallery
    @State private var selectedNote: NoteModel?
    @State private var overlayNote: NoteModel?
    @State private var thumbnailCache = ThumbnailCache.shared

    private let categories = ["All", "coding", "research", "meeting", "communication", "reading", "terminal", "other"]
    private let gridColumns = [GridItem(.adaptive(minimum: 220, maximum: 300), spacing: 12)]

    enum ViewMode: String, CaseIterable {
        case gallery = "Gallery"
        case list = "List"

        var icon: String {
            switch self {
            case .gallery: return "square.grid.2x2"
            case .list: return "list.bullet"
            }
        }
    }

    enum DateRange: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case all = "All Time"

        var startDate: Date? {
            let calendar = Calendar.current
            switch self {
            case .today: return calendar.startOfDay(for: .now)
            case .week: return calendar.date(byAdding: .day, value: -7, to: .now)
            case .month: return calendar.date(byAdding: .month, value: -1, to: .now)
            case .all: return nil
            }
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Toolbar
                toolbar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.bar)

                Divider()

                // Content
                if filteredNotes.isEmpty {
                    emptyState
                } else {
                    switch viewMode {
                    case .gallery:
                        galleryView
                    case .list:
                        listView
                    }
                }

                // Status bar
                statusBar
            }

            // Screenshot overlay
            if let overlayNote {
                ScreenshotOverlayView(note: overlayNote) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        self.overlayNote = nil
                    }
                }
                .transition(.opacity)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))
                TextField("Search notes...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        debouncedSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: 300)
            .onChange(of: searchText) { _, newValue in
                searchDebounceTask?.cancel()
                searchDebounceTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    if !Task.isCancelled {
                        debouncedSearchText = newValue
                    }
                }
            }

            // Date range picker
            Picker("", selection: $selectedDateRange) {
                ForEach(DateRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 300)

            Spacer()

            // Category filter
            Picker("Category", selection: $selectedCategory) {
                ForEach(categories, id: \.self) { cat in
                    Text(cat == "All" ? "All Categories" : cat.capitalized).tag(cat)
                }
            }
            .frame(width: 150)

            // View mode toggle
            Picker("View", selection: $viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Image(systemName: mode.icon).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 80)
        }
    }

    // MARK: - Gallery View

    private var galleryView: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(filteredNotes) { note in
                    TimelineCardView(
                        note: note,
                        thumbnail: loadThumbnail(for: note),
                        isSelected: selectedNote?.id == note.id
                    )
                    .onTapGesture {
                        selectedNote = note
                    }
                    .onTapGesture(count: 2) {
                        withAnimation(.easeIn(duration: 0.2)) {
                            overlayNote = note
                        }
                    }
                    .contextMenu {
                        noteContextMenu(note)
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - List View

    private var listView: some View {
        List(selection: $selectedNote) {
            ForEach(filteredNotes) { note in
                HStack(spacing: 12) {
                    // Thumbnail
                    if let thumb = loadThumbnail(for: note) {
                        Image(nsImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.quaternary)
                            .frame(width: 80, height: 50)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.tertiary)
                            }
                    }

                    // Note info
                    VStack(alignment: .leading, spacing: 3) {
                        Text(note.title)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        Text(note.summary)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Metadata
                    VStack(alignment: .trailing, spacing: 3) {
                        CategoryBadge(category: note.category)
                        HStack(spacing: 4) {
                            Text(note.appName)
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                            Text(note.createdAt, style: .time)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .tag(note)
                .onTapGesture(count: 2) {
                    withAnimation(.easeIn(duration: 0.2)) {
                        overlayNote = note
                    }
                }
                .contextMenu {
                    noteContextMenu(note)
                }
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Captures", systemImage: "photo.on.rectangle.angled")
        } description: {
            if debouncedSearchText.isEmpty {
                Text("Screen captures will appear here as ScreenMind monitors your screen.")
            } else {
                Text("No notes match \"\(debouncedSearchText)\" in the selected time range.")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 12) {
            Divider().frame(height: 1)

            Text("\(filteredNotes.count) captures")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            if !debouncedSearchText.isEmpty {
                Text("matching \"\(debouncedSearchText)\"")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text(selectedDateRange.rawValue)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.bar)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func noteContextMenu(_ note: NoteModel) -> some View {
        Button("View Screenshot") {
            withAnimation { overlayNote = note }
        }
        Button("Copy Title") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(note.title, forType: .string)
        }
        Button("Copy Summary") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(note.summary, forType: .string)
        }
        if let screenshot = note.screenshot {
            Button("Reveal Screenshot in Finder") {
                NSWorkspace.shared.selectFile(screenshot.filePath, inFileViewerRootedAtPath: "")
            }
        }
    }

    // MARK: - Filtering

    private var filteredNotes: [NoteModel] {
        var notes = allNotes

        // Date filter
        if let startDate = selectedDateRange.startDate {
            notes = notes.filter { $0.createdAt >= startDate }
        }

        // Category filter
        if selectedCategory != "All" {
            notes = notes.filter { $0.category == selectedCategory }
        }

        // Text search (uses debounced value for performance)
        if !debouncedSearchText.isEmpty {
            let query = debouncedSearchText
            notes = notes.filter {
                $0.title.localizedCaseInsensitiveContains(query) ||
                $0.summary.localizedCaseInsensitiveContains(query) ||
                $0.appName.localizedCaseInsensitiveContains(query) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }

        return notes
    }

    // MARK: - Thumbnail Loading

    private func loadThumbnail(for note: NoteModel) -> NSImage? {
        guard let screenshot = note.screenshot else { return nil }
        return thumbnailCache.thumbnail(for: screenshot.filePath)
    }
}
