import Foundation
import UserNotifications
import Shared

/// Manages local notifications for note creation events.
public final class NotificationManager: NSObject, Sendable, UNUserNotificationCenterDelegate {

    public static let shared = NotificationManager()

    private override init() {
        super.init()
    }

    /// Request notification permissions.
    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
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

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                SMLogger.system.error("Notification failed: \(error.localizedDescription)")
            }
        }
    }

    /// Post a notification for daily summary.
    public func notifyDailySummary(noteCount: Int) {
        guard noteCount > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Daily Summary"
        content.body = "ScreenMind captured \(noteCount) notes today."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "daily-summary-\(Date().dateFolderName)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
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
