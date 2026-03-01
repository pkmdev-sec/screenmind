import Foundation
import CoreGraphics
import Shared

/// Manages screen recording and other system permissions.
public enum PermissionsManager {

    public enum PermissionStatus: Sendable {
        case granted
        case denied
        case notDetermined
    }

    /// Check current screen recording permission status.
    public static func screenCaptureStatus() -> PermissionStatus {
        if CGPreflightScreenCaptureAccess() {
            return .granted
        }
        return .notDetermined
    }

    /// Request screen recording permission (shows system dialog).
    @discardableResult
    public static func requestScreenCapture() -> Bool {
        CGRequestScreenCaptureAccess()
    }
}
