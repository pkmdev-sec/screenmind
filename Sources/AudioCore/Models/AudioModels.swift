import Foundation

/// Audio segment with transcription.
public struct AudioTranscript: Sendable {
    public let text: String
    public let speaker: String?
    public let startTime: Date
    public let duration: TimeInterval
    public let confidence: Double
    public let language: String
    public let isMeeting: Bool

    public init(text: String, speaker: String? = nil, startTime: Date = .now, duration: TimeInterval = 0, confidence: Double = 0.8, language: String = "en-US", isMeeting: Bool = false) {
        self.text = text
        self.speaker = speaker
        self.startTime = startTime
        self.duration = duration
        self.confidence = confidence
        self.language = language
        self.isMeeting = isMeeting
    }
}

/// Voice memo recording.
public struct VoiceMemo: Sendable {
    public let id: UUID
    public let text: String
    public let audioPath: String?
    public let duration: TimeInterval
    public let createdAt: Date

    public init(id: UUID = UUID(), text: String, audioPath: String? = nil, duration: TimeInterval = 0, createdAt: Date = .now) {
        self.id = id
        self.text = text
        self.audioPath = audioPath
        self.duration = duration
        self.createdAt = createdAt
    }
}

/// Detected meeting info.
public struct DetectedMeeting: Sendable {
    public let title: String
    public let attendees: [String]
    public let startTime: Date
    public let endTime: Date?
    public let calendarEventID: String?
    public let isActive: Bool

    public init(title: String, attendees: [String] = [], startTime: Date = .now, endTime: Date? = nil, calendarEventID: String? = nil, isActive: Bool = true) {
        self.title = title
        self.attendees = attendees
        self.startTime = startTime
        self.endTime = endTime
        self.calendarEventID = calendarEventID
        self.isActive = isActive
    }
}

/// Audio capture configuration.
public struct AudioConfiguration: Sendable {
    public var microphoneEnabled: Bool
    public var systemAudioEnabled: Bool
    public var language: String
    public var vadSensitivity: Double // 0.0 (sensitive) to 1.0 (aggressive filter)
    public var voiceMemoMaxDuration: TimeInterval

    public init(
        microphoneEnabled: Bool = false,
        systemAudioEnabled: Bool = false,
        language: String = "en-US",
        vadSensitivity: Double = 0.5,
        voiceMemoMaxDuration: TimeInterval = 60
    ) {
        self.microphoneEnabled = microphoneEnabled
        self.systemAudioEnabled = systemAudioEnabled
        self.language = language
        self.vadSensitivity = vadSensitivity
        self.voiceMemoMaxDuration = voiceMemoMaxDuration
    }
}
