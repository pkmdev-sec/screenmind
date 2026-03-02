import SwiftUI
import Shared
import PluginSystem

/// Plugin management settings — view installed, enable/disable, browse store.
struct PluginSettingsView: View {
    @State private var installedPlugins: [PluginManifest] = []
    @State private var isLoading = true

    var body: some View {
        Form {
            Section("Installed Plugins") {
                if isLoading {
                    ProgressView("Loading plugins...")
                        .controlSize(.small)
                } else if installedPlugins.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "puzzlepiece.extension")
                            .font(.system(size: 24))
                            .foregroundStyle(.tertiary)
                        Text("No plugins installed")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text("Plugins extend ScreenMind with custom exporters, integrations, and automations.")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                } else {
                    ForEach(installedPlugins) { plugin in
                        HStack(spacing: 10) {
                            Image(systemName: "puzzlepiece.extension.fill")
                                .foregroundStyle(.purple)
                                .font(.system(size: 16))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(plugin.name)
                                    .font(.system(size: 13, weight: .medium))
                                Text(plugin.description)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                HStack(spacing: 8) {
                                    Text("v\(plugin.version)")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(.tertiary)
                                    Text("by \(plugin.author)")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.tertiary)
                                    ForEach(plugin.hooks, id: \.self) { hook in
                                        Text(hook)
                                            .font(.system(size: 9, design: .monospaced))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(.quaternary, in: Capsule())
                                    }
                                }
                            }
                            Spacer()
                            Button(role: .destructive) {
                                Task {
                                    await PluginEngine.shared.unloadPlugin(id: plugin.id)
                                    await loadPlugins()
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Section("Plugin Directory") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Plugins Folder")
                            .font(.system(size: 12, weight: .medium))
                        Text("~/Library/Application Support/\(AppConstants.bundleIdentifier)/Plugins/")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                    Button("Open in Finder") {
                        Task {
                            let dir = await PluginEngine.shared.directory
                            NSWorkspace.shared.open(dir)
                        }
                    }
                    .controlSize(.small)
                }

                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                        .font(.system(size: 11))
                    Text("Drop plugin folders here. Each plugin needs a plugin.json manifest and a main.js entry point.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Section("MCP Server (Claude Desktop / Cursor)") {
                HStack(spacing: 6) {
                    Image(systemName: "network")
                        .foregroundStyle(.purple)
                        .font(.system(size: 12))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MCP Server")
                            .font(.system(size: 12, weight: .medium))
                        Text("Exposes ScreenMind notes as tools for Claude Desktop and Cursor.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Claude Desktop config:")
                        .font(.system(size: 11, weight: .medium))
                    Text("""
                    {
                      "mcpServers": {
                        "screenmind": {
                          "url": "http://127.0.0.1:9877"
                        }
                      }
                    }
                    """)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }

            Section("Plugin Development") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Create a Plugin")
                        .font(.system(size: 12, weight: .medium))
                    Text("""
                    1. Create a folder in the Plugins directory
                    2. Add plugin.json with name, hooks, and permissions
                    3. Add main.js with hook functions (onNoteCreated, etc.)
                    4. Restart ScreenMind to load
                    """)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Available hooks:")
                        .font(.system(size: 11, weight: .medium))
                    HStack(spacing: 6) {
                        ForEach(PluginEvent.allHookNames, id: \.self) { hook in
                            Text(hook)
                                .font(.system(size: 9, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.purple.opacity(0.1))
                                .foregroundStyle(.purple)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .task { await loadPlugins() }
    }

    private func loadPlugins() async {
        isLoading = true
        installedPlugins = await PluginEngine.shared.plugins
        isLoading = false
    }
}
