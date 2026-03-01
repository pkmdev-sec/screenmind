import Testing
@testable import OCRProcessing

@Test func ocrActorInitializes() async {
    let actor = OCRProcessingActor()
    let stats = await actor.stats
    #expect(stats.processed == 0)
}

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
