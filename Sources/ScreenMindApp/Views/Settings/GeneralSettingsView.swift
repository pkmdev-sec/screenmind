import SwiftUI
import SwiftData
import Shared
import StorageCore
import SystemIntegration

/// General settings — launch at login, Obsidian vault, storage, disk usage.
struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("obsidianVaultPath") private var vaultPath = AppConstants.Obsidian.defaultVaultPath
    @AppStorage("retentionDays") private var retentionDays = AppConstants.Storage.retentionDays
    @AppStorage("apiServerEnabled") private var apiServerEnabled = false

    @Environment(\.modelContext) private var modelContext

    @State private var vaultStatus: VaultValidationStatus = .unknown
    @State private var diskUsageBytes: Int64 = 0
    @State private var noteCount: Int = 0

    enum VaultValidationStatus {
        case unknown
        case valid
        case notWritable
        case notFound

        var icon: String {
            switch self {
            case .unknown: return "questionmark.circle"
            case .valid: return "checkmark.circle.fill"
            case .notWritable: return "exclamationmark.triangle.fill"
            case .notFound: return "xmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .unknown: return .secondary
            case .valid: return .green
            case .notWritable: return .orange
            case .notFound: return .red
            }
        }

        var message: String {
            switch self {
            case .unknown: return "Checking vault..."
            case .valid: return "Vault accessible and writable"
            case .notWritable: return "Vault exists but is not writable"
            case .notFound: return "Vault path does not exist"
            }
        }
    }

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch ScreenMind at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        let manager = LaunchAtLoginManager()
                        try? newValue ? manager.enable() : manager.disable()
                    }
            }

            Section("Obsidian Vault") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Vault Path")
                            .font(.system(size: 12, weight: .medium))
                        Text(vaultPath)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()

                    Button("Choose...") {
                        chooseFolder()
                    }
                    .controlSize(.small)
                }

                // Validation status
                HStack(spacing: 6) {
                    Image(systemName: vaultStatus.icon)
                        .foregroundStyle(vaultStatus.color)
                        .font(.system(size: 12))
                    Text(vaultStatus.message)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    if vaultStatus == .notFound {
                        Button("Create Folder") {
                            createVaultFolder()
                        }
                        .controlSize(.mini)
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                        .font(.system(size: 12))
                    Text("Notes saved to \(AppConstants.Obsidian.subfolder)/ subfolder")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Section("Data Retention") {
                HStack {
                    Text("Keep notes for")
                    Stepper("\(retentionDays) days", value: $retentionDays, in: 7...365, step: 7)
                }

                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                        .font(.system(size: 12))
                    Text("Older notes are automatically deleted from SwiftData. Obsidian files are kept.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Section("Storage Usage") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Screenshots on disk")
                            .font(.system(size: 12, weight: .medium))
                        Text(formatBytes(diskUsageBytes))
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            .foregroundStyle(diskUsageColor)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Total notes")
                            .font(.system(size: 12, weight: .medium))
                        Text("\(noteCount)")
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(4)

                // Quota bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.quaternary)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(diskUsageColor)
                            .frame(width: geo.size.width * diskUsageRatio, height: 8)
                            .animation(.easeOut(duration: 0.6), value: diskUsageBytes)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("Used \(formatBytes(diskUsageBytes)) of \(formatBytes(AppConstants.Storage.quotaBytes))")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("\(Int(diskUsageRatio * 100))%")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }

            Section("Developer API") {
                Toggle("Enable local REST API (port 9876)", isOn: $apiServerEnabled)

                HStack(spacing: 6) {
                    Image(systemName: "network")
                        .foregroundStyle(.blue)
                        .font(.system(size: 12))
                    Text("Exposes http://127.0.0.1:9876/api/ for Alfred, Raycast, Shortcuts, and scripts. Localhost only.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                if apiServerEnabled {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Endpoints:")
                            .font(.system(size: 11, weight: .medium))
                        Text("""
                        GET /api/notes?q=search&limit=20
                        GET /api/notes/today
                        GET /api/stats
                        GET /api/apps
                        GET /api/health
                        """)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }

            Section("Defaults") {
                Button("Restore Default Settings") {
                    restoreDefaults()
                }
                .controlSize(.small)

                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 11))
                    Text("Resets capture intervals, detection threshold, and vault path to defaults. Does not delete notes.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            validateVault()
            loadStorageStats()
        }
        .onChange(of: vaultPath) { _, _ in
            validateVault()
        }
    }

    // MARK: - Vault Validation

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

    private func createVaultFolder() {
        let expanded = (vaultPath as NSString).expandingTildeInPath
        try? FileManager.default.createDirectory(atPath: expanded, withIntermediateDirectories: true)
        validateVault()
    }

    // MARK: - Storage Stats

    private func loadStorageStats() {
        Task {
            let storageActor = StorageActor(modelContainer: modelContext.container)
            do {
                diskUsageBytes = try await storageActor.screenshotDiskUsage()
                noteCount = try await storageActor.noteCount()
            } catch {
                SMLogger.ui.error("Failed to load storage stats: \(error.localizedDescription)")
            }
        }
    }

    private var diskUsageRatio: CGFloat {
        let ratio = CGFloat(diskUsageBytes) / CGFloat(AppConstants.Storage.quotaBytes)
        return min(max(ratio, 0), 1)
    }

    private var diskUsageColor: Color {
        switch diskUsageRatio {
        case 0..<0.6: return .green
        case 0.6..<0.85: return .orange
        default: return .red
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Restore Defaults

    private func restoreDefaults() {
        vaultPath = AppConstants.Obsidian.defaultVaultPath
        retentionDays = AppConstants.Storage.retentionDays
        UserDefaults.standard.set(AppConstants.Capture.activeInterval, forKey: "captureActiveInterval")
        UserDefaults.standard.set(AppConstants.Capture.idleInterval, forKey: "captureIdleInterval")
        UserDefaults.standard.set(AppConstants.Detection.defaultThreshold, forKey: "detectionThreshold")
        validateVault()
    }

    // MARK: - Folder Picker

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Vault"
        panel.message = "Choose your Obsidian vault folder"

        if panel.runModal() == .OK, let url = panel.url {
            vaultPath = url.path
        }
    }
}
