import Foundation
import Shared
import ChangeDetection
import CaptureCore

/// Manages concurrent OCR processing with backpressure and ordering.
public actor OCRQueueActor {
    private var queue: [SignificantFrame] = []
    private var processingTask: Task<Void, Never>?
    private var sequenceNumber: UInt64 = 0
    private var results: [UInt64: RecognizedText] = [:]
    private let maxQueueSize = 5
    private let cpuThresholdPercent = 30.0

    /// Maximum concurrent OCR operations (configurable via UserDefaults).
    private var maxConcurrency: Int {
        let value = UserDefaults.standard.integer(forKey: "ocrMaxConcurrency")
        return value > 0 ? value : 3
    }

    public init() {}

    /// Start processing queued frames.
    public func start() async {
        guard processingTask == nil else { return }
        processingTask = Task { [weak self] in
            guard let self else { return }
            await self.processLoop()
        }
    }

    /// Stop processing and clear queue.
    public func stop() async {
        processingTask?.cancel()
        processingTask = nil
        queue.removeAll()
        results.removeAll()
    }

    /// Enqueue a frame for OCR processing. Returns sequence number.
    /// Drops oldest frame if queue is full (backpressure).
    public func enqueue(_ frame: SignificantFrame) async -> UInt64 {
        // Backpressure: drop oldest if queue is full
        if queue.count >= maxQueueSize {
            queue.removeFirst()
            SMLogger.ocr.warning("OCR queue full — dropped oldest frame")
        }

        queue.append(frame)
        let seq = sequenceNumber
        sequenceNumber += 1
        return seq
    }

    /// Get processed result for a sequence number (ordered delivery).
    public func getResult(seq: UInt64) async -> RecognizedText? {
        results.removeValue(forKey: seq)
    }

    /// Current queue depth.
    public var queueDepth: Int {
        queue.count
    }

    // MARK: - Private Processing Loop

    private func processLoop() async {
        while !Task.isCancelled {
            // CPU usage check — pause if CPU is too high
            // TODO: Integrate with ResourceMonitor when available (avoids circular dependency)
            let cpuUsage = getCPUUsage()
            if cpuUsage > self.cpuThresholdPercent {
                SMLogger.ocr.debug("OCR paused — CPU usage \(String(format: "%.1f", cpuUsage))% > \(self.cpuThresholdPercent)%")
                try? await Task.sleep(nanoseconds: 500_000_000) // 500ms pause
                continue
            }

            // Collect batch of frames to process
            let batchSize = min(maxConcurrency, queue.count)
            guard batchSize > 0 else {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                continue
            }

            let batch = Array(queue.prefix(batchSize))
            queue.removeFirst(batchSize)

            // Process batch in parallel using TaskGroup
            await withTaskGroup(of: (Int, RecognizedText?).self) { group in
                for (index, frame) in batch.enumerated() {
                    group.addTask {
                        let result = await self.processFrame(frame)
                        return (index, result)
                    }
                }

                // Collect results (preserves order via index)
                var batchResults: [(Int, RecognizedText?)] = []
                for await result in group {
                    batchResults.append(result)
                }

                // Store results in sequence order
                batchResults.sort { $0.0 < $1.0 }
                for (_, text) in batchResults {
                    if let text {
                        let seq = await self.getNextSequence()
                        results[seq] = text
                    }
                }
            }
        }
    }

    private func processFrame(_ frame: SignificantFrame) async -> RecognizedText? {
        let start = CFAbsoluteTimeGetCurrent()

        do {
            let rawResults = try await TextRecognizer.recognizeText(in: frame.frame.image)

            guard !rawResults.isEmpty else {
                SMLogger.ocr.debug("No text found in frame")
                return nil
            }

            let (cleanText, avgConfidence, wordCount) = TextPreprocessor.clean(rawResults)

            guard wordCount >= 3 else {
                SMLogger.ocr.debug("Too few words (\(wordCount)), skipping frame")
                return nil
            }

            let elapsed = CFAbsoluteTimeGetCurrent() - start
            let truncatedText = TextPreprocessor.truncate(cleanText)

            SMLogger.ocr.debug("OCR: \(wordCount) words, confidence: \(String(format: "%.2f", avgConfidence)), time: \(String(format: "%.1f", elapsed * 1000))ms")

            return RecognizedText(
                text: truncatedText,
                averageConfidence: avgConfidence,
                wordCount: wordCount,
                processingTime: elapsed,
                appName: frame.frame.appName,
                windowTitle: frame.frame.windowTitle,
                timestamp: frame.frame.timestamp
            )
        } catch {
            SMLogger.ocr.error("OCR failed: \(error.localizedDescription)")
            return nil
        }
    }

    private var nextSeq: UInt64 = 0
    private func getNextSequence() async -> UInt64 {
        let seq = nextSeq
        nextSeq += 1
        return seq
    }

    /// Get current CPU usage percentage (simplified version to avoid circular dependency).
    private func getCPUUsage() -> Double {
        var taskInfo = task_basic_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_basic_info_data_t>.size / MemoryLayout<natural_t>.size)

        let result = withUnsafeMutablePointer(to: &taskInfo) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }

        let userTime = Double(taskInfo.user_time.seconds) + Double(taskInfo.user_time.microseconds) / 1_000_000
        let systemTime = Double(taskInfo.system_time.seconds) + Double(taskInfo.system_time.microseconds) / 1_000_000
        return (userTime + systemTime) * 100 // Rough approximation
    }
}
