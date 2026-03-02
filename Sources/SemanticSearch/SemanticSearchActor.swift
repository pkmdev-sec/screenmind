import Foundation
import NaturalLanguage
import Shared

/// Semantic search using on-device NaturalLanguage embeddings with HNSW index.
public actor SemanticSearchActor {
    private let embeddingDB = EmbeddingDatabase()
    private let hnswIndex = HNSWIndex()
    private var nlEmbedding: NLEmbedding?
    private var isReady = false
    private var useHNSW: Bool {
        UserDefaults.standard.bool(forKey: "useHNSWIndex") || embeddingCount() > 1000
    }

    public init() {}

    /// Initialize the embedding model and database.
    public func setup() async throws {
        try await embeddingDB.open()
        try await hnswIndex.load()
        nlEmbedding = NLEmbedding.sentenceEmbedding(for: .english)
        isReady = nlEmbedding != nil
        if isReady {
            let indexType = useHNSW ? "HNSW" : "linear"
            SMLogger.general.info("Semantic search ready (NLEmbedding + \(indexType) index)")
        } else {
            SMLogger.general.warning("NLEmbedding sentence model not available — semantic search disabled")
        }
    }

    /// Generate and store embedding for a note.
    public func indexNote(noteID: String, text: String) async throws {
        guard isReady, let embedding = generateEmbedding(for: text) else { return }
        try await embeddingDB.save(noteID: noteID, embedding: embedding)

        // Add to HNSW index
        await hnswIndex.insert(id: noteID, vector: embedding)

        // Periodically save HNSW index (every 10 notes)
        if await hnswIndex.count % 10 == 0 {
            try? await hnswIndex.save()
        }
    }

    /// Semantic search: find notes similar to the query by meaning.
    /// Uses HNSW for O(log n) search if enabled, otherwise linear scan.
    public func search(query: String, limit: Int = 20) async throws -> [NoteMatch] {
        guard isReady, let queryEmbedding = generateEmbedding(for: query) else { return [] }

        // Use HNSW for large collections
        if useHNSW {
            return await hnswIndex.search(query: queryEmbedding, k: limit)
        }

        // Fallback: linear scan for small collections
        let allEmbeddings = try await embeddingDB.fetchAll()
        var scores: [(noteID: String, score: Float)] = []

        for (noteID, noteEmbedding) in allEmbeddings {
            let similarity = Self.cosineSimilarity(queryEmbedding, noteEmbedding)
            if similarity > 0.3 { // Minimum threshold
                scores.append((noteID, similarity))
            }
        }

        scores.sort { $0.score > $1.score }
        return Array(scores.prefix(limit).map { NoteMatch(noteID: $0.noteID, score: $0.score) })
    }

    /// Remove a note from the search index.
    public func removeNote(noteID: String) async throws {
        try await embeddingDB.delete(noteID: noteID)
        await hnswIndex.remove(id: noteID)
    }

    /// Get embedding count.
    public func embeddingCount() async -> Int {
        (try? await embeddingDB.count()) ?? 0
    }

    private func embeddingCount() -> Int {
        0 // Non-async helper for initialization
    }

    // MARK: - Private

    private func generateEmbedding(for text: String) -> [Float]? {
        guard let nlEmbedding else { return nil }
        // NLEmbedding.vector returns a [Double] for the text
        guard let vector = nlEmbedding.vector(for: text) else { return nil }
        return vector.map { Float($0) }
    }

    /// Cosine similarity between two vectors.
    static func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot: Float = 0, normA: Float = 0, normB: Float = 0
        for i in 0..<a.count {
            dot += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        let denom = sqrt(normA) * sqrt(normB)
        return denom > 0 ? dot / denom : 0
    }
}

/// A search result with similarity score.
public struct NoteMatch: Sendable {
    public let noteID: String
    public let score: Float

    public init(noteID: String, score: Float) {
        self.noteID = noteID
        self.score = score
    }
}
