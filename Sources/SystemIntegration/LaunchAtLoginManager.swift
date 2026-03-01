import Foundation
import ServiceManagement
import Shared

/// Manages Launch at Login using SMAppService (macOS 13+).
public struct LaunchAtLoginManager: Sendable {

    public init() {}

    /// Whether the app is registered to launch at login.
    public var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Enable launch at login.
    public func enable() throws {
        try SMAppService.mainApp.register()
        SMLogger.system.info("Launch at login enabled")
    }

    /// Disable launch at login.
    public func disable() throws {
        try SMAppService.mainApp.unregister()
        SMLogger.system.info("Launch at login disabled")
    }

    /// Toggle launch at login.
    public func toggle() throws {
        if isEnabled {
            try disable()
        } else {
            try enable()
        }
    }
}
