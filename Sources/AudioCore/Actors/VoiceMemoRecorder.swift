import Foundation
import AVFoundation
import Shared

/// Records quick voice memos via keyboard shortcut, transcribes, and creates notes.
public actor VoiceMemoRecorder {
    private let micCapture: MicrophoneCaptureActor
    private let speechRecognizer: SpeechRecognitionActor
    private var isRecording = false
    private var currentBuffers: [AVAudioPCMBuffer] = []
    private let maxDuration: TimeInterval

    public init(language: String = "en-US", maxDuration: TimeInterval = 60) {
        self.micCapture = MicrophoneCaptureActor(vadSensitivity: 0.3) // Sensitive for voice memos
        self.speechRecognizer = SpeechRecognitionActor(language: language)
        self.maxDuration = maxDuration
    }

    /// Start recording a voice memo.
    public func startRecording() async throws {
        guard !isRecording else { return }
        isRecording = true
        currentBuffers.removeAll()

        try await micCapture.start { [weak self] buffer in
            guard let self else { return }
            Task { await self.appendBuffer(buffer) }
        }

        SMLogger.system.info("Voice memo recording started")

        // Auto-stop after maxDuration
        Task {
            try? await Task.sleep(for: .seconds(maxDuration))
            if await self.isRecording {
                _ = await self.stopRecording()
            }
        }
    }

    /// Stop recording and transcribe.
    public func stopRecording() async -> VoiceMemo? {
        guard isRecording else { return nil }
        isRecording = false

        let buffers = currentBuffers
        await micCapture.stop()

        guard !buffers.isEmpty else {
            SMLogger.system.warning("Voice memo: no audio captured")
            return nil
        }

        // Transcribe
        guard let transcript = await speechRecognizer.transcribe(buffers) else {
            SMLogger.system.warning("Voice memo: transcription failed")
            return VoiceMemo(text: "[Transcription failed]", duration: 0)
        }

        let memo = VoiceMemo(
            text: transcript.text,
            duration: transcript.duration
        )

        SMLogger.system.info("Voice memo completed: \(transcript.text.prefix(50))...")
        return memo
    }

    public var recording: Bool { isRecording }

    private func appendBuffer(_ buffer: AVAudioPCMBuffer) {
        currentBuffers.append(buffer)
    }
}
