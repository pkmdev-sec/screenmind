import Foundation
import UserNotifications
import Shared

/// Manages local notifications for note creation events.
public final class NotificationManager: NSObject, Sendable, UNUserNotificationCenterDelegate {

    public static let shared = NotificationManager()

    private override init() {
        super.init()
    }

    /// Whether notifications are available (requires app bundle with CFBundleIdentifier).
    private var isAvailable: Bool { Bundle.main.bundleIdentifier != nil }

    /// Safe accessor for UNUserNotificationCenter — returns nil in bare binary mode.
    /// Centralizes the guard so every call site is inherently safe.
    private var notificationCenter: UNUserNotificationCenter? {
        guard isAvailable else { return nil }
        return UNUserNotificationCenter.current()
    }

    /// Request notification permissions.
    /// Safe for non-bundle execution (SPM debug builds, Conductor).
    public func requestAuthorization() async -> Bool {
        // UNUserNotificationCenter.current() throws NSInternalInconsistencyException
        // when running as a bare binary without an app bundle. This ObjC exception
        // bypasses Swift do/catch and calls abort(), killing the entire process.
        guard let center = notificationCenter else {
            if Bundle.main.bundleURL.pathExtension == "app" {
                SMLogger.system.error("Notification center unavailable despite .app bundle — CFBundleIdentifier missing from Info.plist")
            } else {
                SMLogger.system.warning("Skipping notification auth — no bundle identifier (bare binary)")
            }
            return false
        }
        do {
            let granted = try await center
                .requestAuthorization(options: [.alert, .sound, .badge])
            SMLogger.system.info("Notification authorization: \(granted)")
            return granted
        } catch {
            SMLogger.system.error("Notification auth error: \(error.localizedDescription)")
            return false
        }
    }

    /// Post a notification when a new note is created.
    public func notifyNoteCreated(title: String, category: String) {
        guard let center = notificationCenter else { return }
        let content = UNMutableNotificationContent()
        content.title = "New Note"
        content.subtitle = title
        content.body = "Category: \(category.capitalized)"
        content.sound = .default
        content.categoryIdentifier = "NOTE_CREATED"

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error {
                SMLogger.system.error("Notification failed: \(error.localizedDescription)")
            }
        }
    }

    /// Post a notification for daily summary.
    public func notifyDailySummary(noteCount: Int) {
        guard let center = notificationCenter, noteCount > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Daily Summary"
        content.body = "ScreenMind captured \(noteCount) notes today."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "daily-summary-\(Date().dateFolderName)",
            content: content,
            trigger: nil
        )

        center.add(request)
    }

    // MARK: - UNUserNotificationCenterDelegate

    @MainActor
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
