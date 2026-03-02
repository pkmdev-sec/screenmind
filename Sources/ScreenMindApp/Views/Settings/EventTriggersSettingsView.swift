import SwiftUI

struct EventTriggersSettingsView: View {
    @AppStorage("eventDrivenCaptureEnabled") private var eventDrivenEnabled = true
    @AppStorage("captureOnAppSwitch") private var onAppSwitch = true
    @AppStorage("captureOnWindowFocus") private var onWindowFocus = true
    @AppStorage("captureOnTypingPause") private var onTypingPause = true
    @AppStorage("captureOnScrollStop") private var onScrollStop = true
    @AppStorage("captureOnClipboard") private var onClipboard = false
    @AppStorage("idleFallbackSeconds") private var idleFallback = 30

    var body: some View {
        Form {
            Section("Capture Mode") {
                Toggle("Event-Driven Capture", isOn: $eventDrivenEnabled)
                    .help("Capture on meaningful events instead of fixed timer intervals")

                if !eventDrivenEnabled {
                    Text("Using timer-based capture (5s active / 30s idle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Event Triggers") {
                Toggle("App Switch", isOn: $onAppSwitch)
                    .help("Capture when you switch to a different application")
                Toggle("Window Focus", isOn: $onWindowFocus)
                    .help("Capture when a different window gains focus")
                Toggle("Typing Pause", isOn: $onTypingPause)
                    .help("Capture after you stop typing for 500ms")
                Toggle("Scroll Stop", isOn: $onScrollStop)
                    .help("Capture after you stop scrolling for 300ms")
                Toggle("Clipboard Change", isOn: $onClipboard)
                    .help("Capture when you copy text")
            }
            .disabled(!eventDrivenEnabled)

            Section("Idle Fallback") {
                Stepper("Idle interval: \(idleFallback)s", value: $idleFallback, in: 10...120, step: 10)
                    .help("Capture periodically when no events detected")
            }
            .disabled(!eventDrivenEnabled)
        }
        .formStyle(.grouped)
    }
}
