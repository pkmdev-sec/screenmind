import Foundation
import SQLite3
import Shared

/// Discovers and manages links between semantically related notes.
public actor LinkDiscoveryActor {
    private let semanticSearch: SemanticSearchActor
    private let linkDB: LinkDatabase

    public init(semanticSearch: SemanticSearchActor) {
        self.semanticSearch = semanticSearch
        self.linkDB = LinkDatabase()
    }

    /// Discover links for a newly saved note.
    public func discoverLinks(noteID: String, text: String) async throws -> [NoteLink] {
        // Find semantically similar notes
        let matches = try await semanticSearch.search(query: text, limit: 10)

        var links: [NoteLink] = []
        for match in matches where match.noteID != noteID && match.score > 0.6 {
            let link = NoteLink(
                fromNoteID: noteID,
                toNoteID: match.noteID,
                similarity: match.score
            )
            links.append(link)
        }

        // Store links
        try await linkDB.saveLinks(links)
        if !links.isEmpty {
            SMLogger.general.info("Discovered \(links.count) links for note \(noteID.prefix(8))")
        }
        return links
    }

    /// Get all links for a note (both directions).
    public func getLinks(for noteID: String) async throws -> [NoteLink] {
        try await linkDB.getLinks(for: noteID)
    }

    /// Get all links in the database (for graph visualization).
    public func getAllLinks() async throws -> [NoteLink] {
        try await linkDB.getAllLinks()
    }

    /// Setup the link database.
    public func setup() async throws {
        try await linkDB.open()
    }
}

/// A link between two related notes.
public struct NoteLink: Sendable, Identifiable {
    public let id: String
    public let fromNoteID: String
    public let toNoteID: String
    public let similarity: Float

    public init(fromNoteID: String, toNoteID: String, similarity: Float) {
        self.id = "\(fromNoteID)-\(toNoteID)"
        self.fromNoteID = fromNoteID
        self.toNoteID = toNoteID
        self.similarity = similarity
    }
}

/// SQLite storage for note links.
public actor LinkDatabase {
    private var db: OpaquePointer?

    public init() {}

    public func open() throws {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent(AppConstants.bundleIdentifier)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let path = dir.appendingPathComponent("links.sqlite").path

        guard sqlite3_open(path, &db) == SQLITE_OK else {
            throw EmbeddingError.databaseOpenFailed
        }

        let sql = """
        CREATE TABLE IF NOT EXISTS note_links (
            from_note_id TEXT NOT NULL,
            to_note_id TEXT NOT NULL,
            similarity REAL NOT NULL,
            created_at REAL NOT NULL,
            PRIMARY KEY (from_note_id, to_note_id)
        );
        CREATE INDEX IF NOT EXISTS idx_from ON note_links(from_note_id);
        CREATE INDEX IF NOT EXISTS idx_to ON note_links(to_note_id);
        """
        var err: UnsafeMutablePointer<CChar>?
        sqlite3_exec(db, sql, nil, nil, &err)
        if let err { sqlite3_free(err) }
    }

    public func saveLinks(_ links: [NoteLink]) throws {
        guard let db else { return }
        let sql = "INSERT OR REPLACE INTO note_links (from_note_id, to_note_id, similarity, created_at) VALUES (?, ?, ?, ?)"
        for link in links {
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { continue }
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_text(stmt, 1, link.fromNoteID, -1, nil)
            sqlite3_bind_text(stmt, 2, link.toNoteID, -1, nil)
            sqlite3_bind_double(stmt, 3, Double(link.similarity))
            sqlite3_bind_double(stmt, 4, Date.now.timeIntervalSince1970)
            sqlite3_step(stmt)
        }
    }

    public func getLinks(for noteID: String) throws -> [NoteLink] {
        guard let db else { return [] }
        let sql = "SELECT from_note_id, to_note_id, similarity FROM note_links WHERE from_note_id = ? OR to_note_id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, noteID, -1, nil)
        sqlite3_bind_text(stmt, 2, noteID, -1, nil)

        var results: [NoteLink] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let from = String(cString: sqlite3_column_text(stmt, 0))
            let to = String(cString: sqlite3_column_text(stmt, 1))
            let sim = Float(sqlite3_column_double(stmt, 2))
            results.append(NoteLink(fromNoteID: from, toNoteID: to, similarity: sim))
        }
        return results
    }

    public func getAllLinks() throws -> [NoteLink] {
        guard let db else { return [] }
        let sql = "SELECT from_note_id, to_note_id, similarity FROM note_links"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        var results: [NoteLink] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let from = String(cString: sqlite3_column_text(stmt, 0))
            let to = String(cString: sqlite3_column_text(stmt, 1))
            let sim = Float(sqlite3_column_double(stmt, 2))
            results.append(NoteLink(fromNoteID: from, toNoteID: to, similarity: sim))
        }
        return results
    }

    public func linkCount() throws -> Int {
        guard let db else { return 0 }
        let sql = "SELECT COUNT(*) FROM note_links"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_finalize(stmt) }
        return sqlite3_step(stmt) == SQLITE_ROW ? Int(sqlite3_column_int(stmt, 0)) : 0
    }
}
