import Speech
import AVFoundation
import Shared

public actor MultiEngineSTT {
    public enum STTEngine: String, Sendable, CaseIterable, Codable {
        case appleSpeech
        case whisperAPI
    }

    private let primaryEngine: STTEngine
    private let appleSpeechRecognizer: SFSpeechRecognizer?
    private let whisperEndpoint: String?
    private let whisperAPIKey: String?

    public init(primary: STTEngine = .appleSpeech, whisperEndpoint: String? = nil, whisperAPIKey: String? = nil) {
        self.primaryEngine = primary
        self.appleSpeechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        self.whisperEndpoint = whisperEndpoint
        self.whisperAPIKey = whisperAPIKey
    }

    public func transcribe(_ audioURL: URL) async throws -> TranscriptionResult {
        if primaryEngine == .whisperAPI, let result = try? await whisperTranscribe(audioURL) {
            return result
        }
        return try await appleSpeechTranscribe(audioURL)
    }

    private func appleSpeechTranscribe(_ audioURL: URL) async throws -> TranscriptionResult {
        guard let recognizer = appleSpeechRecognizer, recognizer.isAvailable else {
            throw STTError.recognizerUnavailable
        }
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.requiresOnDeviceRecognition = true

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TranscriptionResult, Error>) in
                var hasResumed = false
                let task = recognizer.recognitionTask(with: request) { result, error in
                    guard !hasResumed else { return }
                    if let error {
                        hasResumed = true
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let result, result.isFinal else { return }
                    hasResumed = true
                    let text = result.bestTranscription.formattedString
                    let segments = result.bestTranscription.segments
                    let conf = segments.isEmpty ? 0.0 : segments.reduce(0.0) { $0 + Double($1.confidence) } / Double(segments.count)
                    continuation.resume(returning: TranscriptionResult(text: text, confidence: conf, engine: .appleSpeech, segments: []))
                }

                // Timeout after 60 seconds
                Task {
                    try? await Task.sleep(for: .seconds(60))
                    if !hasResumed {
                        hasResumed = true
                        task.cancel()
                        continuation.resume(throwing: STTError.transcriptionFailed("Timeout"))
                    }
                }
            }
        } onCancel: {
            // Recognition task will be cancelled when the withCheckedThrowingContinuation scope exits
        }
    }

    private func whisperTranscribe(_ audioURL: URL) async throws -> TranscriptionResult {
        guard let endpoint = whisperEndpoint else { throw STTError.notConfigured }
        let audioData = try Data(contentsOf: audioURL)
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "\(endpoint)/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let key = whisperAPIKey { request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization") }

        var body = Data()
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\nContent-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"model\"\r\n\r\nwhisper-1\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: request)
        let resp = try JSONDecoder().decode(WhisperAPIResponse.self, from: data)
        return TranscriptionResult(text: resp.text, confidence: 0.9, engine: .whisperAPI, segments: [])
    }
}

public struct TranscriptionResult: Sendable {
    public let text: String
    public let confidence: Double
    public let engine: MultiEngineSTT.STTEngine
    public let segments: [TranscriptionSegment]
}

public struct TranscriptionSegment: Sendable {
    public let text: String
    public let startTime: TimeInterval
    public let endTime: TimeInterval
    public let speaker: String?
}

public enum STTError: Error, Sendable {
    case recognizerUnavailable, notConfigured, transcriptionFailed(String)
}

private struct WhisperAPIResponse: Codable { let text: String }
