import Foundation
import AVFoundation
import Shared

/// Captures microphone audio with voice activity detection.
public actor MicrophoneCaptureActor {
    private var audioEngine: AVAudioEngine?
    private var isCapturing = false
    private var audioBuffers: [AVAudioPCMBuffer] = []
    private var silenceFrames: Int = 0
    private let vadThreshold: Float
    private var onSpeechDetected: ((AVAudioPCMBuffer) -> Void)?

    public init(vadSensitivity: Double = 0.5) {
        // Convert sensitivity (0-1) to RMS threshold
        // Lower threshold = more sensitive
        self.vadThreshold = Float(0.001 + (vadSensitivity * 0.01))
    }

    /// Start capturing microphone audio.
    public func start(onSpeech: @escaping (AVAudioPCMBuffer) -> Void) async throws {
        guard !isCapturing else { return }

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)

        guard format.sampleRate > 0 else {
            SMLogger.system.error("Microphone: invalid audio format (no microphone available?)")
            throw AudioError.noMicrophone
        }

        self.onSpeechDetected = onSpeech

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            Task { await self.processBuffer(buffer) }
        }

        try engine.start()
        self.audioEngine = engine
        self.isCapturing = true
        SMLogger.system.info("Microphone capture started (format: \(format.sampleRate)Hz)")
    }

    /// Stop capturing.
    public func stop() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isCapturing = false
        audioBuffers.removeAll()
        SMLogger.system.info("Microphone capture stopped")
    }

    public var capturing: Bool { isCapturing }

    /// Record a fixed-duration clip (for voice memos).
    public func recordClip(duration: TimeInterval) async -> [AVAudioPCMBuffer] {
        audioBuffers.removeAll()
        let startTime = Date.now

        // Collect buffers for the specified duration
        while Date.now.timeIntervalSince(startTime) < duration && isCapturing {
            try? await Task.sleep(for: .milliseconds(100))
        }

        return audioBuffers
    }

    // MARK: - Private

    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        // Voice Activity Detection: check RMS energy
        guard containsSpeech(buffer) else {
            silenceFrames += 1
            return
        }

        silenceFrames = 0
        audioBuffers.append(buffer)

        // Keep rolling buffer bounded (last 30s worth of audio)
        let maxBuffers = Int(30.0 * 48000.0 / 4096.0) // ~30 seconds
        if audioBuffers.count > maxBuffers {
            audioBuffers.removeFirst()
        }

        onSpeechDetected?(buffer)
    }

    /// Simple energy-based Voice Activity Detection.
    private func containsSpeech(_ buffer: AVAudioPCMBuffer) -> Bool {
        guard let channelData = buffer.floatChannelData else { return false }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return false }

        var sumOfSquares: Float = 0
        for i in 0..<frameLength {
            let sample = channelData[0][i]
            sumOfSquares += sample * sample
        }

        let rms = sqrt(sumOfSquares / Float(frameLength))
        return rms > vadThreshold
    }
}

public enum AudioError: Error, LocalizedError {
    case noMicrophone
    case permissionDenied
    case engineStartFailed(String)
    case transcriptionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .noMicrophone: return "No microphone available"
        case .permissionDenied: return "Microphone permission denied"
        case .engineStartFailed(let msg): return "Audio engine failed: \(msg)"
        case .transcriptionFailed(let msg): return "Transcription failed: \(msg)"
        }
    }
}
