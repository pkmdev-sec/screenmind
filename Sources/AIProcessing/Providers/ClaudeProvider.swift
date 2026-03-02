import Foundation
import AppKit
import Shared

/// Language model API client for note generation.
public struct ClaudeProvider: AIProvider, Sendable {
    private let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public var supportsVision: Bool { true }

    public func generateNote(from ocrText: String, appName: String, windowTitle: String?, lastNoteTitle: String? = nil, lastNoteApp: String? = nil, bundleID: String? = nil, contextWindow: [(title: String, summary: String, timestamp: Date)] = []) async throws -> GeneratedNote {
        return try await generateNote(from: ocrText, appName: appName, windowTitle: windowTitle, lastNoteTitle: lastNoteTitle, lastNoteApp: lastNoteApp, bundleID: bundleID, imageData: nil, contextWindow: contextWindow)
    }

    public func generateNote(from ocrText: String, appName: String, windowTitle: String?, lastNoteTitle: String? = nil, lastNoteApp: String? = nil, bundleID: String? = nil, imageData: Data? = nil, contextWindow: [(title: String, summary: String, timestamp: Date)] = []) async throws -> GeneratedNote {
        let prompt = NotePromptBuilder.buildUserPrompt(ocrText: ocrText, appName: appName, windowTitle: windowTitle, lastNoteTitle: lastNoteTitle, lastNoteApp: lastNoteApp, bundleID: bundleID, contextWindow: contextWindow)

        // Build content array with optional image
        let content: [[String: Any]]
        let visionEnabled = UserDefaults.standard.bool(forKey: "aiVisionEnabled")

        if visionEnabled, let imageData = imageData {
            // Preprocess image: resize and encode as base64
            let processedImageData = try preprocessImage(imageData)
            let base64Image = processedImageData.base64EncodedString()

            content = [
                [
                    "type": "image",
                    "source": [
                        "type": "base64",
                        "media_type": "image/jpeg",
                        "data": base64Image
                    ]
                ],
                [
                    "type": "text",
                    "text": prompt
                ]
            ]
        } else {
            content = [["type": "text", "text": prompt]]
        }

        let requestBody: [String: Any] = [
            "model": AppConstants.AI.modelName,
            "max_tokens": AppConstants.AI.maxTokens,
            "temperature": AppConstants.AI.temperature,
            "messages": [
                ["role": "user", "content": content]
            ],
            "system": NotePromptBuilder.systemPrompt
        ]

        var request = URLRequest(url: URL(string: AppConstants.AI.apiBaseURL)!)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(AppConstants.AI.anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            SMLogger.ai.error("Claude API error \(httpResponse.statusCode): \(body)")
            throw ClaudeError.apiError(statusCode: httpResponse.statusCode, message: body)
        }

        return try ClaudeResponseParser.parse(data)
    }

    /// Preprocess image: resize to max 1024px and convert to JPEG.
    private func preprocessImage(_ data: Data) throws -> Data {
        guard let nsImage = NSImage(data: data) else {
            throw ClaudeError.parseError("Invalid image data")
        }

        let maxDimension: CGFloat = 1024
        let size = nsImage.size
        let aspectRatio = size.width / size.height

        let newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        // Only resize if needed
        if size.width <= maxDimension && size.height <= maxDimension {
            // Already small enough, just ensure JPEG format
            return data
        }

        let resized = NSImage(size: newSize)
        resized.lockFocus()
        nsImage.draw(in: NSRect(origin: .zero, size: newSize))
        resized.unlockFocus()

        guard let tiffData = resized.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
            throw ClaudeError.parseError("Image resize failed")
        }

        return jpegData
    }

}

/// Errors from the Claude API.
public enum ClaudeError: Error, LocalizedError {
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parseError(String)
    case rateLimited
    case noAPIKey

    public var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from Claude API"
        case .apiError(let code, let msg): return "Claude API error \(code): \(msg)"
        case .parseError(let detail): return "Failed to parse Claude response: \(detail)"
        case .rateLimited: return "Claude API rate limit exceeded"
        case .noAPIKey: return "No Anthropic API key configured"
        }
    }
}
