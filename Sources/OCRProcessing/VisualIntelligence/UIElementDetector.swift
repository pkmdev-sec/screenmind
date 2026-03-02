import Foundation
import CoreGraphics
import Vision
import Shared

/// Detects UI elements in screenshots using Apple Vision and heuristic classification.
public struct UIElementDetector: Sendable {

    /// Type of UI element detected.
    public enum ElementType: String, Sendable, Codable {
        case button
        case textField
        case dialog
        case window
        case menu
        case icon
        case unknown
    }

    /// A detected UI element with type, bounds, and associated text.
    public struct UIElement: Sendable {
        public let type: ElementType
        public let bounds: CGRect
        public let text: String?
        public let confidence: Double

        public init(type: ElementType, bounds: CGRect, text: String? = nil, confidence: Double) {
            self.type = type
            self.bounds = bounds
            self.text = text
            self.confidence = confidence
        }
    }

    /// Configuration for UI element detection.
    public struct Configuration: Sendable {
        public let minimumConfidence: Float
        public let minimumSize: Int
        public let maximumSize: Int

        public init(
            minimumConfidence: Float = 0.5,
            minimumSize: Int = 10,
            maximumSize: Int = 1000
        ) {
            self.minimumConfidence = minimumConfidence
            self.minimumSize = minimumSize
            self.maximumSize = maximumSize
        }
    }

    private let config: Configuration

    public init(config: Configuration = Configuration()) {
        self.config = config
    }

    /// Detect UI elements in a screenshot.
    /// Returns an array of UIElement with type classifications based on heuristics.
    public func detect(in image: CGImage, ocrText: String? = nil) async throws -> [UIElement] {
        // Use Vision to detect rectangles
        let request = VNDetectRectanglesRequest()
        request.minimumConfidence = config.minimumConfidence
        request.minimumAspectRatio = 0.1
        request.maximumAspectRatio = 10.0
        request.minimumSize = Float(config.minimumSize) / Float(max(image.width, image.height))
        request.maximumObservations = 100

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])

        guard let observations = request.results as? [VNRectangleObservation] else {
            return []
        }

        // Convert observations to UIElements with heuristic classification
        let imageSize = CGSize(width: image.width, height: image.height)
        var elements: [UIElement] = []

        for observation in observations {
            let bounds = VNImageRectForNormalizedRect(
                observation.boundingBox,
                image.width,
                image.height
            )

            // Filter by size
            let area = bounds.width * bounds.height
            if area < Double(config.minimumSize * config.minimumSize) ||
               area > Double(config.maximumSize * config.maximumSize) {
                continue
            }

            // Classify element type based on heuristics
            let elementType = classifyElement(
                bounds: bounds,
                imageSize: imageSize,
                aspectRatio: observation.boundingBox.width / observation.boundingBox.height
            )

            // Try to extract nearby text from OCR (if provided)
            let nearbyText = extractNearbyText(
                bounds: bounds,
                ocrText: ocrText
            )

            let element = UIElement(
                type: elementType,
                bounds: bounds,
                text: nearbyText,
                confidence: Double(observation.confidence)
            )
            elements.append(element)
        }

        SMLogger.ocr.debug("Detected \(elements.count) UI elements")
        return elements
    }

    // MARK: - Heuristic Classification

    /// Classify UI element type based on size, aspect ratio, and position.
    private func classifyElement(
        bounds: CGRect,
        imageSize: CGSize,
        aspectRatio: Double
    ) -> ElementType {
        let width = bounds.width
        let height = bounds.height
        let area = width * height
        let imageArea = imageSize.width * imageSize.height
        let areaRatio = area / imageArea

        // Dialog: Large, roughly square, centered
        if areaRatio > 0.15 && areaRatio < 0.5 && aspectRatio > 0.6 && aspectRatio < 1.5 {
            let centerX = bounds.midX
            let centerY = bounds.midY
            let imageCenterX = imageSize.width / 2
            let imageCenterY = imageSize.height / 2
            let distFromCenter = sqrt(
                pow(centerX - imageCenterX, 2) + pow(centerY - imageCenterY, 2)
            )
            if distFromCenter < imageSize.width * 0.2 {
                return .dialog
            }
        }

        // Window: Very large, any aspect ratio
        if areaRatio > 0.5 {
            return .window
        }

        // Button: Small to medium, wider than tall
        if areaRatio < 0.05 && aspectRatio > 1.5 && aspectRatio < 10.0 {
            return .button
        }

        // Text field: Small to medium, very wide (high aspect ratio)
        if areaRatio < 0.05 && aspectRatio > 3.0 {
            return .textField
        }

        // Icon: Small, roughly square
        if areaRatio < 0.01 && aspectRatio > 0.8 && aspectRatio < 1.2 {
            if width < 100 && height < 100 {
                return .icon
            }
        }

        // Menu: Medium width, tall (vertical list)
        if areaRatio < 0.15 && aspectRatio < 0.5 {
            return .menu
        }

        return .unknown
    }

    /// Extract text from OCR that is spatially near the UI element bounds.
    /// This is a simplified implementation - in production, you'd parse OCR results with positions.
    private func extractNearbyText(bounds: CGRect, ocrText: String?) -> String? {
        // Simplified: just return first 50 chars of OCR text if present
        // In real implementation, you'd need OCR with word positions (VNRecognizedTextObservation)
        guard let text = ocrText, !text.isEmpty else {
            return nil
        }

        let words = text.split(separator: " ")
        if words.count > 0 {
            let sample = words.prefix(3).joined(separator: " ")
            return String(sample)
        }

        return nil
    }
}

/// Result of UI element detection.
public struct UIElementDetectionResult: Sendable {
    public let elements: [UIElementDetector.UIElement]
    public let summary: String

    public init(elements: [UIElementDetector.UIElement]) {
        self.elements = elements

        // Generate summary
        let typeCounts = Dictionary(grouping: elements, by: { $0.type })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        if typeCounts.isEmpty {
            self.summary = "No UI elements detected"
        } else {
            let parts = typeCounts.map { "\($0.value) \($0.key.rawValue)s" }
            self.summary = "Detected: " + parts.joined(separator: ", ")
        }
    }
}
