import Foundation
import Speech
import AVFoundation
import Shared

/// On-device speech-to-text using Apple Speech framework.
public actor SpeechRecognitionActor {
    private let recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?

    public init(language: String = "en-US") {
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: language))
    }

    /// Request speech recognition authorization.
    public static func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    /// Transcribe an array of audio buffers into text.
    public func transcribe(_ buffers: [AVAudioPCMBuffer]) async -> AudioTranscript? {
        guard let recognizer, recognizer.isAvailable else {
            SMLogger.system.warning("Speech recognizer not available")
            return nil
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = true // Privacy: on-device only

        for buffer in buffers {
            request.append(buffer)
        }
        request.endAudio()

        let startTime = Date.now

        return await withCheckedContinuation { continuation in
            recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    SMLogger.system.warning("Speech recognition error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let result, result.isFinal else { return }

                let text = result.bestTranscription.formattedString
                guard !text.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let duration = Date.now.timeIntervalSince(startTime)
                let confidence = result.bestTranscription.segments.reduce(0.0) { sum, seg in
                    sum + Double(seg.confidence)
                } / max(Double(result.bestTranscription.segments.count), 1)

                let transcript = AudioTranscript(
                    text: text,
                    startTime: startTime,
                    duration: duration,
                    confidence: confidence,
                    language: recognizer.locale.identifier
                )

                SMLogger.system.info("Transcribed \(text.count) chars (confidence: \(String(format: "%.2f", confidence)))")
                continuation.resume(returning: transcript)
            }
        }
    }

    /// Check if on-device recognition is supported.
    public var isAvailable: Bool {
        recognizer?.isAvailable == true && recognizer?.supportsOnDeviceRecognition == true
    }
}
