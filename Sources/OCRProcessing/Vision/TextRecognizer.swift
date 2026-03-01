import Foundation
import Vision
import CoreGraphics
import Shared

/// Extracts text from CGImages using the Vision framework.
public enum TextRecognizer {

    /// Recognize text in a CGImage. Returns array of (text, confidence) tuples.
    public static func recognizeText(in image: CGImage) async throws -> [(text: String, confidence: Float)] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let results = observations.compactMap { observation -> (String, Float)? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    return (candidate.string, candidate.confidence)
                }

                continuation.resume(returning: results)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.revision = VNRecognizeTextRequestRevision3

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
