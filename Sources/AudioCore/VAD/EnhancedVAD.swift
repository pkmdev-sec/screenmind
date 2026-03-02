import Foundation
import AVFoundation
import Shared

public actor EnhancedVAD {
    private let energyThreshold: Float
    private var recentResults: [Bool] = []

    public init(sensitivity: Double = 0.5) {
        self.energyThreshold = Float(0.001 + (sensitivity * 0.01))
    }

    public func detectSpeech(in buffer: AVAudioPCMBuffer) -> VADResult {
        guard let channelData = buffer.floatChannelData else {
            return VADResult(isSpeech: false, confidence: 0, energy: 0)
        }
        let count = Int(buffer.frameLength)
        var energy: Float = 0
        var zeroCrossings: Int = 0
        for i in 0..<count {
            let s = channelData[0][i]
            energy += s * s
            if i > 0 && (channelData[0][i] > 0) != (channelData[0][i-1] > 0) { zeroCrossings += 1 }
        }
        let rms = sqrt(energy / Float(count))
        let zcr = Float(zeroCrossings) / Float(count)
        let raw = rms > energyThreshold && zcr < 0.5
        let confidence = min(rms / (energyThreshold * 10), 1.0)

        recentResults.append(raw)
        if recentResults.count > 5 { recentResults.removeFirst() }
        let smoothed = recentResults.filter { $0 }.count >= 3

        return VADResult(isSpeech: smoothed, confidence: confidence, energy: rms)
    }
}

public struct VADResult: Sendable {
    public let isSpeech: Bool
    public let confidence: Float
    public let energy: Float
}
