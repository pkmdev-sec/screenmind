import SwiftUI
import Shared
import SystemIntegration

/// Performance dashboard — live resource usage and pipeline throughput stats.
struct PerformanceSettingsView: View {
    @State private var resources: ResourceMonitor.ResourceSnapshot?
    @State private var throughput: ResourceMonitor.ThroughputStats?

    var body: some View {
        Form {
            // Resource Usage
            Section("Resource Usage") {
                if let res = resources {
                    HStack(spacing: 24) {
                        resourceGauge(label: "CPU", value: res.cpuPercent, max: 100, unit: "%", color: cpuColor(res.cpuPercent))
                        resourceGauge(label: "RAM", value: res.memoryMB, max: Double(AppConstants.Resources.maxRAMMB), unit: "MB", color: ramColor(res.memoryMB))
                        resourceGauge(label: "Battery", value: Double(res.batteryLevel), max: 100, unit: "%", color: batteryColor(res.batteryLevel))
                    }
                    .padding(.vertical, 4)

                    HStack(spacing: 12) {
                        Label(res.isOnBattery ? "On Battery" : "Plugged In", systemImage: res.isOnBattery ? "battery.50" : "bolt.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(res.isOnBattery ? .orange : .green)
                        if res.isLowPower {
                            Text("Low Power (reduced capture rate)")
                                .font(.system(size: 11))
                                .foregroundStyle(.red)
                        }
                    }
                } else {
                    ProgressView("Loading...")
                        .controlSize(.small)
                }
            }

            // Pipeline Throughput
            if let tp = throughput {
                Section("Pipeline Throughput") {
                    HStack {
                        statBox(label: "Frames", value: "\(tp.totalFramesCaptured)", icon: "photo.stack")
                        statBox(label: "Filtered", value: "\(tp.framesFiltered)", icon: "line.3.horizontal.decrease")
                        statBox(label: "OCR'd", value: "\(tp.framesOCRd)", icon: "text.magnifyingglass")
                        statBox(label: "Notes", value: "\(tp.notesGenerated)", icon: "note.text")
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notes/hour")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f", tp.notesPerHour))
                                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Uptime")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Text(formatUptime(tp.uptime))
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Processing Times") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Avg OCR Time")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.0f ms", tp.avgOCRTimeMs))
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Avg AI Time")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.0f ms", tp.avgAITimeMs))
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                        }
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Skipped (AI)")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Text("\(tp.notesSkippedByAI)")
                                .font(.system(size: 14, design: .monospaced))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Skipped (Rules)")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Text("\(tp.notesSkippedByRules)")
                                .font(.system(size: 14, design: .monospaced))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Redactions")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Text("\(tp.redactionsApplied)")
                                .font(.system(size: 14, design: .monospaced))
                        }
                    }
                }

                if let lastNote = tp.lastNoteTime {
                    Section("Last Activity") {
                        HStack {
                            Text("Last note generated:")
                                .font(.system(size: 12))
                            Spacer()
                            Text(lastNote, style: .relative)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Targets
            Section("Resource Targets") {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                        .font(.system(size: 12))
                    Text("Target: <\(Int(AppConstants.Resources.maxCPUPercent))% CPU, <\(AppConstants.Resources.maxRAMMB)MB RAM, <\(Int(AppConstants.Resources.maxBatteryDrainPerHour))%/hr battery drain")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .task {
            // Refresh stats every 3 seconds; auto-cancelled when view disappears
            while !Task.isCancelled {
                let monitor = ResourceMonitor.shared
                resources = await monitor.currentResources()
                throughput = await monitor.currentThroughput()
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }

    // MARK: - Components

    private func resourceGauge(label: String, value: Double, max: Double, unit: String, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 6)
                Circle()
                    .trim(from: 0, to: min(value / max, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: value)

                VStack(spacing: 0) {
                    Text(String(format: "%.0f", value))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                    Text(unit)
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(width: 60, height: 60)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private func statBox(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Colors

    private func cpuColor(_ value: Double) -> Color {
        value < 5 ? .green : (value < 15 ? .orange : .red)
    }

    private func ramColor(_ value: Double) -> Color {
        value < 80 ? .green : (value < 150 ? .orange : .red)
    }

    private func batteryColor(_ level: Int) -> Color {
        level > 50 ? .green : (level > 20 ? .orange : .red)
    }

    // MARK: - Helpers

    private func formatUptime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        }
        return String(format: "%dm %02ds", minutes, secs)
    }
}
