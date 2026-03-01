import Testing
@testable import AIProcessing

@Test func noteCategoryValues() {
    #expect(NoteCategory.allCases.count == 7)
    #expect(NoteCategory.coding.rawValue == "coding")
}

@Test func generatedNoteInit() {
    let note = GeneratedNote(
        title: "Test",
        summary: "Test summary",
        details: "Details",
        category: .coding,
        tags: ["swift"],
        confidence: 0.9,
        skip: false,
        obsidianLinks: []
    )
    #expect(note.title == "Test")
    #expect(note.category == .coding)
}
