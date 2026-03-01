import Foundation
import Shared

/// LRU cache for OCR results keyed by perceptual hash.
/// Avoids re-processing frames that are visually similar to recently OCR'd frames.
public actor OCRCache {
    /// Cached OCR result.
    public struct CachedResult: Sendable {
        public let text: String
        public let confidence: Double
        public let wordCount: Int
        public let cachedAt: Date
    }

    private var cache: [UInt64: CachedResult] = [:]
    private var accessOrder: [UInt64] = []
    private let maxSize: Int
    private let ttlSeconds: TimeInterval
    private var hits: UInt64 = 0
    private var misses: UInt64 = 0

    public init(maxSize: Int = 100, ttlSeconds: TimeInterval = 86400) {
        self.maxSize = maxSize
        self.ttlSeconds = ttlSeconds // 24-hour default TTL
    }

    /// Look up a cached OCR result by perceptual hash.
    /// Returns nil if not found, expired, or below confidence threshold.
    public func get(hash: UInt64, minConfidence: Double = 0.3) -> CachedResult? {
        guard let result = cache[hash] else {
            misses += 1
            return nil
        }

        // TTL check — evict stale entries
        if Date.now.timeIntervalSince(result.cachedAt) > ttlSeconds {
            evict(hash: hash)
            misses += 1
            return nil
        }

        // Confidence check — don't serve low-quality cached results
        guard result.confidence >= minConfidence else {
            misses += 1
            return nil
        }

        // Move to end of access order (LRU)
        accessOrder.removeAll { $0 == hash }
        accessOrder.append(hash)

        hits += 1
        SMLogger.ocr.debug("OCR cache hit for hash \(hash)")
        return result
    }

    /// Store an OCR result in the cache. Updates existing entries in-place.
    public func put(hash: UInt64, text: String, confidence: Double, wordCount: Int) {
        // Update existing entry (don't evict on re-insert)
        if cache[hash] != nil {
            cache[hash] = CachedResult(text: text, confidence: confidence, wordCount: wordCount, cachedAt: .now)
            accessOrder.removeAll { $0 == hash }
            accessOrder.append(hash)
            return
        }

        // Evict oldest if at capacity
        if cache.count >= maxSize, let oldest = accessOrder.first {
            evict(hash: oldest)
        }

        cache[hash] = CachedResult(text: text, confidence: confidence, wordCount: wordCount, cachedAt: .now)
        accessOrder.append(hash)
    }

    /// Cache statistics.
    public var stats: (hits: UInt64, misses: UInt64, size: Int, hitRate: Double) {
        let total = hits + misses
        let rate = total > 0 ? Double(hits) / Double(total) : 0
        return (hits, misses, cache.count, rate)
    }

    /// Clear the cache.
    public func clear() {
        cache.removeAll()
        accessOrder.removeAll()
        hits = 0
        misses = 0
    }

    // MARK: - Private

    private func evict(hash: UInt64) {
        cache.removeValue(forKey: hash)
        accessOrder.removeAll { $0 == hash }
    }
}
