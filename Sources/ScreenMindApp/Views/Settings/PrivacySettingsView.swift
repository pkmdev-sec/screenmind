import SwiftUI
import SwiftData
import CoreGraphics
import Shared
import StorageCore

/// Privacy settings — permission status, data management.
struct PrivacySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteConfirmation = false
    @State private var screenCaptureGranted = false
    @State private var deleteMessage: String?

    var body: some View {
        Form {
            Section("Permissions") {
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Screen Recording")
                                .font(.system(size: 13, weight: .medium))
                            Text("Required to capture screen content")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "record.circle")
                            .foregroundStyle(screenCaptureGranted ? .green : .red)
                    }

                    Spacer()

                    if screenCaptureGranted {
                        Text("Granted")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.green)
                    } else {
                        Button("Open System Settings") {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
                        }
                        .controlSize(.small)
                    }
                }
            }

            Section("Data") {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                        .font(.system(size: 12))
                    Text("All data is stored locally on your Mac. Only extracted text is sent to the language model for note generation.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Section("Danger Zone") {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete All Notes & Screenshots", systemImage: "trash.fill")
                }
                .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete Everything", role: .destructive) {
                        Task {
                            do {
                                let container = modelContext.container
                                let storageActor = StorageActor(modelContainer: container)
                                let count = try await storageActor.deleteAllNotes()
                                deleteMessage = "Deleted \(count) notes"
                                SMLogger.ui.info("User deleted all data: \(count) notes")
                            } catch {
                                deleteMessage = "Delete failed: \(error.localizedDescription)"
                                SMLogger.ui.error("Delete all failed: \(error.localizedDescription)")
                            }
                        }
                    }
                } message: {
                    Text("This will permanently delete all notes and screenshots from SwiftData. Obsidian vault files will not be affected.")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            screenCaptureGranted = CGPreflightScreenCaptureAccess()
        }
    }
}
