import Foundation

public actor HotFrameCache {
    public struct Entry: Sendable {
        public let frameID: UUID
        public let timestamp: Date
        public let appName: String
        public let windowTitle: String?
        public let thumbnailData: Data?
        public let hash: UInt64
        public var noteID: UUID?

        public init(frameID: UUID = UUID(), timestamp: Date, appName: String,
                   windowTitle: String? = nil, thumbnailData: Data? = nil,
                   hash: UInt64, noteID: UUID? = nil) {
            self.frameID = frameID
            self.timestamp = timestamp
            self.appName = appName
            self.windowTitle = windowTitle
            self.thumbnailData = thumbnailData
            self.hash = hash
            self.noteID = noteID
        }
    }

    private var entries: [Entry] = []
    private let maxEntries = 2000
    private var currentDay = Calendar.current.startOfDay(for: .now)

    public init() {}

    public func insert(_ entry: Entry) {
        // Day rollover eviction
        let entryDay = Calendar.current.startOfDay(for: entry.timestamp)
        if entryDay > currentDay {
            entries.removeAll()
            currentDay = entryDay
        }

        // Insert maintaining sorted order
        let idx = entries.firstIndex { $0.timestamp > entry.timestamp } ?? entries.endIndex
        entries.insert(entry, at: idx)

        // Evict oldest if over capacity
        if entries.count > maxEntries {
            entries.removeFirst()
        }
    }

    public func query(from start: Date, to end: Date) -> [Entry] {
        entries.filter { $0.timestamp >= start && $0.timestamp <= end }
    }

    public func recent(_ count: Int) -> [Entry] {
        Array(entries.suffix(count))
    }

    public func entryCount() -> Int { entries.count }
}
