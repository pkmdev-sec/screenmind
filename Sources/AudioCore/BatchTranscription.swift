import AVFoundation
import Shared

public actor BatchTranscriptionActor {
    private var audioFileURL: URL?
    private var audioFile: AVAudioFile?
    private var isBuffering = false
    private var bufferStart: Date?
    private let maxDuration: TimeInterval = 300

    public init() {}

    public func startBuffering() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("meeting_\(UUID().uuidString).wav")
        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
        audioFileURL = url; isBuffering = true; bufferStart = .now
    }

    public func addAudio(_ buffer: AVAudioPCMBuffer) throws {
        guard isBuffering, let file = audioFile else { return }
        try file.write(from: buffer)
    }

    /// Stop buffering and return the audio file URL.
    /// IMPORTANT: Caller is responsible for cleaning up the file using cleanup().
    public func stopBuffering() -> URL? {
        isBuffering = false; audioFile = nil; bufferStart = nil
        return audioFileURL
    }

    /// Clean up the temporary audio file.
    /// Call this after you're done with the file returned by stopBuffering().
    public func cleanup() {
        if let url = audioFileURL {
            try? FileManager.default.removeItem(at: url)
            SMLogger.system.debug("Cleaned up temp audio file: \(url.lastPathComponent)")
            audioFileURL = nil
        }
    }

    public var isCurrentlyBuffering: Bool { isBuffering }
    public var currentURL: URL? { audioFileURL }
}
