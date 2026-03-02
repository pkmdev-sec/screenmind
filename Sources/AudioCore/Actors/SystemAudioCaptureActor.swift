import AVFoundation
import ScreenCaptureKit
import Shared

public actor SystemAudioCaptureActor {
    private var stream: SCStream?
    private var isCapturing = false
    private var continuation: AsyncStream<AVAudioPCMBuffer>.Continuation?

    public init() {}

    public func audioBuffers() -> AsyncStream<AVAudioPCMBuffer> {
        AsyncStream(bufferingPolicy: .bufferingNewest(10)) { cont in
            self.continuation = cont
        }
    }

    public func startCapture() async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        guard let display = content.displays.first else { throw SystemAudioError.noDisplay }
        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        let config = SCStreamConfiguration()
        config.capturesAudio = true
        config.excludesCurrentProcessAudio = true
        config.sampleRate = 16000
        config.channelCount = 1

        let handler = SystemAudioHandler { [weak self] buffer in
            Task { await self?.handleBuffer(buffer) }
        }
        let stream = SCStream(filter: filter, configuration: config, delegate: nil)
        try stream.addStreamOutput(handler, type: .audio, sampleHandlerQueue: .global(qos: .userInitiated))
        try await stream.startCapture()
        self.stream = stream
        isCapturing = true
        SMLogger.system.info("System audio capture started")
    }

    public func stopCapture() async {
        try? await stream?.stopCapture()
        stream = nil
        isCapturing = false
        continuation?.finish()
        SMLogger.system.info("System audio capture stopped")
    }

    private func handleBuffer(_ buffer: AVAudioPCMBuffer) {
        continuation?.yield(buffer)
    }

    public var capturing: Bool { isCapturing }
}

public enum SystemAudioError: Error, Sendable {
    case noDisplay
    case captureSetupFailed
}

// Bridge class for SCStreamOutput (must be class, not actor)
final class SystemAudioHandler: NSObject, SCStreamOutput, @unchecked Sendable {
    private let onBuffer: @Sendable (AVAudioPCMBuffer) -> Void

    init(onBuffer: @escaping @Sendable (AVAudioPCMBuffer) -> Void) {
        self.onBuffer = onBuffer
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }
        // Convert CMSampleBuffer to AVAudioPCMBuffer
        guard let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            SMLogger.system.warning("Audio buffer: no format description")
            return
        }
        let audioFormat = AVAudioFormat(cmAudioFormatDescription: formatDesc)
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            SMLogger.system.warning("Audio buffer: no data buffer")
            return
        }

        let numSamples = CMSampleBufferGetNumSamples(sampleBuffer)
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(numSamples)) else {
            SMLogger.system.warning("Audio buffer: failed to create PCM buffer")
            return
        }
        pcmBuffer.frameLength = AVAudioFrameCount(numSamples)

        var dataLength = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        let status = CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &dataLength, dataPointerOut: &dataPointer)

        guard status == kCMBlockBufferNoErr else {
            SMLogger.system.error("Audio buffer: CMBlockBufferGetDataPointer failed with status \(status)")
            return
        }

        if let data = dataPointer, let bufferData = pcmBuffer.audioBufferList.pointee.mBuffers.mData {
            memcpy(bufferData, data, min(dataLength, Int(pcmBuffer.audioBufferList.pointee.mBuffers.mDataByteSize)))
        } else {
            SMLogger.system.warning("Audio buffer: invalid data pointers")
            return
        }

        onBuffer(pcmBuffer)
    }
}
