import Foundation

/// Compares perceptual hashes using Hamming distance.
public enum ImageDifferentiator {

    /// Normalized Hamming distance between two perceptual hashes.
    /// Returns 0.0 (identical) to 1.0 (completely different).
    public static func difference(hash1: UInt64, hash2: UInt64) -> Double {
        let xor = hash1 ^ hash2
        let setBits = xor.nonzeroBitCount // Swift's built-in popcount
        return Double(setBits) / 64.0
    }
}
