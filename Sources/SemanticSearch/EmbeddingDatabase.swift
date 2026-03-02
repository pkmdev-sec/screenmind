import Foundation
import SQLite3
import Shared

/// SQLite-backed storage for note embeddings.
public actor EmbeddingDatabase {
    private var db: OpaquePointer?
    private let dbPath: String

    public init(customPath: String? = nil) {
        if let customPath = customPath {
            self.dbPath = customPath
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dir = appSupport.appendingPathComponent(AppConstants.bundleIdentifier)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            self.dbPath = dir.appendingPathComponent("embeddings.sqlite").path
        }
    }

    public func open() throws {
        // Ensure parent directory exists
        let parentDir = URL(fileURLWithPath: dbPath).deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
            throw EmbeddingError.databaseOpenFailed
        }
        // Create table
        let sql = """
        CREATE TABLE IF NOT EXISTS note_embeddings (
            note_id TEXT PRIMARY KEY,
            embedding BLOB NOT NULL,
            text_hash INTEGER NOT NULL,
            created_at REAL NOT NULL
        );
        """
        var err: UnsafeMutablePointer<CChar>?
        sqlite3_exec(db, sql, nil, nil, &err)
        if let err { sqlite3_free(err) }
    }

    public func save(noteID: String, embedding: [Float]) throws {
        guard let db else { throw EmbeddingError.databaseNotOpen }
        let sql = "INSERT OR REPLACE INTO note_embeddings (note_id, embedding, text_hash, created_at) VALUES (?, ?, ?, ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw EmbeddingError.queryFailed
        }
        defer { sqlite3_finalize(stmt) }

        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(stmt, 1, noteID, -1, transient)
        let data = embedding.withUnsafeBufferPointer { Data(buffer: $0) }
        _ = data.withUnsafeBytes { ptr in
            sqlite3_bind_blob(stmt, 2, ptr.baseAddress, Int32(data.count), transient)
        }
        sqlite3_bind_int64(stmt, 3, 0)
        sqlite3_bind_double(stmt, 4, Date.now.timeIntervalSince1970)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw EmbeddingError.queryFailed
        }
    }

    public func fetchAll() throws -> [(noteID: String, embedding: [Float])] {
        guard let db else { throw EmbeddingError.databaseNotOpen }
        let sql = "SELECT note_id, embedding FROM note_embeddings"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw EmbeddingError.queryFailed
        }
        defer { sqlite3_finalize(stmt) }

        var results: [(String, [Float])] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let noteID = String(cString: sqlite3_column_text(stmt, 0))
            let blobPtr = sqlite3_column_blob(stmt, 1)
            let blobSize = sqlite3_column_bytes(stmt, 1)

            if let blobPtr, blobSize > 0 {
                let count = Int(blobSize) / MemoryLayout<Float>.size
                let floats = Array(UnsafeBufferPointer(start: blobPtr.assumingMemoryBound(to: Float.self), count: count))
                results.append((noteID, floats))
            }
        }
        return results
    }

    public func delete(noteID: String) throws {
        guard let db else { throw EmbeddingError.databaseNotOpen }
        let sql = "DELETE FROM note_embeddings WHERE note_id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(stmt, 1, noteID, -1, transient)
        sqlite3_step(stmt)
    }

    public func count() throws -> Int {
        guard let db else { return 0 }
        let sql = "SELECT COUNT(*) FROM note_embeddings"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_finalize(stmt) }
        return sqlite3_step(stmt) == SQLITE_ROW ? Int(sqlite3_column_int(stmt, 0)) : 0
    }

    public func close() {
        sqlite3_close(db)
        db = nil
    }
}

public enum EmbeddingError: Error, LocalizedError {
    case databaseOpenFailed
    case databaseNotOpen
    case queryFailed
    case embeddingFailed

    public var errorDescription: String? {
        switch self {
        case .databaseOpenFailed: return "Failed to open embeddings database"
        case .databaseNotOpen: return "Embeddings database not open"
        case .queryFailed: return "Embeddings query failed"
        case .embeddingFailed: return "Failed to generate embedding"
        }
    }
}
