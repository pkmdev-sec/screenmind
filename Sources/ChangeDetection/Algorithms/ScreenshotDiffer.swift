import Foundation
import CoreGraphics
import Accelerate

/// Pixel-by-pixel screenshot diffing with connected components analysis.
/// Compares two CGImages at reduced resolution (480px width) and returns changed regions.
public struct ScreenshotDiffer: Sendable {

    /// A rectangular region where visual change was detected.
    public struct ChangedRegion: Sendable {
        public let bounds: CGRect
        public let changePercent: Double

        public init(bounds: CGRect, changePercent: Double) {
            self.bounds = bounds
            self.changePercent = changePercent
        }
    }

    /// Configuration for screenshot diffing.
    public struct Configuration: Sendable {
        public let targetWidth: Int
        public let changeThreshold: UInt8
        public let minRegionSize: Int

        public init(
            targetWidth: Int = 480,
            changeThreshold: UInt8 = 30,
            minRegionSize: Int = 100
        ) {
            self.targetWidth = targetWidth
            self.changeThreshold = changeThreshold
            self.minRegionSize = minRegionSize
        }
    }

    private let config: Configuration

    public init(config: Configuration = Configuration()) {
        self.config = config
    }

    /// Compare two CGImages and return regions where significant changes occurred.
    /// Images are resized to targetWidth for performance, maintaining aspect ratio.
    public func diff(image1: CGImage, image2: CGImage) -> [ChangedRegion] {
        // Resize both images to same dimensions for comparison
        guard let resized1 = resize(image: image1, targetWidth: config.targetWidth),
              let resized2 = resize(image: image2, targetWidth: config.targetWidth) else {
            return []
        }

        // Ensure dimensions match
        guard resized1.width == resized2.width && resized1.height == resized2.height else {
            return []
        }

        // Create difference image
        guard let diffImage = computeDifference(image1: resized1, image2: resized2) else {
            return []
        }

        // Find connected components in difference image
        let regions = findConnectedComponents(diffImage: diffImage, threshold: config.changeThreshold)

        // Scale regions back to original dimensions
        let scaleX = Double(image1.width) / Double(resized1.width)
        let scaleY = Double(image1.height) / Double(resized1.height)

        return regions
            .filter { $0.pixelCount >= config.minRegionSize }
            .map { region in
                let scaledBounds = CGRect(
                    x: region.bounds.origin.x * scaleX,
                    y: region.bounds.origin.y * scaleY,
                    width: region.bounds.width * scaleX,
                    height: region.bounds.height * scaleY
                )
                let changePercent = Double(region.pixelCount) / Double(resized1.width * resized1.height)
                return ChangedRegion(bounds: scaledBounds, changePercent: changePercent)
            }
    }

    // MARK: - Image Processing

    /// Resize image to target width, maintaining aspect ratio.
    private func resize(image: CGImage, targetWidth: Int) -> CGImage? {
        let aspectRatio = Double(image.height) / Double(image.width)
        let targetHeight = Int(Double(targetWidth) * aspectRatio)

        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(
            data: nil,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: 8,
            bytesPerRow: targetWidth,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        context.interpolationQuality = .low
        context.draw(image, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))

        return context.makeImage()
    }

    /// Compute absolute difference between two grayscale images.
    private func computeDifference(image1: CGImage, image2: CGImage) -> CGImage? {
        let width = image1.width
        let height = image1.height
        let bytesPerRow = width

        guard let data1 = image1.dataProvider?.data as Data?,
              let data2 = image2.dataProvider?.data as Data? else {
            return nil
        }

        var pixels1 = [UInt8](repeating: 0, count: width * height)
        var pixels2 = [UInt8](repeating: 0, count: width * height)
        var diffPixels = [UInt8](repeating: 0, count: width * height)

        data1.copyBytes(to: &pixels1, count: width * height)
        data2.copyBytes(to: &pixels2, count: width * height)

        // Compute absolute difference: |pixel1 - pixel2|
        for i in 0..<(width * height) {
            let diff = abs(Int(pixels1[i]) - Int(pixels2[i]))
            diffPixels[i] = UInt8(min(diff, 255))
        }

        // Create CGImage from difference data
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let provider = CGDataProvider(data: Data(diffPixels) as CFData) else {
            return nil
        }

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }

    // MARK: - Connected Components

    private struct Component {
        var bounds: CGRect
        var pixelCount: Int
    }

    /// Find connected components in difference image using flood fill.
    /// Returns bounding boxes for regions exceeding threshold.
    private func findConnectedComponents(diffImage: CGImage, threshold: UInt8) -> [Component] {
        let width = diffImage.width
        let height = diffImage.height

        guard let data = diffImage.dataProvider?.data as Data? else {
            return []
        }

        var pixels = [UInt8](repeating: 0, count: width * height)
        data.copyBytes(to: &pixels, count: width * height)

        // Create binary mask: 1 if pixel exceeds threshold, 0 otherwise
        var mask = [Bool](repeating: false, count: width * height)
        for i in 0..<pixels.count {
            mask[i] = pixels[i] > threshold
        }

        var visited = [Bool](repeating: false, count: width * height)
        var components: [Component] = []

        // Flood fill to find connected components
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                if mask[index] && !visited[index] {
                    let component = floodFill(
                        x: x, y: y,
                        width: width, height: height,
                        mask: &mask, visited: &visited
                    )
                    components.append(component)
                }
            }
        }

        return components
    }

    /// Flood fill algorithm to find connected component.
    private func floodFill(
        x: Int, y: Int,
        width: Int, height: Int,
        mask: inout [Bool],
        visited: inout [Bool]
    ) -> Component {
        var stack: [(Int, Int)] = [(x, y)]
        var minX = x, maxX = x, minY = y, maxY = y
        var pixelCount = 0

        while let (cx, cy) = stack.popLast() {
            let index = cy * width + cx

            if cx < 0 || cx >= width || cy < 0 || cy >= height { continue }
            if visited[index] || !mask[index] { continue }

            visited[index] = true
            pixelCount += 1

            // Update bounding box
            minX = min(minX, cx)
            maxX = max(maxX, cx)
            minY = min(minY, cy)
            maxY = max(maxY, cy)

            // Add 4-connected neighbors
            stack.append((cx + 1, cy))
            stack.append((cx - 1, cy))
            stack.append((cx, cy + 1))
            stack.append((cx, cy - 1))
        }

        let bounds = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )

        return Component(bounds: bounds, pixelCount: pixelCount)
    }
}
