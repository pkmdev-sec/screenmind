import SwiftUI
import SwiftData
import CoreGraphics
import Shared
import StorageCore
import PipelineCore
import OCRProcessing

/// Privacy settings — redaction, skip rules, encryption, audit log, permissions.
struct PrivacySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("privacyRedactionEnabled") private var redactionEnabled = true
    @AppStorage("privacyScreenshotEncryption") private var encryptionEnabled = false
    @AppStorage("privacyAuditLogEnabled") private var auditLogEnabled = true

    @State private var showDeleteConfirmation = false
    @State private var screenCaptureGranted = false
    @State private var deleteMessage: String?

    // Skip rules state
    @State private var skipRules: [SkipRuleEngine.SkipRule] = []
    @State private var newRuleName = ""
    @State private var newRuleType: SkipRuleEngine.RuleType = .textContains
    @State private var newRulePattern = ""

    // Custom redaction patterns
    @State private var customPatterns: [ContentRedactor.CustomPattern] = []
    @State private var newPatternName = ""
    @State private var newPatternRegex = ""

    // Audit log
    @State private var auditEntryCount = 0
    @State private var exportedLogPath: String?

    var body: some View {
        Form {
            // Permissions
            Section("Permissions") {
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Screen Recording")
                                .font(.system(size: 13, weight: .medium))
                            Text("Required to capture screen content")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "record.circle")
                            .foregroundStyle(screenCaptureGranted ? .green : .red)
                    }
                    Spacer()
                    if screenCaptureGranted {
                        Text("Granted")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.green)
                    } else {
                        Button("Open System Settings") {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
                        }
                        .controlSize(.small)
                    }
                }
            }

            // Content Redaction
            Section("Content Redaction") {
                Toggle("Auto-redact sensitive data before AI processing", isOn: $redactionEnabled)

                if redactionEnabled {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.checkered")
                            .foregroundStyle(.green)
                            .font(.system(size: 12))
                        Text("Credit cards, SSNs, API keys, passwords, and emails are automatically replaced with [REDACTED] before being sent to the AI.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 2)

                    // Custom patterns
                    DisclosureGroup("Custom Redaction Patterns (\(customPatterns.count))") {
                        ForEach(customPatterns.indices, id: \.self) { index in
                            HStack {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(customPatterns[index].name)
                                        .font(.system(size: 11, weight: .medium))
                                    Text(customPatterns[index].pattern)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    customPatterns.remove(at: index)
                                    ContentRedactor.saveCustomPatterns(customPatterns)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack(spacing: 6) {
                            TextField("Name", text: $newPatternName)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                            TextField("Regex pattern", text: $newPatternRegex)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11, design: .monospaced))
                            Button("Add") {
                                guard !newPatternName.isEmpty, !newPatternRegex.isEmpty,
                                      ContentRedactor.validatePattern(newPatternRegex) else { return }
                                customPatterns.append(.init(name: newPatternName, pattern: newPatternRegex))
                                ContentRedactor.saveCustomPatterns(customPatterns)
                                newPatternName = ""
                                newPatternRegex = ""
                            }
                            .controlSize(.small)
                            .disabled(newPatternName.isEmpty || newPatternRegex.isEmpty)
                        }
                    }
                }
            }

            // Skip Rules
            Section("Skip Rules") {
                HStack(spacing: 6) {
                    Image(systemName: "eye.slash")
                        .foregroundStyle(.orange)
                        .font(.system(size: 12))
                    Text("Skip rules prevent captures from reaching AI, saving API costs.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                ForEach(skipRules.indices, id: \.self) { index in
                    HStack {
                        Toggle(isOn: Binding(
                            get: { skipRules[index].enabled },
                            set: { skipRules[index].enabled = $0; SkipRuleEngine.saveRules(skipRules) }
                        )) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(skipRules[index].name)
                                    .font(.system(size: 11, weight: .medium))
                                HStack(spacing: 4) {
                                    Image(systemName: skipRules[index].type.iconName)
                                        .font(.system(size: 9))
                                    Text(skipRules[index].type.rawValue)
                                        .font(.system(size: 10))
                                    Text("\"" + skipRules[index].pattern + "\"")
                                        .font(.system(size: 10, design: .monospaced))
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                        Button(role: .destructive) {
                            skipRules.remove(at: index)
                            SkipRuleEngine.saveRules(skipRules)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Add rule
                DisclosureGroup("Add Skip Rule") {
                    TextField("Rule name", text: $newRuleName)
                        .textFieldStyle(.roundedBorder)
                    Picker("Type", selection: $newRuleType) {
                        ForEach(SkipRuleEngine.RuleType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    TextField("Pattern", text: $newRulePattern)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                    Button("Add Rule") {
                        guard !newRuleName.isEmpty, !newRulePattern.isEmpty else { return }
                        skipRules.append(.init(name: newRuleName, type: newRuleType, pattern: newRulePattern))
                        SkipRuleEngine.saveRules(skipRules)
                        newRuleName = ""
                        newRulePattern = ""
                    }
                    .controlSize(.small)
                    .disabled(newRuleName.isEmpty || newRulePattern.isEmpty)
                }
            }

            // Encryption
            Section("Screenshot Encryption") {
                Toggle("Encrypt screenshots at rest (AES-256-GCM)", isOn: $encryptionEnabled)

                HStack(spacing: 6) {
                    Image(systemName: encryptionEnabled ? "lock.fill" : "lock.open")
                        .foregroundStyle(encryptionEnabled ? .green : .secondary)
                        .font(.system(size: 12))
                    Text(encryptionEnabled
                         ? "New screenshots are encrypted. Key stored in macOS Keychain."
                         : "Screenshots are stored as unencrypted JPEG files.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }

            // Audit Log
            Section("Audit Log") {
                Toggle("Enable audit logging", isOn: $auditLogEnabled)

                if auditLogEnabled {
                    HStack {
                        Text("Total log entries:")
                            .font(.system(size: 12))
                        Spacer()
                        Text("\(auditEntryCount)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        Button("Export Audit Log") {
                            exportAuditLog()
                        }
                        .controlSize(.small)

                        if let exportedLogPath {
                            Button("Reveal in Finder") {
                                NSWorkspace.shared.selectFile(exportedLogPath, inFileViewerRootedAtPath: "")
                            }
                            .controlSize(.small)
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.blue)
                            .font(.system(size: 11))
                        Text("CSV log of all captured, skipped, redacted, and exported events.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Setup & Data
            Section("Setup") {
                Button {
                    hasCompletedOnboarding = false
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "onboarding")
                } label: {
                    Label("Run Setup Wizard Again", systemImage: "arrow.counterclockwise")
                }
            }

            Section("Danger Zone") {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete All Notes & Screenshots", systemImage: "trash.fill")
                }
                .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete Everything", role: .destructive) {
                        Task {
                            do {
                                let container = modelContext.container
                                let storageActor = StorageActor(modelContainer: container)
                                let count = try await storageActor.deleteAllNotes()
                                deleteMessage = "Deleted \(count) notes"
                                SMLogger.ui.info("User deleted all data: \(count) notes")
                            } catch {
                                deleteMessage = "Delete failed: \(error.localizedDescription)"
                                SMLogger.ui.error("Delete all failed: \(error.localizedDescription)")
                            }
                        }
                    }
                } message: {
                    Text("This will permanently delete all notes and screenshots from SwiftData. Obsidian vault files will not be affected.")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            screenCaptureGranted = CGPreflightScreenCaptureAccess()
            skipRules = SkipRuleEngine.loadRules()
            customPatterns = ContentRedactor.loadCustomPatterns()
            loadAuditStats()
        }
    }

    // MARK: - Actions

    private func exportAuditLog() {
        Task {
            let logger = AuditLogger()
            if let path = try? await logger.exportAllLogs() {
                exportedLogPath = path
            }
        }
    }

    private func loadAuditStats() {
        Task {
            let logger = AuditLogger()
            auditEntryCount = await logger.totalEntryCount()
        }
    }
}
