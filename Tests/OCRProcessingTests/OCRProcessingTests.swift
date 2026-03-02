import Testing
import Foundation
@testable import OCRProcessing

// MARK: - OCRProcessingActor Tests

@Test func ocrActorInitializes() async {
    let actor = OCRProcessingActor()
    let stats = await actor.stats
    #expect(stats.processed == 0)
}

// MARK: - TextPreprocessor Tests

@Test func textPreprocessorCleans() {
    let input: [(text: String, confidence: Float)] = [
        ("Hello World", 0.9),
        ("Hello World", 0.9), // duplicate
        ("Some text here", 0.8),
        ("low confidence", 0.1), // below threshold
    ]
    let (text, avg, wordCount) = TextPreprocessor.clean(input)
    #expect(wordCount == 4) // "Hello World Some text here" = 5 words -> "Hello World", "Some text here" deduplicated
    #expect(avg > 0.5)
    #expect(!text.isEmpty)
}

@Test func textPreprocessorTruncates() {
    let longText = String(repeating: "word ", count: 1000)
    let truncated = TextPreprocessor.truncate(longText, maxCharacters: 100)
    #expect(truncated.count <= 103) // 100 + "..."
    #expect(truncated.hasSuffix("..."))
}

// MARK: - ContentRedactor Tests

@Test func contentRedactorRedactsSSN() {
    // Remove key to use default (enabled)
    UserDefaults.standard.removeObject(forKey: "privacyRedactionEnabled")

    let text = "My SSN is 123-45-6789 and another is 987654321"
    let result = ContentRedactor.redact(text)

    #expect(result.text.contains("[REDACTED]"))
    #expect(!result.text.contains("123-45-6789"))
    #expect(result.redactionCount > 0)
    #expect(result.redactedTypes.contains("ssn"))
}

@Test func contentRedactorRedactsCreditCard() {
    UserDefaults.standard.removeObject(forKey: "privacyRedactionEnabled")

    let text = "Card number: 4532-1488-0343-6467"
    let result = ContentRedactor.redact(text)

    #expect(result.text.contains("[REDACTED]"))
    #expect(!result.text.contains("4532"))
    #expect(result.redactionCount > 0)
    #expect(result.redactedTypes.contains("credit-card"))
}

@Test func contentRedactorRedactsAPIKeys() {
    UserDefaults.standard.removeObject(forKey: "privacyRedactionEnabled")

    // Patterns require minimum 20 characters after the prefix
    let text = "My API key is sk-ant-abcdef1234567890123456789012 and OpenAI key sk-1234567890abcdefghij1234567890"
    let result = ContentRedactor.redact(text)

    #expect(result.text.contains("[REDACTED]"))
    #expect(!result.text.contains("sk-ant"))
    #expect(result.redactionCount > 0)
}

@Test func contentRedactorRedactsEmail() {
    UserDefaults.standard.removeObject(forKey: "privacyRedactionEnabled")

    let text = "Contact me at user@example.com for details"
    let result = ContentRedactor.redact(text)

    #expect(result.text.contains("[REDACTED]"))
    #expect(!result.text.contains("user@example.com"))
    #expect(result.redactionCount > 0)
    #expect(result.redactedTypes.contains("email"))
}

@Test func contentRedactorRedactsBearerToken() {
    UserDefaults.standard.removeObject(forKey: "privacyRedactionEnabled")

    let text = "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
    let result = ContentRedactor.redact(text)

    #expect(result.text.contains("[REDACTED]"))
    #expect(!result.text.contains("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"))
    #expect(result.redactionCount > 0)
    #expect(result.redactedTypes.contains("bearer-token"))
}

@Test func contentRedactorCustomPatterns() {
    UserDefaults.standard.removeObject(forKey: "privacyRedactionEnabled")

    // Save a custom pattern
    let customPattern = ContentRedactor.CustomPattern(
        name: "test-id",
        pattern: #"\bTEST-\d{4}\b"#,
        enabled: true
    )
    ContentRedactor.saveCustomPatterns([customPattern])

    let text = "My test ID is TEST-1234"
    let result = ContentRedactor.redact(text)

    #expect(result.text.contains("[REDACTED]"))
    #expect(!result.text.contains("TEST-1234"))
    #expect(result.redactionCount > 0)
    #expect(result.redactedTypes.contains { $0.contains("test-id") })

    // Cleanup
    ContentRedactor.saveCustomPatterns([])
    UserDefaults.standard.removeObject(forKey: "privacyRedactionEnabled")
}

