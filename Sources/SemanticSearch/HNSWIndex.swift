import Foundation
import Shared

/// Hierarchical Navigable Small World (HNSW) graph for approximate nearest neighbor search.
/// Provides O(log n) query time vs O(n) linear scan.
public actor HNSWIndex {
    // MARK: - Configuration
    private let M: Int = 16 // Max connections per layer
    private let efConstruction: Int = 200 // Beam width during construction
    private let efSearch: Int = 100 // Beam width during search
    private let maxLevel: Int = 16

    // MARK: - Data Structures
    private var nodes: [String: Node] = [:] // noteID -> Node
    private var entryPoint: String? // Top-level entry node
    private let storageURL: URL

    private struct Node: Codable {
        var id: String
        var vector: [Float]
        var level: Int
        var connections: [Int: [String]] // level -> neighbor IDs

        init(id: String, vector: [Float], level: Int) {
            self.id = id
            self.vector = vector
            self.level = level
            self.connections = [:]
        }
    }

    // MARK: - Initialization

    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent(AppConstants.bundleIdentifier)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.storageURL = dir.appendingPathComponent("hnsw_index.bin")
    }

    /// Load index from disk.
    public func load() throws {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            SMLogger.general.info("HNSW index not found — starting fresh")
            return
        }

        let data = try Data(contentsOf: storageURL)
        let decoder = JSONDecoder()
        let state = try decoder.decode(IndexState.self, from: data)

        self.nodes = state.nodes
        self.entryPoint = state.entryPoint

        SMLogger.general.info("HNSW index loaded: \(self.nodes.count) nodes")
    }

    /// Save index to disk.
    public func save() throws {
        let state = IndexState(nodes: nodes, entryPoint: entryPoint)
        let encoder = JSONEncoder()
        let data = try encoder.encode(state)
        try data.write(to: storageURL, options: .atomic)

        SMLogger.general.info("HNSW index saved: \(self.nodes.count) nodes")
    }

    // MARK: - Index Operations

    /// Add a vector to the index.
    public func insert(id: String, vector: [Float]) {
        // Determine random level for new node (exponential decay)
        let level = randomLevel()
        let node = Node(id: id, vector: vector, level: level)
        nodes[id] = node

        // First node becomes entry point
        guard let entry = entryPoint else {
            entryPoint = id
            return
        }

        // Insert into layers from top to bottom
        var currentNeighbors = [entry]
        for lc in stride(from: level, through: 0, by: -1) {
            // Find nearest neighbors at this layer
            let nearest = searchLayer(query: vector, entryPoints: currentNeighbors, k: efConstruction, level: lc)

            // Connect to M nearest neighbors
            let neighbors = selectNeighbors(candidates: nearest, M: M)
            nodes[id]?.connections[lc] = neighbors

            // Bidirectional connections
            for neighborID in neighbors {
                if nodes[neighborID]?.connections[lc] == nil {
                    nodes[neighborID]?.connections[lc] = []
                }
                nodes[neighborID]?.connections[lc]?.append(id)

                // Prune if exceeds M connections
                if let connections = nodes[neighborID]?.connections[lc], connections.count > M {
                    let pruned = selectNeighbors(candidates: connections, M: M)
                    nodes[neighborID]?.connections[lc] = pruned
                }
            }

            currentNeighbors = nearest
        }
    }

    /// Remove a vector from the index.
    public func remove(id: String) {
        guard let node = nodes[id] else { return }

        // Remove all bidirectional connections
        for (level, neighbors) in node.connections {
            for neighborID in neighbors {
                nodes[neighborID]?.connections[level]?.removeAll { $0 == id }
            }
        }

        nodes.removeValue(forKey: id)

        // Update entry point if removed
        if entryPoint == id {
            entryPoint = nodes.keys.first
        }
    }

    /// Search for k nearest neighbors (approximate).
    public func search(query: [Float], k: Int) -> [NoteMatch] {
        guard let entry = entryPoint, !nodes.isEmpty else { return [] }

        // Top-down search
        var currentNearest = [entry]
        let maxNodeLevel = nodes[entry]?.level ?? 0

        // Traverse from top layer to layer 0
        for lc in stride(from: maxNodeLevel, to: 0, by: -1) {
            currentNearest = searchLayer(query: query, entryPoints: currentNearest, k: 1, level: lc)
        }

        // Search layer 0 with efSearch beam width
        let results = searchLayer(query: query, entryPoints: currentNearest, k: efSearch, level: 0)

        // Return top k with scores
        return results.prefix(k).compactMap { id in
            guard let node = nodes[id] else { return nil }
            let similarity = cosineSimilarity(query, node.vector)
            return NoteMatch(noteID: id, score: similarity)
        }
    }

    /// Number of vectors in the index.
    public var count: Int {
        nodes.count
    }

    // MARK: - Private Helpers

    /// Search a single layer for nearest neighbors.
    private func searchLayer(query: [Float], entryPoints: [String], k: Int, level: Int) -> [String] {
        var visited = Set<String>()
        var candidates = PriorityQueue<(String, Float)>(sort: { $0.1 > $1.1 }) // Max heap (worst first)
        var results = PriorityQueue<(String, Float)>(sort: { $0.1 < $1.1 }) // Min heap (best first)

        for ep in entryPoints {
            guard let node = nodes[ep] else { continue }
            let dist = distance(query, node.vector)
            candidates.enqueue((ep, dist))
            results.enqueue((ep, dist))
            visited.insert(ep)
        }

        while let (currentID, currentDist) = candidates.dequeue() {
            if currentDist > results.peek()?.1 ?? .infinity { break }

            // Explore neighbors at this level
            guard let connections = nodes[currentID]?.connections[level] else { continue }
            for neighborID in connections {
                guard !visited.contains(neighborID), let neighbor = nodes[neighborID] else { continue }
                visited.insert(neighborID)

                let dist = distance(query, neighbor.vector)
                if dist < results.peek()?.1 ?? .infinity || results.count < k {
                    candidates.enqueue((neighborID, dist))
                    results.enqueue((neighborID, dist))
                    if results.count > k {
                        _ = results.dequeue() // Remove worst
                    }
                }
            }
        }

        return results.allItems.map { $0.0 }
    }

    /// Select M best neighbors using a heuristic (simple: closest by distance).
    private func selectNeighbors(candidates: [String], M: Int) -> [String] {
        Array(candidates.prefix(M))
    }

    /// Random level with exponential decay.
    private func randomLevel() -> Int {
        let ml = 1.0 / log(Double(M))
        let level = Int(-log(Double.random(in: 0.0..<1.0)) * ml)
        return min(level, maxLevel)
    }

    /// Euclidean distance between two vectors.
    private func distance(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return .infinity }
        var sum: Float = 0
        for i in 0..<a.count {
            let diff = a[i] - b[i]
            sum += diff * diff
        }
        return sqrt(sum)
    }

    /// Cosine similarity (for final scoring).
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
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

    // MARK: - Serialization

    private struct IndexState: Codable {
        var nodes: [String: Node]
        var entryPoint: String?
    }
}

// MARK: - Priority Queue (Min/Max Heap)

private struct PriorityQueue<T> {
    private var items: [T] = []
    private let sort: (T, T) -> Bool

    var count: Int { items.count }

    init(sort: @escaping (T, T) -> Bool) {
        self.sort = sort
    }

    mutating func enqueue(_ item: T) {
        items.append(item)
        items.sort(by: sort)
    }

    mutating func dequeue() -> T? {
        items.isEmpty ? nil : items.removeFirst()
    }

    func peek() -> T? {
        items.first
    }

    var allItems: [T] {
        items
    }
}
