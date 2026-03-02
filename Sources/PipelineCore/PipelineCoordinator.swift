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
import PluginSystem
import SwiftData

/// Orchestrates the full capture → detection → OCR → AI → storage pipeline.
public actor PipelineCoordinator {
    private var isRunning = false
    private var captureTask: Task<Void, Never>?
    private var lastNoteTimestamp: Date?
    private var lastNoteApp: String?
    private var lastNoteTitle: String?
    private var recentWordSets: [(hash: UInt64, words: Set<String>)] = []
    private var recentContentKeys: [(key: String, timestamp: Date)] = []
    private var frameSkipCounter: UInt64 = 0
    private var contextWindow: [(title: String, summary: String, timestamp: Date)] = []
    private var activeMeeting: DetectedMeeting?
    private var meetingNoteIDs: [UUID] = []
    private var eventMonitor: EventMonitorActor?
    private let screenLockMonitor = ScreenLockMonitor()
    private var powerProfileTask: Task<Void, Never>?

    private let captureConfig: CaptureConfiguration
    private let captureActor: ScreenCaptureActor
    private let activityMonitor: ActivityMonitorActor
    private let changeDetector: ChangeDetectionActor
    private let ocrProcessor: OCRProcessingActor
    private let aiProcessor: AIProcessingActor
    private let storageActor: StorageActor
    private let screenshotManager: ScreenshotFileManager
    private let powerMonitor = PowerStateMonitor()
    private let powerProfileManager = PowerProfileManager()
    private let spotlightIndexer = SpotlightIndexer()
    private let errorBoundary = ErrorBoundary()
    private let auditLogger = AuditLogger()
    private let resourceMonitor = ResourceMonitor.shared
    private let ocrCache = OCRCache()
    private let meetingDetector = MeetingDetectionActor()
    private let semanticSearch = SemanticSearchActor()
    private let meetingSummarizer: MeetingSummarizer
    private let onNoteSaved: (@Sendable (String, String) -> Void)?

    // Audio actors
    private var micCapture: MicrophoneCaptureActor?
    private var systemAudioCapture: SystemAudioCaptureActor?
    private var speechRecognizer: SpeechRecognitionActor?

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
        self.meetingSummarizer = MeetingSummarizer(
            storageActor: storageActor,
            aiProcessor: aiProcessor,
            meetingDetector: meetingDetector
        )
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

        // Load plugins
        await PluginEngine.shared.loadAllPlugins()
        await PluginEngine.shared.trigger(event: .appStartup, data: [:])

        // Request calendar access for meeting detection (non-blocking)
        if UserDefaults.standard.object(forKey: "audioMeetingDetection") as? Bool ?? true {
            _ = await meetingDetector.requestAccess()
        }

        // Initialize audio capture based on settings
        try? await initializeAudio()

        // Start power profile management
        await powerProfileManager.start()
        startPowerProfileMonitoring()

        do {
            await activityMonitor.startMonitoring()

            // Choose between event-driven or timer-based capture
            if captureConfig.eventDrivenEnabled {
                // Event-driven mode: monitor OS events and capture on demand
                SMLogger.pipeline.info("Starting event-driven capture mode")
                await screenLockMonitor.startMonitoring()
                let monitor = EventMonitorActor(configuration: captureConfig)
                self.eventMonitor = monitor
                let events = await monitor.events()

                captureTask = Task { [weak self] in
                    guard let self else { return }
                    for await _ in events {
                        guard await self.isRunning else { break }
                        // Skip captures when screen is locked
                        if await self.screenLockMonitor.isScreenLocked() {
                            continue
                        }
                        // Capture frame on event
                        if let frame = await self.captureActor.captureNow() {
                            await self.processFrame(frame)
                        }
                    }
                }
            } else {
                // Timer-based mode: traditional streaming capture
                SMLogger.pipeline.info("Starting timer-based capture mode")
                let frameStream = await captureActor.frames()
                try await captureActor.start()

                captureTask = Task { [weak self] in
                    guard let self else { return }
                    for await frame in frameStream {
                        guard await self.isRunning else { break }
                        await self.processFrame(frame)
                    }
                }
            }
        } catch {
            isRunning = false
            throw error
        }

        SMLogger.pipeline.info("Pipeline started — processing frames")
    }

    /// Stop the pipeline.
    public func stop() async {
        guard isRunning else { return }
        isRunning = false

        // Nil out eventMonitor before cancelling task to ensure stream termination
        if eventMonitor != nil {
            eventMonitor = nil
            // Allow the stream to finish naturally before cancelling the task
            try? await Task.sleep(for: .milliseconds(100))
        }

        captureTask?.cancel()
        captureTask = nil
        powerProfileTask?.cancel()
        powerProfileTask = nil
        await captureActor.stop()
        await activityMonitor.stopMonitoring()
        await screenLockMonitor.stopMonitoring()
        await powerProfileManager.stop()
        await stopAudio()

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

        // Stage 0: Excluded apps filter
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

        // Stage 4b: 30-second content dedup floor — skip if same app+window+text seen recently
        let contentKey = makeContentKey(bundleID: frame.bundleIdentifier, windowTitle: frame.windowTitle, textHash: hash)
        if isRecentDuplicate(contentKey: contentKey) {
            SMLogger.pipeline.debug("30s dedup — same app+window+text seen recently")
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
        let contextWindowSize = UserDefaults.standard.integer(forKey: "aiContextWindowSize").clamped(to: 0...10, default: 3)
        let currentContext = contextWindow.suffix(contextWindowSize).map { $0 }

        let generatedNote: GeneratedNote? = await errorBoundary.withRetry(
            stage: "ai-generation",
            strategy: .aiAPI,
            fallback: nil
        ) { [aiProcessor, lastNoteTitle = self.lastNoteTitle, lastNoteApp = self.lastNoteApp] in
            try await aiProcessor.generateNote(
                from: processedText,
                lastNoteTitle: lastNoteTitle,
                lastNoteApp: lastNoteApp,
                bundleID: frame.bundleIdentifier,
                imageData: nil, // TODO: pass image data when vision is enabled
                contextWindow: currentContext
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

            // Trigger plugin hooks
            await PluginEngine.shared.trigger(event: .noteCreated, data: [
                "id": savedNote.id.uuidString,
                "title": generatedNote.title,
                "summary": generatedNote.summary,
                "category": generatedNote.category.rawValue,
                "tags": generatedNote.tags,
                "app": frame.appName
            ])

            // Trigger workflow automations
            await WorkflowEngine.shared.evaluate(event: WorkflowEvent(
                title: generatedNote.title,
                summary: generatedNote.summary,
                category: generatedNote.category.rawValue,
                appName: frame.appName,
                tags: generatedNote.tags,
                confidence: generatedNote.confidence
            ))

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
            recordContentKey(contentKey)

            // Update context window
            contextWindow.append((title: generatedNote.title, summary: generatedNote.summary, timestamp: Date.now))
            let maxContextSize = UserDefaults.standard.integer(forKey: "aiContextWindowSize").clamped(to: 0...10, default: 3)
            if contextWindow.count > maxContextSize {
                contextWindow.removeFirst()
            }

            // Meeting detection and tracking
            if UserDefaults.standard.bool(forKey: "audioMeetingDetection") {
                await checkMeetingStatus(noteID: savedNote.id)
            }

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

    /// Create a unique content key from bundleID + windowTitle + textHash.
    private func makeContentKey(bundleID: String?, windowTitle: String?, textHash: UInt64) -> String {
        let bundle = bundleID ?? "unknown"
        let window = windowTitle ?? "untitled"
        return "\(bundle)|\(window)|\(textHash)"
    }

    /// Check if the same content key was seen within the last 30 seconds.
    private func isRecentDuplicate(contentKey: String) -> Bool {
        let now = Date.now
        let cooldownSeconds: TimeInterval = 30

        // Clean up expired entries
        recentContentKeys.removeAll { now.timeIntervalSince($0.timestamp) > cooldownSeconds }

        // Check for duplicate
        return recentContentKeys.contains { $0.key == contentKey }
    }

    /// Record a content key for 30-second dedup tracking.
    private func recordContentKey(_ contentKey: String) {
        recentContentKeys.append((key: contentKey, timestamp: Date.now))
        // Limit buffer size to prevent unbounded growth
        if recentContentKeys.count > 100 {
            recentContentKeys.removeFirst()
        }
    }

    // MARK: - Power Profile Management

    /// Monitor power state and adjust capture parameters adaptively.
    private func startPowerProfileMonitoring() {
        powerProfileTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                // Update profile every 30 seconds
                try? await Task.sleep(for: .seconds(30))
                let profile = await self.powerProfileManager.updateAndGetConfiguration()
                // Update change detection threshold
                await self.changeDetector.updateThreshold(profile.visualChangeThreshold)
                // Log mode changes
                let mode = await self.powerProfileManager.currentPowerMode()
                SMLogger.pipeline.debug("Power profile: \(mode.rawValue)")
            }
        }
    }

    // MARK: - Audio Initialization

    /// Initialize audio capture actors based on user settings.
    private func initializeAudio() async throws {
        let micEnabled = UserDefaults.standard.bool(forKey: "audioMicrophoneEnabled")
        let systemEnabled = UserDefaults.standard.bool(forKey: "audioSystemEnabled")
        let language = UserDefaults.standard.string(forKey: "audioLanguage") ?? "en-US"
        let vadSensitivity = UserDefaults.standard.double(forKey: "audioVADSensitivity")
        let vadValue = vadSensitivity > 0 ? vadSensitivity : 0.5

        // Initialize microphone capture
        if micEnabled {
            SMLogger.pipeline.info("Starting microphone capture with VAD sensitivity \(vadValue)")
            let mic = MicrophoneCaptureActor(vadSensitivity: vadValue)
            self.micCapture = mic
            let recognizer = SpeechRecognitionActor(language: language)
            self.speechRecognizer = recognizer

            // Start capturing with speech recognition callback
            try await mic.start { buffer in
                // Handle speech detection if needed
                // For now, just log that we got audio
                Task {
                    SMLogger.pipeline.debug("Microphone: speech detected")
                }
            }
        }

        // Initialize system audio capture
        if systemEnabled {
            SMLogger.pipeline.info("Starting system audio capture")
            let sysAudio = SystemAudioCaptureActor()
            self.systemAudioCapture = sysAudio
            try await sysAudio.startCapture()
        }

        if micEnabled || systemEnabled {
            SMLogger.pipeline.info("Audio capture initialized (mic: \(micEnabled), system: \(systemEnabled))")
        }
    }

    /// Stop all audio capture.
    private func stopAudio() async {
        if let mic = micCapture {
            await mic.stop()
            micCapture = nil
        }
        if let sysAudio = systemAudioCapture {
            await sysAudio.stopCapture()
            systemAudioCapture = nil
        }
        speechRecognizer = nil
    }

    // MARK: - Meeting Detection

    /// Check if we're in a meeting and track notes for summarization.
    private func checkMeetingStatus(noteID: UUID) async {
        let currentMeeting = await meetingDetector.detectCurrentMeeting()

        // Meeting started
        if let meeting = currentMeeting, activeMeeting == nil {
            activeMeeting = meeting
            meetingNoteIDs = [noteID]
            SMLogger.pipeline.info("Meeting started: \(meeting.title)")
        }
        // Meeting ongoing - track note
        else if currentMeeting != nil, activeMeeting != nil {
            meetingNoteIDs.append(noteID)
        }
        // Meeting ended
        else if currentMeeting == nil, let meeting = activeMeeting {
            SMLogger.pipeline.info("Meeting ended: \(meeting.title), generating summary...")

            // Fetch all notes from this meeting
            do {
                let notes = try await storageActor.fetchNotes(ids: meetingNoteIDs)
                try await meetingSummarizer.summarizeMeeting(meeting, notes: notes)
            } catch {
                SMLogger.pipeline.error("Meeting summary failed: \(error.localizedDescription)")
            }

            // Reset state
            activeMeeting = nil
            meetingNoteIDs = []
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

// MARK: - Int clamping helper

private extension Int {
    func clamped(to range: ClosedRange<Int>, default defaultValue: Int) -> Int {
        let value = self == 0 ? defaultValue : self
        return Swift.min(Swift.max(value, range.lowerBound), range.upperBound)
    }
}
