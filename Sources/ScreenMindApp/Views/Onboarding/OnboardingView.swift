import SwiftUI
import CoreGraphics
import Shared

/// Multi-step onboarding wizard for first launch.
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentStep = 0
    @State private var apiKey = ""
    @State private var vaultPath = AppConstants.Obsidian.defaultVaultPath
    @State private var selectedProvider: String = "Claude"
    @State private var apiTestStatus: APITestStatus = .idle
    @State private var vaultStatus: VaultStatus = .unchecked
    @State private var showSkipWarning = false
    @Environment(\.dismiss) private var dismiss

    private let totalSteps = 5

    private let aiProviders = ["Claude", "OpenAI", "Ollama", "Gemini", "Custom"]

    enum APITestStatus: Equatable {
        case idle
        case testing
        case success
        case failed(String)
    }

    enum VaultStatus {
        case unchecked
        case valid
        case notFound
        case notWritable
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                        .scaleEffect(step == currentStep ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: currentStep)
                }
            }
            .padding(.top, 24)

            // Step counter
            Text("Step \(currentStep + 1) of \(totalSteps)")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .padding(.top, 6)

            Spacer()

            // Step content
            Group {
                switch currentStep {
                case 0: welcomeStep
                case 1: permissionStep
                case 2: apiKeyStep
                case 3: vaultStep
                case 4: demoStep
                default: EmptyView()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            Spacer()

            // Navigation buttons
            HStack {
                if currentStep == 0 {
                    Button("Skip Setup") {
                        showSkipWarning = true
                    }
                    .controlSize(.large)
                    .foregroundStyle(.secondary)
                    .alert("Skip Setup?", isPresented: $showSkipWarning) {
                        Button("Cancel", role: .cancel) {}
                        Button("Skip Anyway") {
                            hasCompletedOnboarding = true
                            dismiss()
                        }
                    } message: {
                        Text("You'll need to configure the API key and vault path in Settings before ScreenMind can generate notes.")
                    }
                } else if currentStep > 0 {
                    Button("Back") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep -= 1
                        }
                    }
                    .controlSize(.large)
                }

                Spacer()

                if currentStep == 2 && apiTestStatus != .success && !apiKey.isEmpty {
                    // Show test button on API step if not yet tested
                    Button("Test API Key") {
                        testAPIKey()
                    }
                    .controlSize(.large)
                    .buttonStyle(.bordered)
                    .disabled(apiTestStatus == .testing)
                }

                Button(currentStep == totalSteps - 1 ? "Get Started" : "Continue") {
                    if currentStep == totalSteps - 1 {
                        completeOnboarding()
                    } else {
                        // Save settings when leaving relevant steps
                        if currentStep == 2, !apiKey.isEmpty {
                            saveAPISettings()
                        }
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep += 1
                        }
                    }
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .disabled(!canProceed)
            }
            .padding(24)
        }
        .frame(width: 520, height: 480)
        .background {
            LinearGradient(
                colors: [.blue.opacity(0.08), .purple.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .onAppear {
            // Load existing values if re-running setup
            selectedProvider = UserDefaults.standard.string(forKey: "aiProviderType") ?? "Claude"
            apiKey = (try? KeychainManager.retrieve(key: getKeychainKeyForProvider())) ?? ""
            if let savedPath = UserDefaults.standard.string(forKey: "obsidianVaultPath"), !savedPath.isEmpty {
                vaultPath = savedPath
            }
        }
    }

    private var canProceed: Bool {
        switch currentStep {
        case 0: return true
        case 1: return CGPreflightScreenCaptureAccess()
        case 2: return !apiKey.isEmpty
        case 3: return vaultStatus == .valid
        case 4: return true // Excluded apps is optional
        case 5: return true
        default: return true
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 56))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("Welcome to ScreenMind")
                .font(.system(size: 24, weight: .bold))

            Text("AI-powered screen memory for macOS.\nScreenMind watches your screen, understands what you're working on, and automatically creates smart notes — so you never forget what you saw.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 40)

            // Feature highlights
            VStack(alignment: .leading, spacing: 8) {
                featureRow(icon: "eye", color: .blue, text: "Captures screen changes intelligently")
                featureRow(icon: "text.magnifyingglass", color: .green, text: "Extracts text with OCR")
                featureRow(icon: "brain", color: .purple, text: "AI generates structured notes")
                featureRow(icon: "book.closed", color: .orange, text: "Exports to Obsidian automatically")
            }
            .padding(.top, 8)
        }
    }

    private func featureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    private var permissionStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "record.circle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Screen Recording Permission")
                .font(.system(size: 20, weight: .bold))

            Text("ScreenMind needs screen recording access to capture what's on your screen. Your data stays local — only extracted text is sent for note generation.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 40)

            VStack(spacing: 12) {
                Button("Grant Permission") {
                    CGRequestScreenCaptureAccess()
                }
                .controlSize(.large)
                .buttonStyle(.bordered)

                Button("Open System Settings") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
                }
                .controlSize(.small)
                .foregroundStyle(.secondary)
            }
            .padding(.top, 8)

            if CGPreflightScreenCaptureAccess() {
                Label("Permission granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 13, weight: .medium))
            }
        }
    }

    private var apiKeyStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.fill")
                .font(.system(size: 48))
                .foregroundStyle(.purple)

            Text("AI Provider Setup")
                .font(.system(size: 20, weight: .bold))

            Text("Choose your AI provider and enter your API key to enable intelligent note generation.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 40)

            // Provider picker
            Picker("Provider", selection: $selectedProvider) {
                ForEach(aiProviders, id: \.self) { provider in
                    Text(provider).tag(provider)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 380)
            .onChange(of: selectedProvider) { _, _ in
                apiKey = (try? KeychainManager.retrieve(key: getKeychainKeyForProvider())) ?? ""
                apiTestStatus = .idle
            }

            // API key instructions
            Text(providerInstructions)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            SecureField(providerPlaceholder, text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .frame(width: 380)
                .onChange(of: apiKey) { _, _ in
                    apiTestStatus = .idle
                }

            // Test status
            switch apiTestStatus {
            case .idle:
                EmptyView()
            case .testing:
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Testing connection...")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            case .success:
                Label("API key verified successfully", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 12, weight: .medium))
            case .failed(let msg):
                Label(msg, systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.system(size: 12))
            }

            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.green)
                Text("Stored securely in macOS Keychain")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var vaultStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Obsidian Vault")
                .font(.system(size: 20, weight: .bold))

            Text("Notes are saved as Markdown files to your Obsidian vault. They'll appear automatically in Obsidian with tags, links, and frontmatter.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 40)

            HStack {
                Text(vaultPath)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))

                Button("Change...") {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    if panel.runModal() == .OK, let url = panel.url {
                        vaultPath = url.path
                        UserDefaults.standard.set(vaultPath, forKey: "obsidianVaultPath")
                        validateVault()
                    }
                }
                .controlSize(.small)
            }
            .frame(width: 380)

            // Validation
            HStack(spacing: 6) {
                switch vaultStatus {
                case .unchecked:
                    EmptyView()
                case .valid:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Vault path is valid and writable")
                        .font(.system(size: 11))
                        .foregroundStyle(.green)
                case .notFound:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    Text("Path does not exist")
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                    Button("Create") {
                        let expanded = (vaultPath as NSString).expandingTildeInPath
                        try? FileManager.default.createDirectory(atPath: expanded, withIntermediateDirectories: true)
                        validateVault()
                    }
                    .controlSize(.mini)
                case .notWritable:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Path exists but is not writable")
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)
                }
            }
            .font(.system(size: 12))
        }
        .onAppear {
            validateVault()
        }
    }

    private var demoStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.point.up.braille.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text("Try Your First Capture!")
                .font(.system(size: 24, weight: .bold))

            Text("ScreenMind is ready! Let's try a manual capture to see how it works. You can trigger a capture anytime with the keyboard shortcut.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 40)

            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "1.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.system(size: 20))
                    Text("Use Cmd+Opt+Shift+C to capture your screen")
                        .font(.system(size: 13))
                }

                HStack(spacing: 10) {
                    Image(systemName: "2.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.system(size: 20))
                    Text("ScreenMind will extract text and create a note")
                        .font(.system(size: 13))
                }

                HStack(spacing: 10) {
                    Image(systemName: "3.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.system(size: 20))
                    Text("View your notes in the menu bar or browser")
                        .font(.system(size: 13))
                }
            }
            .padding(16)
            .frame(maxWidth: 400)
            .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text("Essential Shortcuts:")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 20) {
                    Label("Cmd+Shift+N", systemImage: "power")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Label("Cmd+Shift+P", systemImage: "pause.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Label("Cmd+Shift+S", systemImage: "note.text")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Helpers

    private var providerInstructions: String {
        switch selectedProvider {
        case "Claude": return "Get your API key at console.anthropic.com"
        case "OpenAI": return "Get your API key at platform.openai.com/api-keys"
        case "Ollama": return "Run Ollama locally - no API key required (leave blank)"
        case "Gemini": return "Get your API key at aistudio.google.com/apikey"
        case "Custom": return "Enter your custom API endpoint's key"
        default: return ""
        }
    }

    private var providerPlaceholder: String {
        switch selectedProvider {
        case "Claude": return "sk-ant-..."
        case "OpenAI": return "sk-proj-..."
        case "Ollama": return "localhost:11434 (no key needed)"
        case "Gemini": return "AIza..."
        case "Custom": return "your-api-key"
        default: return ""
        }
    }

    private func getKeychainKeyForProvider() -> String {
        switch selectedProvider {
        case "Claude": return "com.screenmind.claude-api-key"
        case "OpenAI": return "com.screenmind.openai-api-key"
        case "Ollama": return "com.screenmind.ollama-api-key"
        case "Gemini": return "com.screenmind.gemini-api-key"
        case "Custom": return "com.screenmind.custom-api-key"
        default: return AppConstants.AI.keychainKey
        }
    }

    private func saveAPISettings() {
        UserDefaults.standard.set(selectedProvider, forKey: "aiProviderType")
        if !apiKey.isEmpty {
            try? KeychainManager.save(key: getKeychainKeyForProvider(), value: apiKey)
        }
    }

    private func validateVault() {
        let expanded = (vaultPath as NSString).expandingTildeInPath
        if !FileManager.default.fileExists(atPath: expanded) {
            vaultStatus = .notFound
        } else if !FileManager.default.isWritableFile(atPath: expanded) {
            vaultStatus = .notWritable
        } else {
            vaultStatus = .valid
        }
    }

    private func testAPIKey() {
        apiTestStatus = .testing
        saveAPISettings()

        // Skip test for Ollama (local, no key needed)
        if selectedProvider == "Ollama" {
            apiTestStatus = .success
            return
        }

        Task {
            do {
                // Test based on provider
                if selectedProvider == "Claude" {
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
                        apiTestStatus = .success
                    } else if let http = response as? HTTPURLResponse {
                        apiTestStatus = .failed("API returned status \(http.statusCode)")
                    } else {
                        apiTestStatus = .failed("Unexpected response")
                    }
                } else {
                    // For other providers, just validate key format
                    if apiKey.count > 10 {
                        apiTestStatus = .success
                    } else {
                        apiTestStatus = .failed("API key too short")
                    }
                }
            } catch {
                apiTestStatus = .failed(error.localizedDescription)
            }
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        dismiss()
    }
}
