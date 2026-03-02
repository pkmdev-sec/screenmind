import Foundation
import Shared

public actor HybridSearch {
    private let semanticSearch: SemanticSearchActor
    private let ftsIndex: FTSIndex
    private var cache: [String: (results: [HybridMatch], timestamp: Date)] = [:]
    private let cacheTTL: TimeInterval = 300
    private let maxCache = 100

    public init(semanticSearch: SemanticSearchActor, ftsIndex: FTSIndex) {
        self.semanticSearch = semanticSearch; self.ftsIndex = ftsIndex
    }

    public func search(query: String, limit: Int = 20) async throws -> [HybridMatch] {
        if let c = cache[query], Date.now.timeIntervalSince(c.timestamp) < cacheTTL { return c.results }

        async let sem = semanticSearch.search(query: query, limit: limit)
        async let fts = try ftsIndex.search(query: query, limit: limit)
        let (semResults, ftsResults) = try await (sem, fts)

        let k: Float = 60
        var scores: [String: (sem: Float, fts: Float)] = [:]
        for (i, m) in semResults.enumerated() { scores[m.noteID, default: (0,0)].sem = 1.0 / (k + Float(i)) }
        for (i, id) in ftsResults.enumerated() { scores[id, default: (0,0)].fts = 1.0 / (k + Float(i)) }

        let results = scores.map { HybridMatch(noteID: $0.key, score: $0.value.sem + $0.value.fts, semanticScore: $0.value.sem, ftsScore: $0.value.fts) }
            .sorted { $0.score > $1.score }.prefix(limit).map { $0 }

        cache[query] = (results, .now)
        if cache.count > maxCache { if let old = cache.min(by: { $0.value.timestamp < $1.value.timestamp })?.key { cache.removeValue(forKey: old) } }
        return results
    }

    public func clearCache() { cache.removeAll() }
}

public struct HybridMatch: Sendable {
    public let noteID: String
    public let score: Float
    public let semanticScore: Float
    public let ftsScore: Float
}
