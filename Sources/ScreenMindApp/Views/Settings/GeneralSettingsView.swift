import SwiftUI
import Shared
import SystemIntegration

/// General settings — launch at login, Obsidian vault, storage.
struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("obsidianVaultPath") private var vaultPath = AppConstants.Obsidian.defaultVaultPath
    @AppStorage("retentionDays") private var retentionDays = AppConstants.Storage.retentionDays

    @State private var showFolderPicker = false

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

                    Button("Choose…") {
                        chooseFolder()
                    }
                    .controlSize(.small)
                }

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
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
        }
        .formStyle(.grouped)
        .padding()
    }

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
