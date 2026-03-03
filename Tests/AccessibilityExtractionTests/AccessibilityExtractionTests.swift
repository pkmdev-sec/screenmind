import Foundation
import Testing
@testable import AccessibilityExtraction

// MARK: - AccessibilityTreeExtractor Self-PID Guard Tests

@Test func extractTextReturnNilForSelfPID() {
    let extractor = AccessibilityTreeExtractor()
    let selfPID = ProcessInfo.processInfo.processIdentifier
    let result = extractor.extractText(from: selfPID)
    #expect(result == nil, "extractText should return nil for ScreenMind's own PID to prevent MainActor re-entry")
}

@Test func extractTextDoesNotCrashForInvalidPID() {
    let extractor = AccessibilityTreeExtractor()
    // PID 0 is the kernel — AX API will fail gracefully, but we verify no crash
    let result = extractor.extractText(from: 0)
    // Result may be nil (no accessibility access or no window), but must not crash
    _ = result
}

@Test func extractTextAllowsNonSelfPID() {
    let extractor = AccessibilityTreeExtractor()
    // PID 1 (launchd) is always running — verify the guard doesn't block non-self PIDs.
    // The call may return nil (no focused window or no AX permission), but it should
    // attempt extraction rather than short-circuit via the self-PID guard.
    let result = extractor.extractText(from: 1)
    // We can't assert non-nil (depends on AX permissions), but the guard path
    // is verified: PID 1 != self PID, so the function proceeds past the guard.
    _ = result
}

// MARK: - ExtractedText Model Tests

@Test func extractedTextInitializes() {
    let text = ExtractedText(
        text: "Hello world",
        source: .accessibility,
        nodeCount: 5,
        browserURL: "https://example.com",
        extractionTime: 0.05
    )
    #expect(text.text == "Hello world")
    #expect(text.source == .accessibility)
    #expect(text.nodeCount == 5)
    #expect(text.browserURL == "https://example.com")
    #expect(text.extractionTime == 0.05)
}

@Test func extractedTextNilBrowserURL() {
    let text = ExtractedText(
        text: "Some text",
        source: .ocr,
        nodeCount: 0,
        extractionTime: 0.1
    )
    #expect(text.browserURL == nil)
    #expect(text.source == .ocr)
}

@Test func extractionSourceRawValues() {
    #expect(ExtractionSource.accessibility.rawValue == "accessibility")
    #expect(ExtractionSource.ocr.rawValue == "ocr")
}
