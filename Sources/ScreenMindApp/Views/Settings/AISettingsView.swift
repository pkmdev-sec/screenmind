import SwiftUI
import Shared

/// AI settings — API key, model config, usage stats.
struct AISettingsView: View {
    @State private var apiKey = ""
    @State private var isKeyVisible = false
    @State private var testStatus: TestStatus = .idle
    @AppStorage("aiMaxTokens") private var maxTokens = AppConstants.AI.maxTokens
    @AppStorage("aiTemperature") private var temperature = AppConstants.AI.temperature
    @AppStorage("aiRateLimit") private var rateLimit = AppConstants.AI.rateLimitPerHour

    enum TestStatus {
        case idle, testing, success, failed(String)
    }

    var body: some View {
        Form {
            Section("API Key") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if isKeyVisible {
                            TextField("sk-ant-...", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12, design: .monospaced))
                        } else {
                            SecureField("sk-ant-...", text: $apiKey)
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
                            try? KeychainManager.save(key: AppConstants.AI.keychainKey, value: apiKey)
                        }
                        .controlSize(.small)
                        .disabled(apiKey.isEmpty)

                        Button("Test Connection") {
                            testConnection()
                        }
                        .controlSize(.small)
                        .disabled(apiKey.isEmpty)

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
                        }
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

            Section("Model Configuration") {
                // Model info card
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Language Model")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Sonnet 4.6")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "brain.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.purple)
                }
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))

                HStack {
                    Text("Max tokens:")
                    Spacer()
                    Stepper("\(maxTokens)", value: $maxTokens, in: 128...2048, step: 64)
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

            Section("Cost Estimate") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("~$1.50 — $2.80 / month")
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
        .formStyle(.grouped)
        .padding()
        .onAppear {
            apiKey = (try? KeychainManager.retrieve(key: AppConstants.AI.keychainKey)) ?? ""
        }
    }

    private func testConnection() {
        testStatus = .testing
        Task {
            do {
                try? KeychainManager.save(key: AppConstants.AI.keychainKey, value: apiKey)

                var request = URLRequest(url: URL(string: AppConstants.AI.apiBaseURL)!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
                request.setValue(AppConstants.AI.anthropicVersion, forHTTPHeaderField: "anthropic-version")

                let body: [String: Any] = [
                    "model": AppConstants.AI.modelName,
                    "max_tokens": 10,
                    "messages": [["role": "user", "content": "ping"]]
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    testStatus = .success
                } else {
                    testStatus = .failed("API returned error")
                }
            } catch {
                testStatus = .failed(error.localizedDescription)
            }
        }
    }
}
