import Foundation
import EventKit
import Shared

/// Detects when the user is in a meeting using calendar events and audio heuristics.
public actor MeetingDetectionActor {
    private let eventStore = EKEventStore()
    private var hasCalendarAccess = false
    private var currentMeeting: DetectedMeeting?

    public init() {}

    /// Request calendar access.
    public func requestAccess() async -> Bool {
        do {
            hasCalendarAccess = try await eventStore.requestFullAccessToEvents()
            SMLogger.system.info("Calendar access: \(self.hasCalendarAccess ? "granted" : "denied")")
            return hasCalendarAccess
        } catch {
            SMLogger.system.warning("Calendar access failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Check if the user is currently in a meeting based on calendar events.
    public func detectCurrentMeeting() -> DetectedMeeting? {
        guard hasCalendarAccess else { return nil }

        let now = Date()
        let calendars = eventStore.calendars(for: .event)

        // Look for events within 5 minutes of now
        let predicate = eventStore.predicateForEvents(
            withStart: now.addingTimeInterval(-300),
            end: now.addingTimeInterval(300),
            calendars: calendars
        )

        let events = eventStore.events(matching: predicate)

        // Find the closest active event
        for event in events {
            // Skip all-day events
            guard !event.isAllDay else { continue }

            // Check if we're within the event's time range
            if event.startDate <= now && (event.endDate ?? now) >= now {
                let attendees = event.attendees?.compactMap { $0.name ?? $0.url.absoluteString } ?? []

                let meeting = DetectedMeeting(
                    title: event.title ?? "Meeting",
                    attendees: attendees,
                    startTime: event.startDate,
                    endTime: event.endDate,
                    calendarEventID: event.eventIdentifier,
                    isActive: true
                )

                currentMeeting = meeting
                SMLogger.system.info("Meeting detected: \(meeting.title) with \(attendees.count) attendees")
                return meeting
            }
        }

        currentMeeting = nil
        return nil
    }

    /// Check if a specific app is a known meeting app.
    public static func isMeetingApp(_ bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        let meetingApps = [
            "us.zoom.xos",
            "com.microsoft.teams",
            "com.microsoft.teams2",
            "com.google.Chrome",  // Google Meet runs in browser
            "com.apple.FaceTime",
            "com.tinyspeck.slackmacgap", // Slack huddles
            "com.webex.meetingmanager",
            "com.discord.Discord",
        ]
        return meetingApps.contains(bundleID)
    }

    public var active: DetectedMeeting? { currentMeeting }
}
