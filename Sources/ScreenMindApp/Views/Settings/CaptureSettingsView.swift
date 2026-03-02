import SwiftUI
import Shared

/// Capture settings — intervals, detection threshold, excluded apps.
struct CaptureSettingsView: View {
    @AppStorage("captureActiveInterval") private var activeInterval = AppConstants.Capture.activeInterval
    @AppStorage("captureIdleInterval") private var idleInterval = AppConstants.Capture.idleInterval
    @AppStorage("detectionThreshold") private var threshold = AppConstants.Detection.defaultThreshold
    @AppStorage("excludedApps") private var excludedAppsString = ""
    @AppStorage("pauseDuringFocus") private var pauseDuringFocus = false
    @AppStorage("eventDrivenCaptureEnabled") private var eventDrivenEnabled = true
    @AppStorage("powerProfileAutoSwitch") private var powerAutoSwitch = true
    @AppStorage("powerProfileManual") private var powerProfile = "performance"

    @State private var newExcludedApp = ""

    private var excludedApps: [String] {
        excludedAppsString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    var body: some View {
        Form {
            Section("Capture Mode") {
                Toggle("Event-Driven Capture", isOn: $eventDrivenEnabled)
                    .help("Capture on meaningful events (app switch, typing pause) instead of fixed intervals")

                if eventDrivenEnabled {
                    Text("Captures triggered by app switches, typing pauses, scroll stops, and clipboard changes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Using timer-based capture at regular intervals")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Capture Intervals") {
                HStack {
                    Text("When active:")
                    Spacer()
                    Stepper("\(Int(activeInterval))s", value: $activeInterval, in: 1...60, step: 1)
                        .frame(width: 100)
                }
                .disabled(eventDrivenEnabled)

                HStack {
                    Text("When idle:")
                    Spacer()
                    Stepper("\(Int(idleInterval))s", value: $idleInterval, in: 10...300, step: 10)
                        .frame(width: 100)
                }
                .disabled(eventDrivenEnabled)

                HStack(spacing: 6) {
                    Image(systemName: eventDrivenEnabled ? "info.circle" : "bolt.fill")
                        .foregroundStyle(eventDrivenEnabled ? .blue : .yellow)
                        .font(.system(size: 11))
                    Text(eventDrivenEnabled ? "Intervals only apply in timer-based mode" : "Lower intervals = more notes but higher battery usage")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Section("Change Detection") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Sensitivity")
                        Spacer()
                        Text("\(Int(threshold * 100))%")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: $threshold, in: 0.05...0.50, step: 0.01)

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
                        .font(.system(size: 12))
                    Text("Higher sensitivity captures more screen changes but generates more notes.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Section("Excluded Apps") {
                HStack {
                    TextField("Bundle ID (e.g., com.apple.Safari)", text: $newExcludedApp)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))

                    Button("Add") {
                        guard !newExcludedApp.isEmpty else { return }
                        let current = excludedApps
                        excludedAppsString = (current + [newExcludedApp]).joined(separator: ", ")
                        newExcludedApp = ""
                    }
                    .controlSize(.small)
                    .disabled(newExcludedApp.isEmpty)
                }

                if !excludedApps.isEmpty {
                    ForEach(excludedApps, id: \.self) { app in
                        HStack {
                            Text(app)
                                .font(.system(size: 12, design: .monospaced))
                            Spacer()
                            Button(role: .destructive) {
                                let updated = excludedApps.filter { $0 != app }
                                excludedAppsString = updated.joined(separator: ", ")
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Section("Focus Mode") {
                Toggle("Pause capture during Focus / DND", isOn: $pauseDuringFocus)

                HStack(spacing: 6) {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(.purple)
                        .font(.system(size: 12))
                    Text("When macOS Focus (Do Not Disturb) is active, ScreenMind will pause capturing. Resumes automatically when Focus ends.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Section("Power Profile") {
                Toggle("Auto-adjust for battery", isOn: $powerAutoSwitch)
                    .help("Reduce capture rate on battery to extend battery life")

                if !powerAutoSwitch {
                    Picker("Profile", selection: $powerProfile) {
                        Text("Performance").tag("performance")
                        Text("Balanced").tag("balanced")
                        Text("Power Saver").tag("saver")
                    }
                    .pickerStyle(.segmented)
                }

                HStack(spacing: 6) {
                    Image(systemName: "battery.75percent")
                        .foregroundStyle(.green)
                        .font(.system(size: 12))
                    Text(powerAutoSwitch ? "System will automatically switch between Performance (AC), Balanced (battery >40%), and Power Saver (battery ≤40% or thermal)" : "Manual profile: \(profileDescription)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var profileDescription: String {
        switch powerProfile {
        case "performance": return "Performance — full speed (200ms debounce, 3s visual check)"
        case "balanced": return "Balanced — moderate (500ms debounce, 10s visual check)"
        case "saver": return "Power Saver — slow (1s debounce, 30s visual check)"
        default: return ""
        }
    }
}
