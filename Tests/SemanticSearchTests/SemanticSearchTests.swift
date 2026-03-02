import Foundation
import Testing
@testable import SemanticSearch

// MARK: - EmbeddingDatabase Tests

@Test func embeddingDatabaseOpenAndClose() async throws {
    let tempPath = NSTemporaryDirectory() + "test-\(UUID().uuidString).sqlite"
    let db = EmbeddingDatabase(customPath: tempPath)
    try await db.open()
    await db.close()
    try? FileManager.default.removeItem(atPath: tempPath)
}

@Test func embeddingDatabaseSaveAndFetch() async throws {
    let tempPath = NSTemporaryDirectory() + "test-\(UUID().uuidString).sqlite"
    let db = EmbeddingDatabase(customPath: tempPath)
    try await db.open()
    defer { 
        Task { 
            await db.close()
            try? FileManager.default.removeItem(atPath: tempPath)
        } 
    }

    let noteID = UUID().uuidString
    let embedding: [Float] = [0.1, 0.2, 0.3, 0.4, 0.5]
    try await db.save(noteID: noteID, embedding: embedding)

    let results = try await db.fetchAll()
    #expect(results.count >= 1)

    let found = results.first { $0.noteID == noteID }
    #expect(found != nil)
    #expect(found?.embedding.count == 5)
    // Float comparison with tolerance
    if let fetched = found?.embedding {
        #expect(abs(fetched[0] - 0.1) < 0.001)
        #expect(abs(fetched[4] - 0.5) < 0.001)
    }
}

@Test func embeddingDatabaseCount() async throws {
    let tempPath = NSTemporaryDirectory() + "test-\(UUID().uuidString).sqlite"
    let db = EmbeddingDatabase(customPath: tempPath)
    try await db.open()
    defer { 
        Task { 
            await db.close()
            try? FileManager.default.removeItem(atPath: tempPath)
        } 
    }

    let initialCount = try await db.count()
    let noteID = "count-test-\(UUID().uuidString)"
    try await db.save(noteID: noteID, embedding: [1.0, 2.0, 3.0])
    let newCount = try await db.count()
    #expect(newCount == initialCount + 1)

    // Cleanup
    try await db.delete(noteID: noteID)
}

@Test func embeddingDatabaseDelete() async throws {
    let tempPath = NSTemporaryDirectory() + "test-\(UUID().uuidString).sqlite"
    let db = EmbeddingDatabase(customPath: tempPath)
    try await db.open()
    defer { 
        Task { 
            await db.close()
            try? FileManager.default.removeItem(atPath: tempPath)
        } 
    }

    let noteID = "delete-test-\(UUID().uuidString)"
    try await db.save(noteID: noteID, embedding: [1.0])
    try await db.delete(noteID: noteID)

    let results = try await db.fetchAll()
    let found = results.first { $0.noteID == noteID }
    #expect(found == nil)
}

@Test func embeddingDatabaseUpsert() async throws {
    let tempPath = NSTemporaryDirectory() + "test-\(UUID().uuidString).sqlite"
    let db = EmbeddingDatabase(customPath: tempPath)
    try await db.open()
    defer { 
        Task { 
            await db.close()
            try? FileManager.default.removeItem(atPath: tempPath)
        } 
    }

    let noteID = "upsert-test-\(UUID().uuidString)"
    try await db.save(noteID: noteID, embedding: [1.0, 2.0])
    try await db.save(noteID: noteID, embedding: [3.0, 4.0]) // Should update, not duplicate

    let results = try await db.fetchAll()
    let matches = results.filter { $0.noteID == noteID }
    #expect(matches.count == 1) // Only one entry
    if matches.count > 0 {
        #expect(abs(matches[0].embedding[0] - 3.0) < 0.001) // Updated value
    }

    // Cleanup
    try await db.delete(noteID: noteID)
}

// MARK: - EmbeddingError Tests

@Test func embeddingErrorDescriptions() {
    #expect(EmbeddingError.databaseOpenFailed.errorDescription != nil)
    #expect(EmbeddingError.databaseNotOpen.errorDescription != nil)
    #expect(EmbeddingError.queryFailed.errorDescription != nil)
    #expect(EmbeddingError.embeddingFailed.errorDescription != nil)
}

@Test func embeddingDatabaseThrowsWhenNotOpen() async {
    let tempPath = NSTemporaryDirectory() + "test-\(UUID().uuidString).sqlite"
    let db = EmbeddingDatabase(customPath: tempPath)
    // Don't open — should throw
    do {
        try await db.save(noteID: "test", embedding: [1.0])
        #expect(Bool(false), "Should have thrown")
    } catch {
        #expect(error is EmbeddingError)
    }
    try? FileManager.default.removeItem(atPath: tempPath)
}
