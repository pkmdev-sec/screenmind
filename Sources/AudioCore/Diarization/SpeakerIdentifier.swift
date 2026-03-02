import Foundation
import Shared

public actor SpeakerIdentifier {
    private var knownSpeakers: [String: [Float]] = [:]
    private let similarityThreshold: Float = 0.7
    private var nextIndex = 1

    public init() {}

    public func identifySpeaker(audioFeatures: [Float]) -> String {
        var best: (id: String, sim: Float) = ("", 0)
        for (id, emb) in knownSpeakers {
            let sim = cosineSimilarity(audioFeatures, emb)
            if sim > best.sim { best = (id, sim) }
        }
        if best.sim >= similarityThreshold { return best.id }
        let newID = "Speaker \(nextIndex)"; nextIndex += 1
        knownSpeakers[newID] = audioFeatures
        return newID
    }

    public func reset() { knownSpeakers.removeAll(); nextIndex = 1 }

    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot: Float = 0, na: Float = 0, nb: Float = 0
        for i in 0..<a.count { dot += a[i]*b[i]; na += a[i]*a[i]; nb += b[i]*b[i] }
        let d = sqrt(na) * sqrt(nb)
        return d > 0 ? dot / d : 0
    }
}
