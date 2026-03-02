import Foundation

/// Plugin manifest (plugin.json).
public struct PluginManifest: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let version: String
    public let author: String
    public let description: String
    public let main: String // "main.js"
    public let hooks: [String] // ["onNoteCreated", "onTimer"]
    public let permissions: [String] // ["network", "storage"]
    public let homepage: String?
    public let schedule: String?  // "every 30m", "every 2h", "every 1d"

    public init(id: String, name: String, version: String, author: String, description: String, main: String = "main.js", hooks: [String] = [], permissions: [String] = [], homepage: String? = nil, schedule: String? = nil) {
        self.id = id
        self.name = name
        self.version = version
        self.author = author
        self.description = description
        self.main = main
        self.hooks = hooks
        self.permissions = permissions
        self.homepage = homepage
        self.schedule = schedule
    }
}

/// Plugin lifecycle events.
public enum PluginEvent: Sendable {
    case noteCreated
    case noteSaved
    case noteExported
    case appStartup
    case appShutdown
    case timer

    public var hookName: String {
        switch self {
        case .noteCreated: return "onNoteCreated"
        case .noteSaved: return "onNoteSaved"
        case .noteExported: return "onNoteExported"
        case .appStartup: return "onAppStartup"
        case .appShutdown: return "onAppShutdown"
        case .timer: return "onTimer"
        }
    }

    public static var allHookNames: [String] {
        ["onNoteCreated", "onNoteSaved", "onNoteExported", "onAppStartup", "onAppShutdown", "onTimer"]
    }
}

/// Plugin listing from the store registry.
public struct PluginListing: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let author: String
    public let description: String
    public let version: String
    public let downloadURL: String
    public let homepage: String?
    public let downloads: Int?

    public init(id: String, name: String, author: String, description: String, version: String, downloadURL: String, homepage: String? = nil, downloads: Int? = nil) {
        self.id = id
        self.name = name
        self.author = author
        self.description = description
        self.version = version
        self.downloadURL = downloadURL
        self.homepage = homepage
        self.downloads = downloads
    }
}

/// Plugin registry (fetched from GitHub).
public struct PluginRegistry: Codable, Sendable {
    public let plugins: [PluginListing]
}
