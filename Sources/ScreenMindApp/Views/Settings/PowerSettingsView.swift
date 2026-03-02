import SwiftUI

struct PowerSettingsView: View {
    @AppStorage("powerProfileAutoSwitch") private var autoSwitch = true
    @AppStorage("powerProfileManual") private var manualProfile = "performance"

    var body: some View {
        Form {
            Section("Power Management") {
                Toggle("Auto-switch profiles", isOn: $autoSwitch)
                    .help("Automatically adjust capture behavior based on battery and thermal state")

                if !autoSwitch {
                    Picker("Manual Profile", selection: $manualProfile) {
                        Text("Performance").tag("performance")
                        Text("Balanced").tag("balanced")
                        Text("Power Saver").tag("saver")
                    }
                    .pickerStyle(.segmented)
                }
            }

            Section("Profile Details") {
                VStack(alignment: .leading, spacing: 12) {
                    profileRow("Performance", desc: "AC power — full speed (200ms debounce, 3s visual check)", icon: "bolt.fill")
                    Divider()
                    profileRow("Balanced", desc: "Battery >40% — moderate (500ms debounce, 10s visual check)", icon: "battery.75percent")
                    Divider()
                    profileRow("Power Saver", desc: "Battery ≤40% or thermal — slow (1s debounce, 30s visual check)", icon: "battery.25percent")
                }
            }

            Section("Thermal Override") {
                Text("When the system reaches serious/critical thermal state, Power Saver is automatically activated regardless of battery level.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func profileRow(_ name: String, desc: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.headline)
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
