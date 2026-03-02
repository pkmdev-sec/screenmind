import Foundation
import Testing
@testable import SemanticSearch

// MARK: - HNSW Index Tests

@Test func hnswIndexInitializes() async {
    let index = HNSWIndex()
    let count = await index.count
    #expect(count == 0)
}

@Test func hnswIndexInsertAndSearch() async {
    let index = HNSWIndex()

    // Insert some vectors
    let vectors: [(String, [Float])] = [
        ("note1", [1.0, 0.0, 0.0, 0.0]),
        ("note2", [0.9, 0.1, 0.0, 0.0]), // Similar to note1
        ("note3", [0.0, 1.0, 0.0, 0.0]),
        ("note4", [0.0, 0.0, 1.0, 0.0]),
    ]

    for (id, vector) in vectors {
        await index.insert(id: id, vector: vector)
    }

    let count = await index.count
    #expect(count == 4)

    // Search for vector similar to note1
    let query: [Float] = [1.0, 0.0, 0.0, 0.0]
    let results = await index.search(query: query, k: 2)

    #expect(results.count <= 2)
    // First result should be note1 or note2 (both similar to query)
    if let first = results.first {
        #expect(first.noteID == "note1" || first.noteID == "note2")
        #expect(first.score > 0.8)
    }
}

@Test func hnswIndexRemove() async {
    let index = HNSWIndex()

    await index.insert(id: "note1", vector: [1.0, 0.0, 0.0])
    await index.insert(id: "note2", vector: [0.0, 1.0, 0.0])

    var count = await index.count
    #expect(count == 2)

    await index.remove(id: "note1")
    count = await index.count
    #expect(count == 1)

    // Search should not return removed note
    let results = await index.search(query: [1.0, 0.0, 0.0], k: 5)
    #expect(results.allSatisfy { $0.noteID != "note1" })
}

@Test func hnswIndexSaveAndLoad() async throws {
    let index1 = HNSWIndex()

    // Insert data
    await index1.insert(id: "note1", vector: [1.0, 2.0, 3.0])
    await index1.insert(id: "note2", vector: [4.0, 5.0, 6.0])

    // Save
    try await index1.save()

    // Create new index and load
    let index2 = HNSWIndex()
    try await index2.load()

    let count = await index2.count
    #expect(count == 2)

    // Search should work on loaded index
    let results = await index2.search(query: [1.0, 2.0, 3.0], k: 1)
    #expect(results.count > 0)
    if let first = results.first {
        #expect(first.noteID == "note1")
    }
}

@Test func hnswIndexEmptySearch() async {
    let index = HNSWIndex()
    let results = await index.search(query: [1.0, 0.0, 0.0], k: 5)
    #expect(results.isEmpty)
}

@Test func hnswIndexLargeK() async {
    let index = HNSWIndex()

    // Insert 5 vectors
    for i in 0..<5 {
        let vector = [Float](repeating: Float(i), count: 10)
        await index.insert(id: "note\(i)", vector: vector)
    }

    // Request k=100 (more than available)
    let results = await index.search(query: [Float](repeating: 0.0, count: 10), k: 100)
    #expect(results.count <= 5)
}

@Test func hnswIndexHighDimensional() async {
    let index = HNSWIndex()

    // Test with higher dimensional vectors (similar to real embeddings)
    let dim = 512
    let vector1 = [Float](repeating: 1.0, count: dim)
    let vector2 = [Float](repeating: 0.5, count: dim)

    await index.insert(id: "high1", vector: vector1)
    await index.insert(id: "high2", vector: vector2)

    let results = await index.search(query: vector1, k: 1)
    #expect(results.count > 0)
    if let first = results.first {
        #expect(first.noteID == "high1")
        #expect(first.score > 0.9) // Should be very similar to itself
    }
}

@Test func hnswIndexCosineSimilarity() async {
    let index = HNSWIndex()

    // Orthogonal vectors (should have low similarity)
    await index.insert(id: "ortho1", vector: [1.0, 0.0, 0.0])
    await index.insert(id: "ortho2", vector: [0.0, 1.0, 0.0])

    let results = await index.search(query: [1.0, 0.0, 0.0], k: 2)
    if results.count >= 2 {
        // First should be similar, second should be orthogonal (low score)
        #expect(results[0].score > 0.9)
        #expect(results[1].score < 0.1)
    }
}
