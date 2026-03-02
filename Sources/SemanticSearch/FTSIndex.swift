import Foundation
import SQLite3
import Shared

public actor FTSIndex {
    private var db: OpaquePointer?
    private let dbPath: String

    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("com.screenmind.app")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.dbPath = dir.appendingPathComponent("fts_index.db").path
    }

    public func setup() throws {
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else { throw FTSError.openFailed }
        let sql = "CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(note_id UNINDEXED, title, content, app_name, tokenize='porter unicode61');"
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else { throw FTSError.createFailed }
    }

    public func indexNote(noteID: String, title: String, content: String, appName: String) throws {
        let sql = "INSERT OR REPLACE INTO notes_fts (note_id, title, content, app_name) VALUES (?, ?, ?, ?)"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { throw FTSError.insertFailed }
        sqlite3_bind_text(stmt, 1, (noteID as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (title as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (content as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 4, (appName as NSString).utf8String, -1, nil)
        sqlite3_step(stmt)
    }

    public func search(query: String, limit: Int = 20) throws -> [String] {
        let sql = "SELECT note_id FROM notes_fts WHERE notes_fts MATCH ? ORDER BY rank LIMIT ?"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { throw FTSError.searchFailed }
        sqlite3_bind_text(stmt, 1, (query as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 2, Int32(limit))
        var results: [String] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let c = sqlite3_column_text(stmt, 0) { results.append(String(cString: c)) }
        }
        return results
    }

    public func removeNote(noteID: String) throws {
        let sql = "DELETE FROM notes_fts WHERE note_id = ?"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_text(stmt, 1, (noteID as NSString).utf8String, -1, nil)
        sqlite3_step(stmt)
    }

    /// Explicitly shut down the FTS index and close the database connection.
    /// Call this before deinit if possible to ensure clean shutdown.
    public func shutdown() {
        if let db {
            sqlite3_close_v2(db)
            self.db = nil
            SMLogger.system.debug("FTS index database closed")
        }
    }

    deinit {
        if let db {
            sqlite3_close_v2(db)
            SMLogger.system.debug("FTS index database closed in deinit")
        }
    }
}

public enum FTSError: Error, Sendable { case openFailed, createFailed, insertFailed, searchFailed }
