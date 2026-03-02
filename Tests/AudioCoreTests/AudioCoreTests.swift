import Foundation
import Testing
@testable import AudioCore

// MARK: - AudioTranscript Tests

@Test func audioTranscriptInitializesWithDefaults() {
    let transcript = AudioTranscript(text: "Hello world")
    #expect(transcript.text == "Hello world")
    #expect(transcript.speaker == nil)
    #expect(transcript.confidence == 0.8)
    #expect(transcript.language == "en-US")
    #expect(transcript.isMeeting == false)
    #expect(transcript.duration == 0)
}

@Test func audioTranscriptInitializesWithAllFields() {
    let date = Date(timeIntervalSince1970: 1000)
    let transcript = AudioTranscript(
        text: "Meeting notes",
        speaker: "John",
        startTime: date,
        duration: 60,
        confidence: 0.95,
        language: "en-GB",
        isMeeting: true
    )
    #expect(transcript.text == "Meeting notes")
    #expect(transcript.speaker == "John")
    #expect(transcript.startTime == date)
    #expect(transcript.duration == 60)
    #expect(transcript.confidence == 0.95)
    #expect(transcript.language == "en-GB")
    #expect(transcript.isMeeting == true)
}

// MARK: - VoiceMemo Tests

@Test func voiceMemoInitializesWithDefaults() {
    let memo = VoiceMemo(text: "Quick thought")
    #expect(memo.text == "Quick thought")
    #expect(memo.audioPath == nil)
    #expect(memo.duration == 0)
    #expect(memo.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
}

@Test func voiceMemoInitializesWithAllFields() {
    let id = UUID()
    let date = Date(timeIntervalSince1970: 2000)
    let memo = VoiceMemo(
        id: id,
        text: "Detailed memo",
        audioPath: "/path/to/audio.m4a",
        duration: 30,
        createdAt: date
    )
    #expect(memo.id == id)
    #expect(memo.text == "Detailed memo")
    #expect(memo.audioPath == "/path/to/audio.m4a")
    #expect(memo.duration == 30)
    #expect(memo.createdAt == date)
}

// MARK: - DetectedMeeting Tests

@Test func detectedMeetingInitializesWithDefaults() {
    let meeting = DetectedMeeting(title: "Sprint Planning")
    #expect(meeting.title == "Sprint Planning")
    #expect(meeting.attendees.isEmpty)
    #expect(meeting.endTime == nil)
    #expect(meeting.calendarEventID == nil)
    #expect(meeting.isActive == true)
}

@Test func detectedMeetingInitializesWithAllFields() {
    let start = Date(timeIntervalSince1970: 1000)
    let end = Date(timeIntervalSince1970: 4600)
    let meeting = DetectedMeeting(
        title: "Team Sync",
        attendees: ["Alice", "Bob"],
        startTime: start,
        endTime: end,
        calendarEventID: "cal-123",
        isActive: false
    )
    #expect(meeting.title == "Team Sync")
    #expect(meeting.attendees == ["Alice", "Bob"])
    #expect(meeting.startTime == start)
    #expect(meeting.endTime == end)
    #expect(meeting.calendarEventID == "cal-123")
    #expect(meeting.isActive == false)
}

// MARK: - AudioConfiguration Tests

@Test func audioConfigurationDefaults() {
    let config = AudioConfiguration()
    #expect(config.microphoneEnabled == false)
    #expect(config.systemAudioEnabled == false)
    #expect(config.language == "en-US")
    #expect(config.vadSensitivity == 0.5)
    #expect(config.voiceMemoMaxDuration == 60)
}

@Test func audioConfigurationCustomValues() {
    var config = AudioConfiguration(
        microphoneEnabled: true,
        systemAudioEnabled: true,
        language: "ja-JP",
        vadSensitivity: 0.8,
        voiceMemoMaxDuration: 120
    )
    #expect(config.microphoneEnabled == true)
    #expect(config.language == "ja-JP")
    #expect(config.voiceMemoMaxDuration == 120)

    // Test mutability
    config.microphoneEnabled = false
    #expect(config.microphoneEnabled == false)
}
