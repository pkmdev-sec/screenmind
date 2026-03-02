import SwiftUI
import Shared

/// Settings window with tabbed sections — macOS native style.
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            CaptureSettingsView()
                .tabItem {
                    Label("Capture", systemImage: "camera.fill")
                }

            EventTriggersSettingsView()
                .tabItem {
                    Label("Events", systemImage: "bolt.fill")
                }

            PowerSettingsView()
                .tabItem {
                    Label("Power", systemImage: "battery.75percent")
                }

            AudioSettingsView()
                .tabItem {
                    Label("Audio", systemImage: "waveform")
                }

            AISettingsView()
                .tabItem {
                    Label("AI", systemImage: "brain")
                }

            SearchSettingsView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            ExportSettingsView()
                .tabItem {
                    Label("Export", systemImage: "square.and.arrow.up")
                }

            PrivacySettingsView()
                .tabItem {
                    Label("Privacy", systemImage: "lock.shield.fill")
                }

            PerformanceSettingsView()
                .tabItem {
                    Label("Stats", systemImage: "gauge.with.dots.needle.33percent")
                }

            PluginSettingsView()
                .tabItem {
                    Label("Plugins", systemImage: "puzzlepiece.extension")
                }
        }
        .frame(width: 780, height: 620)
    }
}
