import CoreGraphics
import AppKit

public enum ThumbnailGenerator {
    /// Generate a small JPEG thumbnail from a CGImage.
    /// Returns ~2KB of JPEG data (100x75 max).
    public static func generate(from image: CGImage, maxWidth: Int = 100, maxHeight: Int = 75) -> Data? {
        let aspect = CGFloat(image.width) / CGFloat(image.height)
        let w: Int, h: Int
        if aspect > CGFloat(maxWidth) / CGFloat(maxHeight) {
            w = maxWidth
            h = max(Int(CGFloat(maxWidth) / aspect), 1)
        } else {
            h = maxHeight
            w = max(Int(CGFloat(maxHeight) * aspect), 1)
        }

        guard let ctx = CGContext(
            data: nil, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.interpolationQuality = .medium
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))

        guard let thumb = ctx.makeImage() else { return nil }
        let nsImage = NSImage(cgImage: thumb, size: NSSize(width: w, height: h))
        guard let tiff = nsImage.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .jpeg, properties: [.compressionFactor: 0.7])
    }
}
