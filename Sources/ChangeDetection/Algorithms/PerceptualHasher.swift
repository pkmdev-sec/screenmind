import Foundation
import CoreGraphics

/// dHash (difference hash) perceptual hashing for screen change detection.
public enum PerceptualHasher {

    /// Compute dHash of a CGImage. Returns a 64-bit perceptual hash.
    /// Algorithm: Resize to 9x8 grayscale, compare adjacent pixels horizontally.
    public static func hash(of image: CGImage) -> UInt64 {
        let width = 9
        let height = 8
        let bitsPerComponent = 8
        let bytesPerRow = width

        // Create 9x8 grayscale context
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return 0 }

        // Draw image scaled to 9x8
        context.interpolationQuality = .low
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return 0 }
        let pixels = data.assumingMemoryBound(to: UInt8.self)

        // Compare each pixel with its right neighbor: 8 rows × 8 comparisons = 64 bits
        var hash: UInt64 = 0
        for row in 0..<height {
            for col in 0..<(width - 1) {
                let index = row * bytesPerRow + col
                let left = pixels[index]
                let right = pixels[index + 1]
                hash <<= 1
                if left > right {
                    hash |= 1
                }
            }
        }

        return hash
    }

    /// Compute dHash with downscaling for faster processing of large images.
    /// Downscales the image before computing the hash to reduce computation time.
    public static func hashWithDownscale(of image: CGImage, scaleFactor: Int = 6) -> UInt64 {
        let targetW = max(image.width / scaleFactor, 32)
        let targetH = max(image.height / scaleFactor, 32)
        let colorSpace = CGColorSpaceCreateDeviceGray()

        guard let ctx = CGContext(
            data: nil,
            width: targetW,
            height: targetH,
            bitsPerComponent: 8,
            bytesPerRow: targetW,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            // Fallback to regular hash if downscaling fails
            return hash(of: image)
        }

        ctx.interpolationQuality = .low
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: targetW, height: targetH))

        guard let downscaled = ctx.makeImage() else {
            return hash(of: image)
        }

        return hash(of: downscaled)
    }
}
