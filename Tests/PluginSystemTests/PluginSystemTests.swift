import Foundation
import Testing
@testable import PluginSystem

// MARK: - PluginManifest Tests

@Test func pluginManifestInitializesWithDefaults() {
    let manifest = PluginManifest(
        id: "test-plugin",
        name: "Test Plugin",
        version: "1.0.0",
        author: "Test Author",
        description: "A test plugin"
    )
    #expect(manifest.id == "test-plugin")
    #expect(manifest.name == "Test Plugin")
    #expect(manifest.version == "1.0.0")
    #expect(manifest.author == "Test Author")
    #expect(manifest.description == "A test plugin")
    #expect(manifest.main == "main.js")
    #expect(manifest.hooks.isEmpty)
    #expect(manifest.permissions.isEmpty)
    #expect(manifest.homepage == nil)
}

@Test func pluginManifestInitializesWithAllFields() {
    let manifest = PluginManifest(
        id: "full-plugin",
        name: "Full Plugin",
        version: "2.0.0",
        author: "Dev",
        description: "Full featured",
        main: "index.js",
        hooks: ["onNoteCreated", "onTimer"],
        permissions: ["network"],
        homepage: "https://example.com"
    )
    #expect(manifest.main == "index.js")
    #expect(manifest.hooks.count == 2)
    #expect(manifest.permissions == ["network"])
    #expect(manifest.homepage == "https://example.com")
}

@Test func pluginManifestJSONRoundTrip() throws {
    let original = PluginManifest(
        id: "roundtrip",
        name: "RoundTrip",
        version: "1.0.0",
        author: "Test",
        description: "Test roundtrip",
        hooks: ["onNoteCreated"],
        permissions: ["network"]
    )

    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(PluginManifest.self, from: data)

    #expect(decoded.id == original.id)
    #expect(decoded.name == original.name)
    #expect(decoded.version == original.version)
    #expect(decoded.hooks == original.hooks)
    #expect(decoded.permissions == original.permissions)
}

@Test func pluginManifestDecodesFromJSON() throws {
    let json = """
    {
        "id": "json-plugin",
        "name": "JSON Plugin",
        "version": "1.0.0",
        "author": "Tester",
        "description": "From JSON",
        "main": "main.js",
        "hooks": ["onAppStartup"],
        "permissions": []
    }
    """
    let manifest = try JSONDecoder().decode(PluginManifest.self, from: json.data(using: .utf8)!)
    #expect(manifest.id == "json-plugin")
    #expect(manifest.hooks == ["onAppStartup"])
}

// MARK: - PluginEvent Tests

@Test func pluginEventHookNames() {
    #expect(PluginEvent.noteCreated.hookName == "onNoteCreated")
    #expect(PluginEvent.noteSaved.hookName == "onNoteSaved")
    #expect(PluginEvent.noteExported.hookName == "onNoteExported")
    #expect(PluginEvent.appStartup.hookName == "onAppStartup")
    #expect(PluginEvent.appShutdown.hookName == "onAppShutdown")
    #expect(PluginEvent.timer.hookName == "onTimer")
}

@Test func pluginEventAllHookNames() {
    let allNames = PluginEvent.allHookNames
    #expect(allNames.count == 6)
    #expect(allNames.contains("onNoteCreated"))
    #expect(allNames.contains("onTimer"))
}

// MARK: - PluginListing Tests

@Test func pluginListingInitializes() {
    let listing = PluginListing(
        id: "store-plugin",
        name: "Store Plugin",
        author: "Author",
        description: "Description",
        version: "1.0.0",
        downloadURL: "https://example.com/plugin.zip"
    )
    #expect(listing.id == "store-plugin")
    #expect(listing.downloadURL == "https://example.com/plugin.zip")
    #expect(listing.homepage == nil)
    #expect(listing.downloads == nil)
}

@Test func pluginListingJSONRoundTrip() throws {
    let original = PluginListing(
        id: "test",
        name: "Test",
        author: "Author",
        description: "Desc",
        version: "1.0.0",
        downloadURL: "https://example.com",
        homepage: "https://home.com",
        downloads: 42
    )
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(PluginListing.self, from: data)
    #expect(decoded.id == original.id)
    #expect(decoded.downloads == 42)
    #expect(decoded.homepage == "https://home.com")
}

// MARK: - PluginRegistry Tests

@Test func pluginRegistryDecodesFromJSON() throws {
    let json = """
    {
        "plugins": [
            {
                "id": "plugin-1",
                "name": "Plugin 1",
                "author": "Dev",
                "description": "First",
                "version": "1.0.0",
                "downloadURL": "https://example.com/1.zip"
            },
            {
                "id": "plugin-2",
                "name": "Plugin 2",
                "author": "Dev",
                "description": "Second",
                "version": "2.0.0",
                "downloadURL": "https://example.com/2.zip"
            }
        ]
    }
    """
    let registry = try JSONDecoder().decode(PluginRegistry.self, from: json.data(using: .utf8)!)
    #expect(registry.plugins.count == 2)
    #expect(registry.plugins[0].id == "plugin-1")
    #expect(registry.plugins[1].version == "2.0.0")
}
