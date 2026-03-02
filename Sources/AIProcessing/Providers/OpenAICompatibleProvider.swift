import Foundation
import AppKit
import Shared

/// Provider for OpenAI-compatible chat completion APIs.
/// Works with: OpenAI, Ollama (local), Gemini (via OpenAI compat), and custom endpoints.
public struct OpenAICompatibleProvider: AIProvider, Sendable {
    private let apiKey: String
    private let baseURL: String
    private let modelName: String
    private let providerName: String

    public init(apiKey: String, baseURL: String, modelName: String, providerName: String = "OpenAI") {
        self.apiKey = apiKey
        self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        self.modelName = modelName
        self.providerName = providerName
    }

    public var supportsVision: Bool {
        // Only OpenAI and Gemini support vision, not Ollama
        return providerName == "OpenAI" || providerName == "Gemini"
    }

    public func generateNote(from ocrText: String, appName: String, windowTitle: String?, lastNoteTitle: String?, lastNoteApp: String?, bundleID: String? = nil, contextWindow: [(title: String, summary: String, timestamp: Date)] = []) async throws -> GeneratedNote {
        return try await generateNote(from: ocrText, appName: appName, windowTitle: windowTitle, lastNoteTitle: lastNoteTitle, lastNoteApp: lastNoteApp, bundleID: bundleID, imageData: nil, contextWindow: contextWindow)
    }

    public func generateNote(from ocrText: String, appName: String, windowTitle: String?, lastNoteTitle: String?, lastNoteApp: String?, bundleID: String? = nil, imageData: Data? = nil, contextWindow: [(title: String, summary: String, timestamp: Date)] = []) async throws -> GeneratedNote {
        let prompt = NotePromptBuilder.buildUserPrompt(ocrText: ocrText, appName: appName, windowTitle: windowTitle, lastNoteTitle: lastNoteTitle, lastNoteApp: lastNoteApp, bundleID: bundleID, contextWindow: contextWindow)

        let visionEnabled = UserDefaults.standard.bool(forKey: "aiVisionEnabled")

        // Build user message content
        let userContent: Any
        if visionEnabled, supportsVision, let imageData = imageData {
            // Preprocess image
            let processedImageData = try preprocessImage(imageData)
            let base64Image = processedImageData.base64EncodedString()

            userContent = [
                ["type": "text", "text": prompt],
                [
                    "type": "image_url",
                    "image_url": [
                        "url": "data:image/jpeg;base64,\(base64Image)"
                    ]
                ]
            ]
        } else {
            userContent = prompt
        }

        let requestBody: [String: Any] = [
            "model": modelName,
            "max_tokens": UserDefaults.standard.integer(forKey: "aiMaxTokens").clamped(to: 128...4096, default: AppConstants.AI.maxTokens),
            "temperature": UserDefaults.standard.double(forKey: "aiTemperature").clamped(to: 0.0...2.0, default: AppConstants.AI.temperature),
            "messages": [
                ["role": "system", "content": NotePromptBuilder.systemPrompt],
                ["role": "user", "content": userContent]
            ]
        ]

        let endpoint = "\(baseURL)/chat/completions"
        guard let url = URL(string: endpoint) else {
            throw OpenAIError.invalidURL(endpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Auth: Ollama doesn't need a key, OpenAI/Gemini/Custom use Bearer token
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            SMLogger.ai.error("\(providerName) API error \(httpResponse.statusCode): \(body)")
            throw OpenAIError.apiError(statusCode: httpResponse.statusCode, message: body)
        }

        return try Self.parseResponse(data, providerName: providerName)
    }

    /// Preprocess image: resize to max 1024px and convert to JPEG.
    private func preprocessImage(_ data: Data) throws -> Data {
        guard let nsImage = NSImage(data: data) else {
            throw OpenAIError.parseError("Invalid image data")
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
            return data
        }

        let resized = NSImage(size: newSize)
        resized.lockFocus()
        nsImage.draw(in: NSRect(origin: .zero, size: newSize))
        resized.unlockFocus()

        guard let tiffData = resized.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
            throw OpenAIError.parseError("Image resize failed")
        }

        return jpegData
    }

    // MARK: - Response Parsing

    /// Parse an OpenAI-compatible chat completion response.
    static func parseResponse(_ data: Data, providerName: String) throws -> GeneratedNote {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.parseError("Could not extract content from \(providerName) response")
        }

        return try ClaudeResponseParser.parseNoteJSON(content)
    }

}

/// Errors from OpenAI-compatible APIs.
public enum OpenAIError: Error, LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parseError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url): return "Invalid API URL: \(url)"
        case .invalidResponse: return "Invalid response from API"
        case .apiError(let code, let msg): return "API error \(code): \(msg)"
        case .parseError(let detail): return "Failed to parse response: \(detail)"
        }
    }
}

// MARK: - Numeric clamping helpers

private extension Int {
    func clamped(to range: ClosedRange<Int>, default defaultValue: Int) -> Int {
        let value = self == 0 ? defaultValue : self
        return Swift.min(Swift.max(value, range.lowerBound), range.upperBound)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>, default defaultValue: Double) -> Double {
        let value = self == 0 ? defaultValue : self
        return Swift.min(Swift.max(value, range.lowerBound), range.upperBound)
    }
}
