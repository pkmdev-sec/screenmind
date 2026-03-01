import SwiftUI
import Shared
import StorageCore

/// Export settings — enable/disable exporters, configure paths and webhooks.
struct ExportSettingsView: View {
    // Obsidian is enabled by default
    @AppStorage("exporter_Obsidian Markdown_enabled") private var obsidianEnabled = true
    @AppStorage("exporter_JSON_enabled") private var jsonEnabled = false
    @AppStorage("exporter_Flat Markdown_enabled") private var flatMarkdownEnabled = false
    @AppStorage("exporter_Webhook_enabled") private var webhookEnabled = false

    @AppStorage("exportJsonPath") private var jsonPath = ""
    @AppStorage("exportMarkdownPath") private var markdownPath = ""
    @AppStorage("exportWebhookURL") private var webhookURL = ""

    var body: some View {
        Form {
            Section("Active Exporters") {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                        .font(.system(size: 12))
                    Text("Notes are exported to all enabled formats after AI processing.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                // Obsidian
                exporterToggle(
                    type: .obsidian,
                    isEnabled: $obsidianEnabled
                )

                // JSON
                exporterToggle(
                    type: .json,
                    isEnabled: $jsonEnabled
                )

                // Flat Markdown
                exporterToggle(
                    type: .flatMarkdown,
                    isEnabled: $flatMarkdownEnabled
                )

                // Webhook
                exporterToggle(
                    type: .webhook,
                    isEnabled: $webhookEnabled
                )
            }

            // JSON Config
            if jsonEnabled {
                Section("JSON Export") {
                    pathPicker(label: "Output Directory", path: $jsonPath, defaultPath: defaultJSONPath)

                    HStack(spacing: 6) {
                        Image(systemName: "curlybraces")
                            .foregroundStyle(.orange)
                            .font(.system(size: 11))
                        Text("One .json file per note with all metadata. Great for data analysis scripts.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Flat Markdown Config
            if flatMarkdownEnabled {
                Section("Flat Markdown Export") {
                    pathPicker(label: "Output Directory", path: $markdownPath, defaultPath: defaultMarkdownPath)

                    HStack(spacing: 6) {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.blue)
                            .font(.system(size: 11))
                        Text("Simple .md files without frontmatter. Works with any Markdown editor.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Webhook Config
            if webhookEnabled {
                Section("Webhook") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("URL:")
                                .font(.system(size: 12))
                            TextField("https://hooks.example.com/endpoint", text: $webhookURL)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11, design: .monospaced))
                        }

                        if !webhookURL.isEmpty {
                            webhookValidation
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.forward.app")
                            .foregroundStyle(.purple)
                            .font(.system(size: 11))
                        Text("POSTs note JSON to the URL. Works with Zapier, Make.com, n8n, or any webhook receiver.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Summary
            Section("Export Summary") {
                let enabledCount = [obsidianEnabled, jsonEnabled, flatMarkdownEnabled, webhookEnabled].filter { $0 }.count
                HStack {
                    Text("\(enabledCount) exporter\(enabledCount == 1 ? "" : "s") active")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    if enabledCount == 0 {
                        Label("Notes stored in SwiftData only", systemImage: "exclamationmark.triangle")
                            .font(.system(size: 11))
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Components

    private func exporterToggle(type: ExporterType, isEnabled: Binding<Bool>) -> some View {
        Toggle(isOn: isEnabled) {
            HStack(spacing: 8) {
                Image(systemName: type.iconName)
                    .foregroundStyle(isEnabled.wrappedValue ? .primary : .tertiary)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 1) {
                    Text(type.rawValue)
                        .font(.system(size: 12, weight: .medium))
                    Text(type.subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func pathPicker(label: String, path: Binding<String>, defaultPath: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                Text(path.wrappedValue.isEmpty ? defaultPath : path.wrappedValue)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Button("Choose...") {
                let panel = NSOpenPanel()
                panel.canChooseDirectories = true
                panel.canChooseFiles = false
                if panel.runModal() == .OK, let url = panel.url {
                    path.wrappedValue = url.path
                }
            }
            .controlSize(.small)
        }
    }

    @ViewBuilder
    private var webhookValidation: some View {
        if URL(string: webhookURL) != nil, webhookURL.hasPrefix("http") {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 11))
                Text("Valid URL")
                    .font(.system(size: 10))
                    .foregroundStyle(.green)
            }
        } else {
            HStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.system(size: 11))
                Text("Invalid URL — must start with http:// or https://")
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Defaults

    private var defaultJSONPath: String {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        return desktop.appendingPathComponent("ScreenMind-Export/JSON").path
    }

    private var defaultMarkdownPath: String {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        return desktop.appendingPathComponent("ScreenMind-Export/Markdown").path
    }
}
