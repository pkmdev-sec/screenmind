import SwiftUI
import Shared
import AudioCore

/// Audio settings — microphone, system audio, speech recognition, meeting detection.
struct AudioSettingsView: View {
    @AppStorage("audioMicrophoneEnabled") private var micEnabled = false
    @AppStorage("audioSystemEnabled") private var systemAudioEnabled = false
    @AppStorage("audioLanguage") private var language = "en-US"
    @AppStorage("audioVADSensitivity") private var vadSensitivity = 0.5
    @AppStorage("audioMeetingDetection") private var meetingDetection = true
    @AppStorage("audioVoiceMemoMaxDuration") private var memoMaxDuration = 60.0
    @AppStorage("audioSTTEngine") private var sttEngine = "appleSpeech"
    @AppStorage("audioWhisperEndpoint") private var whisperEndpoint = ""
    @AppStorage("audioWhisperAPIKey") private var whisperAPIKey = ""
    @AppStorage("audioBatchMode") private var batchMode = false

    private let languages = [
        ("en-US", "English (US)"),
        ("en-GB", "English (UK)"),
        ("es-ES", "Spanish"),
        ("fr-FR", "French"),
        ("de-DE", "German"),
        ("ja-JP", "Japanese"),
        ("zh-CN", "Chinese (Simplified)"),
        ("ko-KR", "Korean"),
        ("pt-BR", "Portuguese (Brazil)"),
        ("hi-IN", "Hindi"),
    ]

    var body: some View {
        Form {
            // Audio Sources
            Section("Audio Sources") {
                Toggle("Microphone", isOn: $micEnabled)
                    .help("Capture audio from the default microphone")
                Toggle("System Audio", isOn: $systemAudioEnabled)
                    .help("Capture what you hear (Zoom, Meet, media playback)")

                if systemAudioEnabled {
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundStyle(.blue)
                            .font(.system(size: 12))
                        Text("System audio capture requires Screen Recording permission.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 2)
                }
            }

            Section("Speech-to-Text Engine") {
                Picker("Primary Engine", selection: $sttEngine) {
                    Text("Apple Speech (on-device)").tag("appleSpeech")
                    Text("Whisper API (cloud)").tag("whisperAPI")
                }

                if sttEngine == "whisperAPI" {
                    TextField("Whisper Endpoint", text: $whisperEndpoint)
                        .textFieldStyle(.roundedBorder)
                    SecureField("API Key", text: $whisperAPIKey)
                        .textFieldStyle(.roundedBorder)
                } else {
                    Picker("Language", selection: $language) {
                        ForEach(languages, id: \.0) { code, name in
                            Text(name).tag(code)
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                            .foregroundStyle(.purple)
                            .font(.system(size: 12))
                        Text("Uses Apple's on-device speech recognition. No internet required. Supports 50+ languages.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Voice Activity Detection") {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("VAD Sensitivity:")
                        Spacer()
                        Text(String(format: "%.0f%%", vadSensitivity * 100))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $vadSensitivity, in: 0.1...0.9, step: 0.1)
                    HStack {
                        Text("More sensitive")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                        Spacer()
                        Text("Less sensitive")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                        .font(.system(size: 11))
                    Text("Voice Activity Detection filters silence. Higher sensitivity captures more, lower reduces noise.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Section("Meeting Mode") {
                Toggle("Batch Transcription", isOn: $batchMode)
                    .help("Buffer audio during meetings and transcribe as a batch when the meeting ends")

                if batchMode {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform.badge.magnifyingglass")
                            .foregroundStyle(.orange)
                            .font(.system(size: 12))
                        Text("Audio is buffered during detected meetings and transcribed in one batch for better context and accuracy.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 2)
                }
            }

            Section("Voice Memos") {
                HStack {
                    Text("Max duration:")
                    Spacer()
                    Stepper("\(Int(memoMaxDuration))s", value: $memoMaxDuration, in: 10...300, step: 10)
                        .frame(width: 120)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 11))
                        Text("Cmd+Opt+Shift+V")
                            .font(.system(size: 11, design: .monospaced))
                        Text("— Start/stop voice memo")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Text("Records microphone, transcribes on-device, and saves as a note.")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }

            Section("Meeting Detection") {
                Toggle("Auto-detect meetings from calendar", isOn: $meetingDetection)

                if meetingDetection {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.orange)
                            .font(.system(size: 12))
                        Text("Checks your calendar for active meetings. Notes generated during meetings are tagged with meeting title and attendees.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 2)

                    HStack(spacing: 6) {
                        Image(systemName: "app.badge.checkmark")
                            .foregroundStyle(.green)
                            .font(.system(size: 11))
                        Text("Detects: Zoom, Teams, Google Meet, FaceTime, Slack Huddles, Discord, WebEx")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