@Test func contentRedactorDisabledMode() {
    // Disable redaction
    UserDefaults.standard.set(false, forKey: "privacyRedactionEnabled")

    let text = "My SSN is 123-45-6789 and email user@example.com"
    let result = ContentRedactor.redact(text)

    #expect(result.text == text) // No redaction
    #expect(result.redactionCount == 0)
    #expect(result.redactedTypes.isEmpty)

    // Cleanup - remove the key for other tests
    UserDefaults.standard.removeObject(forKey: "privacyRedactionEnabled")
}

@Test func contentRedactorValidatePattern() {
    #expect(ContentRedactor.validatePattern(#"\d{3}-\d{2}-\d{4}"#) == true)
    #expect(ContentRedactor.validatePattern("[invalid(") == false)
}

// MARK: - OCRCache Tests

@Test func ocrCacheMissReturnsNil() async {
    let cache = OCRCache()
    let result = await cache.get(hash: 12345)
    #expect(result == nil)

    let stats = await cache.stats
    #expect(stats.misses == 1)
    #expect(stats.hits == 0)
}

@Test func ocrCachePutAndGet() async {
    let cache = OCRCache()
    let hash: UInt64 = 12345

    await cache.put(hash: hash, text: "Hello World", confidence: 0.95, wordCount: 2)
    let result = await cache.get(hash: hash)

    #expect(result != nil)
    #expect(result?.text == "Hello World")
    #expect(result?.confidence == 0.95)
    #expect(result?.wordCount == 2)

    let stats = await cache.stats
    #expect(stats.hits == 1)
    #expect(stats.size == 1)
}

@Test func ocrCacheTTLExpiration() async {
    let cache = OCRCache(maxSize: 10, ttlSeconds: 0.1) // 100ms TTL
    let hash: UInt64 = 12345

    await cache.put(hash: hash, text: "Test", confidence: 0.9, wordCount: 1)

    // Immediate retrieval should work
    let result1 = await cache.get(hash: hash)
    #expect(result1 != nil)

    // Wait for TTL expiration
    try? await Task.sleep(nanoseconds: 150_000_000) // 150ms

    let result2 = await cache.get(hash: hash)
    #expect(result2 == nil) // Expired

    let stats = await cache.stats
    #expect(stats.misses == 1) // Second get was a miss
}

@Test func ocrCacheLRUEviction() async {
    let cache = OCRCache(maxSize: 3)

    // Fill cache to capacity
    await cache.put(hash: 1, text: "Text1", confidence: 0.9, wordCount: 1)
    await cache.put(hash: 2, text: "Text2", confidence: 0.9, wordCount: 1)
    await cache.put(hash: 3, text: "Text3", confidence: 0.9, wordCount: 1)

    var stats = await cache.stats
    #expect(stats.size == 3)

    // Add one more — should evict hash 1 (oldest)
    await cache.put(hash: 4, text: "Text4", confidence: 0.9, wordCount: 1)

    stats = await cache.stats
    #expect(stats.size == 3) // Still at max capacity

    // Hash 1 should be evicted
    let result1 = await cache.get(hash: 1)
    #expect(result1 == nil)

    // Hash 4 should exist
    let result4 = await cache.get(hash: 4)
    #expect(result4 != nil)
}

@Test func ocrCacheStatsTracking() async {
    let cache = OCRCache()

    await cache.put(hash: 1, text: "Test", confidence: 0.9, wordCount: 1)

    _ = await cache.get(hash: 1) // Hit
    _ = await cache.get(hash: 1) // Hit
    _ = await cache.get(hash: 2) // Miss
    _ = await cache.get(hash: 3) // Miss

    let stats = await cache.stats
    #expect(stats.hits == 2)
    #expect(stats.misses == 2)
    #expect(stats.hitRate == 0.5) // 2 hits / 4 total
}

@Test func ocrCacheClear() async {
    let cache = OCRCache()

    await cache.put(hash: 1, text: "Test", confidence: 0.9, wordCount: 1)
    var stats = await cache.stats
    #expect(stats.size == 1)

    await cache.clear()
    stats = await cache.stats
    #expect(stats.size == 0)
    #expect(stats.hits == 0)
    #expect(stats.misses == 0)
}
