import SwiftUI
import Shared
import AIProcessing

/// AI settings — provider selection, API key, model config, usage stats.
struct AISettingsView: View {
    @AppStorage("aiProviderType") private var selectedProvider = AIProviderType.claude.rawValue
    @AppStorage("aiMaxTokens") private var maxTokens = AppConstants.AI.maxTokens
    @AppStorage("aiTemperature") private var temperature = AppConstants.AI.temperature
    @AppStorage("aiRateLimit") private var rateLimit = AppConstants.AI.rateLimitPerHour

    @State private var apiKey = ""
    @State private var baseURL = ""
    @State private var modelName = ""
    @State private var isKeyVisible = false
    @State private var testStatus: TestStatus = .idle

    enum TestStatus: Equatable {
        case idle, testing, success, failed(String)
    }

    private var providerType: AIProviderType {
        AIProviderType(rawValue: selectedProvider) ?? .claude
    }

    var body: some View {
        Form {
            // Provider Selection
            Section("AI Provider") {
                Picker("Provider", selection: $selectedProvider) {
                    ForEach(AIProviderType.allCases, id: \.rawValue) { type in
                        HStack(spacing: 8) {
                            Image(systemName: type.iconName)
                                .frame(width: 16)
                            Text(type.displayName)
                        }
                        .tag(type.rawValue)
                    }
                }
                .onChange(of: selectedProvider) { _, newValue in
                    loadProviderSettings(for: AIProviderType(rawValue: newValue) ?? .claude)
                    testStatus = .idle
                }

                // Provider info
                HStack(spacing: 8) {
                    Image(systemName: providerType.iconName)
                        .font(.system(size: 18))
                        .foregroundStyle(.purple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(providerType.displayName)
                            .font(.system(size: 13, weight: .semibold))
                        Text(providerType.subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if providerType == .ollama {
                        Text("Offline")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.15))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }
                .padding(6)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }

            // API Key (if required)
            if providerType.requiresAPIKey || providerType == .custom {
                Section(providerType.requiresAPIKey ? "API Key" : "API Key (Optional)") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if isKeyVisible {
                                TextField(keyPlaceholder, text: $apiKey)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 12, design: .monospaced))
                            } else {
                                SecureField(keyPlaceholder, text: $apiKey)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 12, design: .monospaced))
                            }

