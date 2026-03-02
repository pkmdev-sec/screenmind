import Foundation
import JavaScriptCore
import Shared

/// JavaScriptCore-based plugin execution engine.
public actor PluginEngine {
    public static let shared = PluginEngine()

    private var loadedPlugins: [LoadedPlugin] = []
    private let pluginsDirectory: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.pluginsDirectory = appSupport
            .appendingPathComponent(AppConstants.bundleIdentifier)
            .appendingPathComponent("Plugins")
        try? FileManager.default.createDirectory(at: pluginsDirectory, withIntermediateDirectories: true)
    }

    /// Load all plugins from the plugins directory.
    public func loadAllPlugins() async {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: pluginsDirectory,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) else { return }

        for dir in contents {
            guard (try? dir.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else { continue }
            do {
                try await loadPlugin(from: dir.path)
            } catch {
                SMLogger.system.warning("Plugin load failed at \(dir.lastPathComponent): \(error.localizedDescription)")
            }
        }
        SMLogger.system.info("Loaded \(self.loadedPlugins.count) plugin(s)")
    }

    /// Load a single plugin from a directory.
    public func loadPlugin(from path: String) async throws {
        let manifestURL = URL(fileURLWithPath: path).appendingPathComponent("plugin.json")
        let manifestData = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(PluginManifest.self, from: manifestData)

        // Check if already loaded
        guard !loadedPlugins.contains(where: { $0.manifest.id == manifest.id }) else { return }

        let scriptURL = URL(fileURLWithPath: path).appendingPathComponent(manifest.main)
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        // Create sandboxed JSContext
        let context = JSContext()!
        context.exceptionHandler = { _, exception in
            SMLogger.system.error("Plugin JS error [\(manifest.name)]: \(exception?.toString() ?? "unknown")")
        }

        // Inject safe APIs (no file system, no process)
        injectSafeAPIs(into: context, manifest: manifest)

        // Execute plugin script
        context.evaluateScript(script)

        let plugin = LoadedPlugin(manifest: manifest, context: context, path: path)
        loadedPlugins.append(plugin)
        SMLogger.system.info("Plugin loaded: \(manifest.name) v\(manifest.version)")
    }

    /// Trigger an event on all plugins that subscribe to it.
    public func trigger(event: PluginEvent, data: [String: Any]) {
        for plugin in loadedPlugins where plugin.manifest.hooks.contains(event.hookName) {
            let handler = plugin.context.objectForKeyedSubscript(event.hookName)
            let jsData = plugin.context.objectForKeyedSubscript("JSON")?.invokeMethod("parse", withArguments: [
                (try? JSONSerialization.data(withJSONObject: data)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
            ])
            handler?.call(withArguments: [jsData as Any])
        }
    }

    /// List all loaded plugins.
    public var plugins: [PluginManifest] { loadedPlugins.map(\.manifest) }

    /// Unload a plugin by ID.
    public func unloadPlugin(id: String) {
        loadedPlugins.removeAll { $0.manifest.id == id }
    }

    /// Get the plugins directory path.
    public var directory: URL { pluginsDirectory }

    // MARK: - Storage Closures

    /// Storage closures that can be injected by the app (to avoid circular dependencies)
    public var getNoteCountClosure: (@Sendable () async throws -> Int)?

    // MARK: - Sandboxing

    private func injectSafeAPIs(into context: JSContext, manifest: PluginManifest) {
        // Console.log
        let logBlock: @convention(block) (String) -> Void = { message in
            SMLogger.system.info("Plugin [\(manifest.name)]: \(message)")
        }
        context.setObject(logBlock, forKeyedSubscript: "log" as NSString)

        // Fetch (network access — only if permitted)
        if manifest.permissions.contains("network") {
            let fetchBlock: @convention(block) (String, JSValue?) -> JSValue = { urlString, options in
                let promise = JSValue(newPromiseIn: context) { resolve, reject in
                    guard let url = URL(string: urlString) else {
                        reject?.call(withArguments: ["Invalid URL"])
                        return
                    }

                    // Security: enforce HTTPS or explicit localhost HTTP
                    if url.scheme != "https" && !(url.scheme == "http" && (url.host == "localhost" || url.host == "127.0.0.1")) {
                        reject?.call(withArguments: ["Only HTTPS URLs are allowed (or HTTP to localhost)"])
                        return
                    }

                    var request = URLRequest(url: url)
                    request.timeoutInterval = 10 // 10 second timeout

                    if let method = options?.objectForKeyedSubscript("method")?.toString() {
                        request.httpMethod = method
                    }
                    if let headers = options?.objectForKeyedSubscript("headers")?.toDictionary() as? [String: String] {
                        for (key, value) in headers {
                            request.setValue(value, forHTTPHeaderField: key)
                        }
                    }
                    if let body = options?.objectForKeyedSubscript("body")?.toString() {
                        request.httpBody = body.data(using: .utf8)
                    }

                    URLSession.shared.dataTask(with: request) { data, response, error in
                        if let error {
                            reject?.call(withArguments: [error.localizedDescription])
                        } else if let data {
                            // Security: enforce 10MB response size limit
                            if data.count > 10 * 1024 * 1024 {
                                reject?.call(withArguments: ["Response size exceeds 10MB limit"])
                                return
                            }
                            if let text = String(data: data, encoding: .utf8) {
                                resolve?.call(withArguments: [text])
                            } else {
                                reject?.call(withArguments: ["Response not valid UTF-8"])
                            }
                        }
                    }.resume()
                }
                return promise!
            }
            context.setObject(fetchBlock, forKeyedSubscript: "fetch" as NSString)
        }

        // getEnv (read environment variables for plugin config)
        let getEnvBlock: @convention(block) (String) -> String? = { key in
            UserDefaults.standard.string(forKey: "plugin.\(manifest.id).\(key)")
        }
        context.setObject(getEnvBlock, forKeyedSubscript: "getEnv" as NSString)

        // Storage APIs (only if permitted)
        if manifest.permissions.contains("storage") {
            // getNoteCount — returns total note count
            let getNoteCountBlock: @convention(block) () -> JSValue = {
                let promise = JSValue(newPromiseIn: context) { [weak self] resolve, reject in
                    Task {
                        do {
                            guard let self, let closure = await self.getNoteCountClosure else {
                                reject?.call(withArguments: ["Storage not available"])
                                return
                            }
                            let count = try await closure()
                            resolve?.call(withArguments: [count])
                        } catch {
                            reject?.call(withArguments: [error.localizedDescription])
                        }
                    }
                }
                return promise!
            }
            context.setObject(getNoteCountBlock, forKeyedSubscript: "getNoteCount" as NSString)
        }
    }
}

/// A loaded plugin instance.
struct LoadedPlugin {
    let manifest: PluginManifest
    let context: JSContext
    let path: String
}
