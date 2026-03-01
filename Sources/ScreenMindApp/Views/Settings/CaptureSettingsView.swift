import SwiftUI
import Shared

/// Capture settings — intervals, detection threshold, excluded apps.
struct CaptureSettingsView: View {
    @AppStorage("captureActiveInterval") private var activeInterval = AppConstants.Capture.activeInterval
    @AppStorage("captureIdleInterval") private var idleInterval = AppConstants.Capture.idleInterval
    @AppStorage("detectionThreshold") private var threshold = AppConstants.Detection.defaultThreshold
    @AppStorage("excludedApps") private var excludedAppsString = ""

    @State private var newExcludedApp = ""

    private var excludedApps: [String] {
        excludedAppsString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    var body: some View {
        Form {
            Section("Capture Intervals") {
                HStack {
                    Text("When active:")
                    Spacer()
                    Stepper("\(Int(activeInterval))s", value: $activeInterval, in: 1...60, step: 1)
                        .frame(width: 100)
                }

                HStack {
                    Text("When idle:")
                    Spacer()
                    Stepper("\(Int(idleInterval))s", value: $idleInterval, in: 10...300, step: 10)
                        .frame(width: 100)
                }

                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 11))
                    Text("Lower intervals = more notes but higher battery usage")
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
        }
        .formStyle(.grouped)
        .padding()
    }
}