                            Button {
                                isKeyVisible.toggle()
                            } label: {
                                Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                            }
                            .buttonStyle(.plain)
                        }

                        HStack(spacing: 12) {
                            Button("Save to Keychain") {
                                saveAPIKey()
                            }
                            .controlSize(.small)
                            .disabled(apiKey.isEmpty && providerType.requiresAPIKey)

                            Button("Test Connection") {
                                testConnection()
                            }
                            .controlSize(.small)
                            .disabled(apiKey.isEmpty && providerType.requiresAPIKey)

                            testStatusView
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.green)
                            .font(.system(size: 11))
                        Text("Stored securely in macOS Keychain. Never sent to logs.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Endpoint Configuration
            Section("Endpoint") {
                HStack {
                    Text("Base URL:")
                        .font(.system(size: 12))
                    TextField(providerType.defaultBaseURL, text: $baseURL)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                }

                HStack {
                    Text("Model:")
                        .font(.system(size: 12))
                    TextField(providerType.defaultModelName, text: $modelName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                }

                if providerType == .ollama {
                    Button("Test Ollama Connection") {
                        testConnection()
                    }
                    .controlSize(.small)

                    testStatusView

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                            .font(.system(size: 11))
                        Text("Make sure Ollama is running: ollama serve")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Button("Reset to Defaults") {
                    baseURL = providerType.defaultBaseURL
                    modelName = providerType.defaultModelName
                    saveEndpointSettings()
                }
                .controlSize(.mini)
                .foregroundStyle(.secondary)
            }

            // Model Parameters
            Section("Model Parameters") {
                HStack {
                    Text("Max tokens:")
                    Spacer()
                    Stepper("\(maxTokens)", value: $maxTokens, in: 128...4096, step: 64)
                        .frame(width: 120)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Temperature:")
                        Spacer()
                        Text(String(format: "%.1f", temperature))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $temperature, in: 0.0...1.0, step: 0.1)
                }

                HStack {
                    Text("Rate limit:")
                    Spacer()
                    Stepper("\(rateLimit) req/hr", value: $rateLimit, in: 10...500, step: 10)
                        .frame(width: 150)
                }
            }

            // Cost info (only for paid providers)
            if providerType == .claude || providerType == .openai || providerType == .gemini {
                Section("Cost Estimate") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(costEstimate)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.green)
                        Text("Based on ~576 requests/day at 600 input + 200 output tokens each")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            loadProviderSettings(for: providerType)
        }
        .onChange(of: baseURL) { _, _ in saveEndpointSettings() }
        .onChange(of: modelName) { _, _ in saveEndpointSettings() }
    }

    // MARK: - UI Helpers

    @ViewBuilder
    private var testStatusView: some View {
        switch testStatus {
        case .idle:
            EmptyView()
        case .testing:
            ProgressView()
                .controlSize(.small)
        case .success:
            Label("Connected", systemImage: "checkmark.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(.green)
        case .failed(let msg):
            Label(msg, systemImage: "xmark.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(.red)
                .lineLimit(2)
        }
    }

    private var keyPlaceholder: String {
        switch providerType {
        case .claude: return "sk-ant-..."
        case .openai: return "sk-..."
        case .gemini: return "AI..."
        case .ollama: return "Not required"
        case .custom: return "API key (optional)"
        }
    }

    private var costEstimate: String {
        switch providerType {
        case .claude: return "~$1.50 - $2.80 / month"
        case .openai: return "~$0.50 - $1.50 / month"
        case .gemini: return "~$0.30 - $0.80 / month"
        case .ollama: return "Free (local)"
        case .custom: return "Varies"
        }
    }

    // MARK: - Settings Persistence

    private func loadProviderSettings(for type: AIProviderType) {
        apiKey = (try? KeychainManager.retrieve(key: type.keychainKey)) ?? ""
        // Fallback to legacy key for Claude
        if apiKey.isEmpty && type == .claude {
            apiKey = (try? KeychainManager.retrieve(key: AppConstants.AI.keychainKey)) ?? ""
        }
        baseURL = UserDefaults.standard.string(forKey: "aiBaseURL_\(type.rawValue)") ?? type.defaultBaseURL
        modelName = UserDefaults.standard.string(forKey: "aiModelName_\(type.rawValue)") ?? type.defaultModelName
    }

    private func saveAPIKey() {
        try? KeychainManager.save(key: providerType.keychainKey, value: apiKey)
        // Also save to legacy key for Claude backward compat
        if providerType == .claude {
            try? KeychainManager.save(key: AppConstants.AI.keychainKey, value: apiKey)
        }
    }

    private func saveEndpointSettings() {
        let type = providerType
        if !baseURL.isEmpty {
            UserDefaults.standard.set(baseURL, forKey: "aiBaseURL_\(type.rawValue)")
        }
        if !modelName.isEmpty {
            UserDefaults.standard.set(modelName, forKey: "aiModelName_\(type.rawValue)")
        }
    }

    // MARK: - Test Connection

    private func testConnection() {
        testStatus = .testing
        saveAPIKey()
        saveEndpointSettings()

        let type = providerType
        let key = apiKey
        let url = baseURL.isEmpty ? type.defaultBaseURL : baseURL
        let model = modelName.isEmpty ? type.defaultModelName : modelName

        Task {
            do {
                try await AIProviderFactory.testConnection(type: type, apiKey: key, baseURL: url, modelName: model)
                testStatus = .success
            } catch {
                testStatus = .failed(error.localizedDescription)
            }
        }
    }
}
