import Foundation
import Shared

/// Supported AI provider types.
public enum AIProviderType: String, CaseIterable, Sendable, Codable {
    case claude = "Claude"
    case openai = "OpenAI"
    case ollama = "Ollama"
    case gemini = "Gemini"
    case custom = "Custom"

    /// Display name for UI.
    public var displayName: String { rawValue }

    /// Whether this provider requires an API key.
    public var requiresAPIKey: Bool {
        switch self {
        case .claude, .openai, .gemini: return true
        case .ollama: return false
        case .custom: return false // Optional for custom
        }
    }

    /// Default base URL for this provider.
    public var defaultBaseURL: String {
        switch self {
        case .claude: return AppConstants.AI.apiBaseURL
        case .openai: return "https://api.openai.com/v1"
        case .ollama: return "http://localhost:11434/v1"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta/openai"
        case .custom: return ""
        }
    }

    /// Default model name for this provider.
    public var defaultModelName: String {
        switch self {
        case .claude: return AppConstants.AI.modelName
        case .openai: return "gpt-4o-mini"
        case .ollama: return "llama3.2"
        case .gemini: return "gemini-2.0-flash"
        case .custom: return ""
        }
    }

    /// SF Symbol icon name.
    public var iconName: String {
        switch self {
        case .claude: return "brain.fill"
        case .openai: return "sparkles"
        case .ollama: return "desktopcomputer"
        case .gemini: return "diamond.fill"
        case .custom: return "wrench.and.screwdriver.fill"
        }
    }

    /// Short description of the provider.
    public var subtitle: String {
        switch self {
        case .claude: return "Anthropic's Claude models"
        case .openai: return "GPT-4o, GPT-4o-mini"
        case .ollama: return "Local models, fully offline"
        case .gemini: return "Google Gemini models"
        case .custom: return "Any OpenAI-compatible API"
        }
    }

    /// UserDefaults key for this provider's API key.
    public var keychainKey: String {
        "com.screenmind.\(rawValue.lowercased())-api-key"
    }
}

/// Factory that builds the correct AIProvider from user settings.
public enum AIProviderFactory {

    /// Build an AIProvider from the current user settings.
    public static func createProvider() -> (any AIProvider)? {
        let providerString = UserDefaults.standard.string(forKey: "aiProviderType") ?? AIProviderType.claude.rawValue
        let providerType = AIProviderType(rawValue: providerString) ?? .claude

        return createProvider(type: providerType)
    }

    /// Build an AIProvider for a specific type using stored settings.
    public static func createProvider(type: AIProviderType) -> (any AIProvider)? {
        let baseURL = UserDefaults.standard.string(forKey: "aiBaseURL_\(type.rawValue)") ?? type.defaultBaseURL
        let modelName = UserDefaults.standard.string(forKey: "aiModelName_\(type.rawValue)") ?? type.defaultModelName

        switch type {
        case .claude:
            guard let apiKey = try? KeychainManager.retrieve(key: type.keychainKey),
                  !apiKey.isEmpty else {
                // Fallback to legacy key
                guard let legacyKey = try? KeychainManager.retrieve(key: AppConstants.AI.keychainKey),
                      !legacyKey.isEmpty else {
                    SMLogger.ai.error("No API key found for Claude")
                    return nil
                }
                return ClaudeProvider(apiKey: legacyKey)
            }
            return ClaudeProvider(apiKey: apiKey)

        case .openai, .gemini:
            guard let apiKey = try? KeychainManager.retrieve(key: type.keychainKey),
                  !apiKey.isEmpty else {
                SMLogger.ai.error("No API key found for \(type.displayName)")
                return nil
            }
            return OpenAICompatibleProvider(
                apiKey: apiKey,
                baseURL: baseURL,
                modelName: modelName,
                providerName: type.displayName
            )

        case .ollama:
            // Ollama doesn't require an API key
            return OpenAICompatibleProvider(
                apiKey: "",
                baseURL: baseURL,
                modelName: modelName,
                providerName: "Ollama"
            )

        case .custom:
            guard !baseURL.isEmpty else {
                SMLogger.ai.error("No base URL configured for custom provider")
                return nil
            }
            let apiKey = (try? KeychainManager.retrieve(key: type.keychainKey)) ?? ""
            return OpenAICompatibleProvider(
                apiKey: apiKey,
                baseURL: baseURL,
                modelName: modelName,
                providerName: "Custom"
            )
        }
    }

    /// Test connectivity for a provider type.
    public static func testConnection(type: AIProviderType, apiKey: String, baseURL: String, modelName: String) async throws {
        switch type {
        case .claude:
            var request = URLRequest(url: URL(string: AppConstants.AI.apiBaseURL)!)
            request.httpMethod = "POST"
            request.timeoutInterval = 15
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue(AppConstants.AI.anthropicVersion, forHTTPHeaderField: "anthropic-version")
            let body: [String: Any] = [
                "model": modelName.isEmpty ? AppConstants.AI.modelName : modelName,
                "max_tokens": 10,
                "messages": [["role": "user", "content": "ping"]]
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                throw OpenAIError.apiError(statusCode: code, message: "Connection test failed")
            }

        case .openai, .gemini, .ollama, .custom:
            let url = baseURL.hasSuffix("/") ? "\(baseURL)chat/completions" : "\(baseURL)/chat/completions"
            guard let requestURL = URL(string: url) else {
                throw OpenAIError.invalidURL(url)
            }
            var request = URLRequest(url: requestURL)
            request.httpMethod = "POST"
            request.timeoutInterval = 15
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if !apiKey.isEmpty {
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            }
            let body: [String: Any] = [
                "model": modelName,
                "max_tokens": 10,
                "messages": [["role": "user", "content": "ping"]]
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                throw OpenAIError.apiError(statusCode: code, message: "Connection test failed")
            }
        }
    }
}
