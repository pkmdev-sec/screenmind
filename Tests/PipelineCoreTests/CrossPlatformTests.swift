import Foundation
import Testing
@testable import PipelineCore

// MARK: - Cross-Platform Protocol Tests

@Test func capturedFrameDataInit() {
    let frameData = CapturedFrameData(
        imageData: Data(),
        width: 1920,
        height: 1080,
        timestamp: Date(),
        appName: "Safari",
        windowTitle: "Apple",
        bundleID: "com.apple.Safari"
    )

    #expect(frameData.width == 1920)
    #expect(frameData.height == 1080)
    #expect(frameData.appName == "Safari")
    #expect(frameData.bundleID == "com.apple.Safari")
}

@Test func ocrResultInit() {
    let element = OCRTextElement(
        text: "Hello",
        bounds: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.1),
        confidence: 0.95
    )

    let result = OCRResult(
        fullText: "Hello World",
        elements: [element],
        confidence: 0.90,
        processingTimeMs: 150
    )

    #expect(result.fullText == "Hello World")
    #expect(result.elements.count == 1)
    #expect(result.confidence == 0.90)
    #expect(result.processingTimeMs == 150)
}

@Test func aiGeneratedNoteInit() {
    let note = AIGeneratedNote(
        title: "Test Note",
        summary: "This is a test",
        details: "Full details here",
        category: "coding",
        tags: ["swift", "testing"],
        confidence: 0.85,
        shouldSkip: false
    )

    #expect(note.title == "Test Note")
    #expect(note.category == "coding")
    #expect(note.tags.count == 2)
    #expect(note.shouldSkip == false)
}

@Test func storedNoteInit() {
    let note = StoredNote(
        id: "test-id",
        title: "Stored Note",
        summary: "Summary",
        details: "Details",
        category: "research",
        tags: ["ai"],
        confidence: 0.92,
        appName: "Safari",
        windowTitle: "Wikipedia",
        createdAt: Date(),
        hasScreenshot: true
    )

    #expect(note.id == "test-id")
    #expect(note.appName == "Safari")
    #expect(note.hasScreenshot == true)
}

@Test func storageStatsInit() {
    let stats = StorageStats(
        totalNotes: 100,
        totalScreenshots: 80,
        diskUsageBytes: 1_000_000,
        quotaBytes: 1_073_741_824
    )

    #expect(stats.totalNotes == 100)
    #expect(stats.totalScreenshots == 80)
    #expect(stats.diskUsageBytes == 1_000_000)
}

@Test func exportFormatCaseIterable() {
    let formats = ExportFormat.allCases
    #expect(formats.contains(.markdown))
    #expect(formats.contains(.json))
    #expect(formats.contains(.obsidian))
    #expect(formats.contains(.notion))
}

// MARK: - Platform Adapter Tests

@Test func createPlatformAdapterReturnsMacOS() async {
    let adapter = createPlatformAdapter()
    #expect(adapter.platformName == "macOS")
    #expect(adapter.supportsScreenCapture == true)
    #expect(adapter.supportsNativeOCR == true)
}

@Test func macOSAdapterProperties() async {
    let adapter = MacOSAdapter()
    let platformName = await adapter.platformName
    let supportsCapture = await adapter.supportsScreenCapture
    let supportsOCR = await adapter.supportsNativeOCR

    #expect(platformName == "macOS")
    #expect(supportsCapture == true)
    #expect(supportsOCR == true)
}

@Test func windowsAdapterThrowsNotImplemented() async {
    let adapter = WindowsAdapter()
    let platformName = await adapter.platformName
    #expect(platformName == "Windows")

    await #expect(throws: PlatformError.self) {
        try await adapter.initialize()
    }
}

@Test func linuxAdapterThrowsNotImplemented() async {
    let adapter = LinuxAdapter()
    let platformName = await adapter.platformName
    #expect(platformName == "Linux")

    await #expect(throws: PlatformError.self) {
        try await adapter.initialize()
    }
}

// MARK: - UserDefaults Tests

@Test func crossPlatformModeUserDefaults() {
    UserDefaults.standard.crossPlatformMode = true
    #expect(UserDefaults.standard.crossPlatformMode == true)

    UserDefaults.standard.crossPlatformMode = false
    #expect(UserDefaults.standard.crossPlatformMode == false)
}
