import Foundation
import Shared
import CaptureCore
import ChangeDetection
import OCRProcessing
import AIProcessing
import StorageCore
import SystemIntegration
import AudioCore
import SemanticSearch
import SwiftData

/// Orchestrates the full capture → detection → OCR → AI → storage pipeline.
public actor PipelineCoordinator {
    private var isRunning = false
    private var captureTask: Task<Void, Never>?
    private var lastNoteTimestamp: Date?
    private var lastNoteApp: String?
    private var lastNoteTitle: String?
    private var recentWordSets: [(hash: UInt64, words: Set<String>)] = []
    private var frameSkipCounter: UInt64 = 0

    private let captureConfig: CaptureConfiguration
    private let captureActor: ScreenCaptureActor
    private let activityMonitor: ActivityMonitorActor
    private let changeDetector: ChangeDetectionActor
    private let ocrProcessor: OCRProcessingActor
    private let aiProcessor: AIProcessingActor
    private let storageActor: StorageActor
    private let screenshotManager: ScreenshotFileManager
    private let powerMonitor = PowerStateMonitor()
    private let spotlightIndexer = SpotlightIndexer()
    private let errorBoundary = ErrorBoundary()
    private let auditLogger = AuditLogger()
    private let resourceMonitor = ResourceMonitor.shared
    private let ocrCache = OCRCache()
    private let meetingDetector = MeetingDetectionActor()
    private let semanticSearch = SemanticSearchActor()
    private let onNoteSaved: (@Sendable (String, String) -> Void)?

    public init(
        captureConfig: CaptureConfiguration = CaptureConfiguration(),
        aiProvider: any AIProvider,
        modelContainer: ModelContainer,
        onNoteSaved: (@Sendable (String, String) -> Void)? = nil
    ) {
        self.captureConfig = captureConfig
        self.onNoteSaved = onNoteSaved
        self.captureActor = ScreenCaptureActor(configuration: captureConfig)
        self.activityMonitor = ActivityMonitorActor()
        self.changeDetector = ChangeDetectionActor()
        self.ocrProcessor = OCRProcessingActor()
        self.aiProcessor = AIProcessingActor(provider: aiProvider)
        self.storageActor = StorageActor(modelContainer: modelContainer)
        self.screenshotManager = ScreenshotFileManager()
    }

    /// Start the full pipeline.
    public func start() async throws {
        // Allow restart after previous failure
        if isRunning {
            await captureActor.stop()
            isRunning = false
        }
        isRunning = true

        SMLogger.pipeline.info("Pipeline starting...")

        // Enforce screenshot quota on startup to handle cases where quota was
        // exceeded during previous sessions or short sessions that didn't hit the periodic check
        let deleted = screenshotManager.enforceQuota()
        if deleted > 0 {
            SMLogger.pipeline.info("Startup quota cleanup: deleted \(deleted) screenshots")
        }

        await resourceMonitor.resetSession()

        // Initialize semantic search
        try? await semanticSearch.setup()

        // Request calendar access for meeting detection (non-blocking)
        if UserDefaults.standard.object(forKey: "audioMeetingDetection") as? Bool ?? true {
            _ = await meetingDetector.requestAccess()
        }

        // Set up the frame stream BEFORE starting capture so no frames are lost
        let frameStream = await captureActor.frames()

        do {
            await activityMonitor.startMonitoring()
            try await captureActor.start()
        } catch {
            isRunning = false
            throw error
        }

        captureTask = Task { [weak self] in
            guard let self else { return }
            for await frame in frameStream {
                guard await self.isRunning else { break }
                await self.processFrame(frame)
            }
        }

        SMLogger.pipeline.info("Pipeline started — processing frames")
    }

    /// Stop the pipeline.
    public func stop() async {
        guard isRunning else { return }
        isRunning = false
        captureTask?.cancel()
        captureTask = nil
        await captureActor.stop()
        await activityMonitor.stopMonitoring()

        // Write daily summary on stop
        do {
            try await storageActor.writeDailySummary()
        } catch {
            SMLogger.pipeline.warning("Daily summary failed: \(error.localizedDescription)")
        }

        // Auto-prune old notes
        do {
            let pruned = try await storageActor.pruneOldNotes()
            if pruned > 0 {
                SMLogger.pipeline.info("Auto-pruned \(pruned) old notes on shutdown")
            }
        } catch {
            SMLogger.pipeline.warning("Auto-prune failed: \(error.localizedDescription)")
        }

        SMLogger.pipeline.info("Pipeline stopped")
    }

    /// Trigger a manual capture — bypasses cooldown and change detection.
    public func captureNow() async {
        guard isRunning else { return }
        guard let frame = await captureActor.captureNow() else {
            SMLogger.pipeline.warning("Manual capture: no frame returned")
            return
        }
        SMLogger.pipeline.info("Manual capture — processing frame from \(frame.appName, privacy: .public)")
        await processFrame(frame)
    }

    /// Pause/resume the pipeline.
    public func setPaused(_ paused: Bool) {
        isRunning = !paused
        SMLogger.pipeline.info("Pipeline \(paused ? "paused" : "resumed")")
    }

    /// Get pipeline stats.
    public func stats() async -> PipelineStats {
        let detectionStats = await changeDetector.stats
        let ocrStats = await ocrProcessor.stats
        let aiUsage = await aiProcessor.currentUsage
        return PipelineStats(
            totalFrames: detectionStats.total,
            filteredFrames: detectionStats.filtered,
            significantFrames: detectionStats.passed,
            ocrProcessed: ocrStats.processed,
            avgOCRTime: ocrStats.avgTime,
            aiRequests: aiUsage.requests,
            aiLimit: aiUsage.limit
        )
    }

    // MARK: - Private Pipeline

    private func processFrame(_ frame: CapturedFrame) async {
        await resourceMonitor.recordFrameCaptured()

        // Stage 0a: Battery check — reduce capture rate on low battery, but don't block entirely.
        // Users on low battery still expect SOME captures, just less frequently.
        if await powerMonitor.shouldPauseForBattery() {
            // On low battery: only process every 4th frame (effectively 20s intervals instead of 5s)
            if frameSkipCounter % 4 != 0 {
                frameSkipCounter += 1
                return
            }
            frameSkipCounter += 1
            SMLogger.pipeline.debug("Low battery — processing at reduced rate")
        }

        // Stage 0b: Excluded apps filter
        if let bundleID = frame.bundleIdentifier,
           captureConfig.excludedBundleIDs.contains(bundleID) {
            SMLogger.pipeline.debug("Skipping excluded app: \(bundleID, privacy: .public)")
            return
        }

        // Stage 1: Change Detection (manual captures bypass this)
        let significantFrame: SignificantFrame
        if frame.isManualCapture {
            // Manual captures always pass — user explicitly requested it
            significantFrame = SignificantFrame(frame: frame, hash: 0, differenceScore: 1.0)
        } else {
            guard let detected = await changeDetector.process(frame) else {
                await resourceMonitor.recordFrameFiltered()
                return // Filtered — no significant change
            }
            significantFrame = detected
        }

        // Stage 1b: Idle awareness.
        // When user is idle, we still process frames that passed change detection
        // (the screen actually changed). We only skip if change detection ALSO shows
        // the screen is static (significantFrame already filters for that).
        // This ensures idle captures work as intended by the "when idle" setting.

        SMLogger.pipeline.info("Frame passed detection — app=\(frame.appName, privacy: .public)")

        // Stage 2: Cooldown — don't generate notes too frequently (manual captures bypass cooldown)
        if !frame.isManualCapture, let lastNote = lastNoteTimestamp {
            let elapsed = Date.now.timeIntervalSince(lastNote)
            if elapsed < AppConstants.Pipeline.minNoteCooldownSeconds {
                SMLogger.pipeline.debug("Cooldown active — \(Int(AppConstants.Pipeline.minNoteCooldownSeconds - elapsed))s remaining")
                return
            }
        }

        // Stage 3: OCR (with cache)
        let recognizedText: RecognizedText

        // Check OCR cache first — avoid re-processing visually similar frames
        if let cached = await ocrCache.get(hash: significantFrame.hash) {
            recognizedText = RecognizedText(
                text: cached.text,
                averageConfidence: cached.confidence,
                wordCount: cached.wordCount,
                processingTime: 0,
                appName: frame.appName,
                windowTitle: frame.windowTitle,
                timestamp: frame.timestamp
            )
            SMLogger.pipeline.debug("OCR cache hit for hash \(significantFrame.hash)")
        } else {
            guard let ocrResult = await ocrProcessor.process(significantFrame) else {
                SMLogger.pipeline.info("OCR returned no text")
                return
            }
            recognizedText = ocrResult
            await resourceMonitor.recordOCRComplete(timeMs: ocrResult.processingTime * 1000)
            // Cache the result
            await ocrCache.put(hash: significantFrame.hash, text: ocrResult.text, confidence: ocrResult.averageConfidence, wordCount: ocrResult.wordCount)
        }

        let textPreview = String(recognizedText.text.prefix(80))
        SMLogger.pipeline.info("OCR: \(textPreview, privacy: .public)")

        // Stage 3b: Skip Rules — user-defined pattern-based skip logic (saves API costs)
        let skipResult = SkipRuleEngine.evaluate(
            text: recognizedText.text,
            appName: frame.appName,
            windowTitle: frame.windowTitle
        )
        if skipResult.shouldSkip {
            await resourceMonitor.recordNoteSkippedByRule()
            if let rule = skipResult.matchedRule {
                await auditLogger.log(action: .skipped, appName: frame.appName, reason: "Skip rule: \(rule.name)")
            }
            return
        }

        // Stage 3c: Content Redaction — remove sensitive data before AI processing
        let redactionResult = ContentRedactor.redact(recognizedText.text)
        if redactionResult.redactionCount > 0 {
            await resourceMonitor.recordRedaction(count: redactionResult.redactionCount)
        }
        let processedText: RecognizedText
        if redactionResult.redactionCount > 0 {
            processedText = RecognizedText(
                text: redactionResult.text,
                averageConfidence: recognizedText.averageConfidence,
                wordCount: recognizedText.wordCount,
                processingTime: recognizedText.processingTime,
                appName: recognizedText.appName,
                windowTitle: recognizedText.windowTitle,
                timestamp: recognizedText.timestamp
            )
            await auditLogger.log(
                action: .redacted,
                appName: frame.appName,
                reason: "Redacted \(redactionResult.redactionCount) fields: \(redactionResult.redactedTypes.joined(separator: ", "))"
            )
        } else {
            processedText = recognizedText
        }

        // Stage 4: Content dedup — skip if text is too similar to recent notes
        let sample = String(processedText.text.prefix(AppConstants.Pipeline.textSampleLength))
        let words = extractWords(sample)
        let hash = fnv1aHash(words)
        if isTextDuplicate(hash: hash, words: words) {
            SMLogger.pipeline.debug("Content dedup — skipping similar text")
            return
        }

        // Stage 5: Save screenshot (with optional encryption)
        var screenshotPath: String?
        do {
            var path = try screenshotManager.save(
                frame.image,
                hash: significantFrame.hash,
                timestamp: frame.timestamp
            )
            // Encrypt if enabled
            if ScreenshotEncryptor.isEnabled {
                path = try ScreenshotEncryptor.encryptFile(at: path)
                await auditLogger.log(action: .encrypted, appName: frame.appName, reason: "Screenshot encrypted")
            }
            screenshotPath = path
        } catch {
            let msg = String(describing: error)
            SMLogger.pipeline.error("Screenshot save failed: \(msg, privacy: .public)")
        }

        // Stage 6: AI Note Generation (with retry via ErrorBoundary)
        let generatedNote: GeneratedNote? = await errorBoundary.withRetry(
            stage: "ai-generation",
            strategy: .aiAPI,
            fallback: nil
        ) { [aiProcessor, lastNoteTitle = self.lastNoteTitle, lastNoteApp = self.lastNoteApp] in
            try await aiProcessor.generateNote(
                from: processedText,
                lastNoteTitle: lastNoteTitle,
                lastNoteApp: lastNoteApp
            )
        }

        guard let generatedNote else {
            await resourceMonitor.recordNoteSkippedByAI()
            SMLogger.pipeline.info("AI skipped frame or failed")
            return
        }

        SMLogger.pipeline.info("AI note: \(generatedNote.title, privacy: .public)")

        // Stage 7: Storage + Obsidian Export
        do {
            let savedNote = try await storageActor.saveNote(
                generatedNote,
                appName: frame.appName,
                windowTitle: frame.windowTitle,
                screenshotPath: screenshotPath,
                hash: significantFrame.hash,
                imageWidth: frame.image.width,
                imageHeight: frame.image.height,
                timestamp: frame.timestamp,
                redactionCount: redactionResult.redactionCount
            )
            SMLogger.pipeline.info("Note saved to storage + exporters")

            // Audit log
            await auditLogger.log(
                action: .captured,
                appName: frame.appName,
                reason: "Note: \(generatedNote.title)"
            )

            // Spotlight indexing
            await spotlightIndexer.indexNote(
                id: savedNote.id.uuidString,
                title: generatedNote.title,
                summary: generatedNote.summary,
                category: generatedNote.category.rawValue,
                appName: frame.appName,
                tags: generatedNote.tags,
                createdAt: frame.timestamp
            )

            // Notify user
            NotificationManager.shared.notifyNoteCreated(
                title: generatedNote.title,
                category: generatedNote.category.rawValue
            )

            // Record stats + learn tag patterns
            await resourceMonitor.recordNoteGenerated(aiTimeMs: 0)
            TagSuggester.recordTags(generatedNote.tags)

            // Index for semantic search
            let indexText = "\(generatedNote.title) \(generatedNote.summary) \(generatedNote.details)"
            try? await semanticSearch.indexNote(noteID: savedNote.id.uuidString, text: indexText)

            // Discover knowledge graph links
            let linkDiscovery = LinkDiscoveryActor(semanticSearch: semanticSearch)
            try? await linkDiscovery.setup()
            _ = try? await linkDiscovery.discoverLinks(noteID: savedNote.id.uuidString, text: indexText)

            // Enforce screenshot storage quota periodically (every 10 notes)
            let throughputStats = await resourceMonitor.currentThroughput()
            if throughputStats.notesGenerated % 10 == 0 {
                screenshotManager.enforceQuota()
            }

            // Update tracking state
            lastNoteTimestamp = Date.now
            lastNoteTitle = generatedNote.title
            lastNoteApp = frame.appName
            appendDedupEntry(hash: hash, words: words)

            onNoteSaved?(generatedNote.title, frame.appName)
        } catch {
            let msg = String(describing: error)
            SMLogger.pipeline.error("Pipeline error: \(msg, privacy: .public)")
        }
    }

    // MARK: - Content Deduplication

    /// Extract normalized word set from text for comparison.
    private func extractWords(_ text: String) -> Set<String> {
        Set(text.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init))
    }

    /// Deterministic FNV-1a hash — stable across process restarts (unlike Set.hashValue).
    private func fnv1aHash(_ words: Set<String>) -> UInt64 {
        var hash: UInt64 = 14695981039346656037 // FNV offset basis
        let sorted = words.sorted()
        for word in sorted {
            for byte in word.utf8 {
                hash ^= UInt64(byte)
                hash &*= 1099511628211 // FNV prime
            }
        }
        return hash
    }

    /// Jaccard similarity: |A ∩ B| / |A ∪ B|. Returns 0.0–1.0.
    private func jaccardSimilarity(_ a: Set<String>, _ b: Set<String>) -> Double {
        guard !a.isEmpty || !b.isEmpty else { return 1.0 }
        let intersection = a.intersection(b).count
        let union = a.union(b).count
        return Double(intersection) / Double(union)
    }

    /// Check if text is a duplicate — exact hash match OR fuzzy Jaccard similarity above threshold.
    private func isTextDuplicate(hash: UInt64, words: Set<String>) -> Bool {
        for entry in recentWordSets {
            // Fast path: exact hash match
            if entry.hash == hash { return true }
            // Slow path: fuzzy similarity check
            if jaccardSimilarity(words, entry.words) >= AppConstants.Pipeline.textSimilarityThreshold {
                return true
            }
        }
        return false
    }

    private func appendDedupEntry(hash: UInt64, words: Set<String>) {
        recentWordSets.append((hash: hash, words: words))
        if recentWordSets.count > AppConstants.Pipeline.recentTextBufferSize {
            recentWordSets.removeFirst()
        }
    }
}

/// Pipeline statistics snapshot.
public struct PipelineStats: Sendable {
    public let totalFrames: UInt64
    public let filteredFrames: UInt64
    public let significantFrames: UInt64
    public let ocrProcessed: UInt64
    public let avgOCRTime: TimeInterval
    public let aiRequests: Int
    public let aiLimit: Int
}
