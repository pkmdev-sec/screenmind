import SwiftUI
import CoreGraphics
import Shared

/// Multi-step onboarding wizard for first launch.
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentStep = 0
    @State private var apiKey = ""
    @State private var vaultPath = AppConstants.Obsidian.defaultVaultPath
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(step == currentStep ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: currentStep)
                }
            }
            .padding(.top, 24)

            Spacer()

            // Step content
            Group {
                switch currentStep {
                case 0: welcomeStep
                case 1: permissionStep
                case 2: apiKeyStep
                case 3: vaultStep
                case 4: readyStep
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
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep -= 1
                        }
                    }
                    .controlSize(.large)
                }

                Spacer()

                Button(currentStep == 4 ? "Get Started" : "Continue") {
                    if currentStep == 4 {
                        hasCompletedOnboarding = true
                        dismiss()
                    } else {
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
        .frame(width: 500, height: 420)
        .background {
            LinearGradient(
                colors: [.blue.opacity(0.05), .purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var canProceed: Bool {
        switch currentStep {
        case 0: return true // Welcome — always proceed
        case 1: return CGPreflightScreenCaptureAccess() // Permission must be granted
        case 2: return !apiKey.isEmpty // API key must be entered
        case 3: return FileManager.default.isWritableFile(atPath: (vaultPath as NSString).expandingTildeInPath) // Vault must exist
        case 4: return true // Ready — always proceed
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
        }
    }

    private var permissionStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "record.circle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Screen Recording Permission")
                .font(.system(size: 20, weight: .bold))

            Text("ScreenMind needs screen recording access to capture what's on your screen. Your data stays local — only OCR text is sent to Claude AI for note generation.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 40)

            Button("Grant Permission") {
                CGRequestScreenCaptureAccess()
            }
            .controlSize(.large)
            .buttonStyle(.bordered)
            .padding(.top, 8)

            if CGPreflightScreenCaptureAccess() {
                Label("Permission granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 13))
            }
        }
    }

    private var apiKeyStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.fill")
                .font(.system(size: 48))
                .foregroundStyle(.purple)

            Text("Claude AI Setup")
                .font(.system(size: 20, weight: .bold))

            Text("Enter your Anthropic API key to enable AI-powered note generation. You can get one at console.anthropic.com.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 40)

            SecureField("sk-ant-...", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
                .onChange(of: apiKey) { _, newValue in
                    if !newValue.isEmpty {
                        try? KeychainManager.save(key: AppConstants.AI.keychainKey, value: newValue)
                    }
                }

            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.green)
                Text("Stored in macOS Keychain")
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

                Button("Change…") {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    if panel.runModal() == .OK, let url = panel.url {
                        vaultPath = url.path
                        UserDefaults.standard.set(vaultPath, forKey: "obsidianVaultPath")
                    }
                }
                .controlSize(.small)
            }
            .frame(width: 350)
        }
    }

    private var readyStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            Text("You're All Set!")
                .font(.system(size: 24, weight: .bold))

            Text("ScreenMind will run silently in your menu bar. Click the brain icon to see your notes, pause monitoring, or adjust settings.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 8) {
                Label("⌘⇧N — Toggle monitoring", systemImage: "keyboard")
                Label("⌘⇧P — Pause / Resume", systemImage: "keyboard")
                Label("⌘⇧S — Open notes browser", systemImage: "keyboard")
            }
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(.secondary)
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
    }
}
