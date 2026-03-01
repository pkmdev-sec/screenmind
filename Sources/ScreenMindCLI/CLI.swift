import Foundation
import SwiftData
import Shared
import StorageCore
import AIProcessing
import SystemIntegration

/// ScreenMind CLI — query notes, export data, and view stats from the command line.
@main
struct ScreenMindCLI {
    static func main() async {
        let args = CommandLine.arguments.dropFirst()
        guard let command = args.first else {
            printUsage()
            return
        }

        let subArgs = Array(args.dropFirst())

        do {
            switch command {
            case "search":
                try await searchNotes(query: subArgs.joined(separator: " "))
            case "list", "ls":
                try await listNotes(limit: Int(subArgs.first ?? "10") ?? 10)
            case "today":
                try await listTodayNotes()
            case "export":
                try await exportNotes(format: subArgs.first ?? "json", path: subArgs.dropFirst().first)
            case "stats":
                try await showStats()
            case "apps":
                try await listApps()
            case "version":
                print("screenmind-cli 1.0.0")
            case "help", "--help", "-h":
                printUsage()
            default:
                print("Unknown command: \(command)")
                printUsage()
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }

    // MARK: - Commands

    static func searchNotes(query: String) async throws {
        guard !query.isEmpty else {
            print("Usage: screenmind-cli search <query>")
            return
        }

        let storage = try createStorageActor()
        let notes = try await storage.searchNotes(query: query)

        if notes.isEmpty {
            print("No notes found for \"\(query)\"")
            return
        }

        print("Found \(notes.count) note(s) matching \"\(query)\":\n")
        for note in notes.prefix(20) {
            printNote(note)
        }
    }

    static func listNotes(limit: Int) async throws {
        let storage = try createStorageActor()
        let notes = try await storage.searchNotes(
            query: "",
            category: nil,
            from: nil,
            to: nil,
            appName: nil,
            limit: limit
        )

        if notes.isEmpty {
            print("No notes found.")
            return
        }

        print("\(notes.count) most recent note(s):\n")
        for note in notes {
            printNote(note)
        }
    }

    static func listTodayNotes() async throws {
        let storage = try createStorageActor()
        let notes = try await storage.fetchTodayNotes()

        if notes.isEmpty {
            print("No notes captured today.")
            return
        }

        print("\(notes.count) note(s) today:\n")
        for note in notes {
            printNote(note)
        }
    }

    static func exportNotes(format: String, path: String?) async throws {
        let storage = try createStorageActor()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let notes = try await storage.fetchNotes(from: startOfDay, to: endOfDay)

        guard !notes.isEmpty else {
            print("No notes to export.")
            return
        }

        switch format {
        case "json":
            let jsonNotes = notes.map { note -> [String: Any] in
                [
                    "id": note.id.uuidString,
                    "title": note.title,
                    "summary": note.summary,
                    "details": note.details,
                    "category": note.category,
                    "tags": note.tags,
                    "confidence": note.confidence,
                    "app": note.appName,
                    "window": note.windowTitle ?? "",
                    "created": note.createdAt.iso8601String
                ]
            }
            let data = try JSONSerialization.data(withJSONObject: jsonNotes, options: [.prettyPrinted, .sortedKeys])
            if let path {
                try data.write(to: URL(fileURLWithPath: path))
                print("Exported \(notes.count) notes to \(path)")
            } else {
                print(String(data: data, encoding: .utf8) ?? "")
            }

        case "csv":
            var csv = "id,title,summary,category,app,tags,confidence,created\n"
            for note in notes {
                let tags = note.tags.joined(separator: ";")
                csv += "\"\(note.id)\",\"\(escapeCSV(note.title))\",\"\(escapeCSV(note.summary))\",\(note.category),\(note.appName),\"\(tags)\",\(note.confidence),\(note.createdAt.iso8601String)\n"
            }
            if let path {
                try csv.write(toFile: path, atomically: true, encoding: .utf8)
                print("Exported \(notes.count) notes to \(path)")
            } else {
                print(csv)
            }

        default:
            print("Unknown format: \(format). Use 'json' or 'csv'.")
        }
    }

    static func showStats() async throws {
        let storage = try createStorageActor()
        let totalNotes = try await storage.noteCount()
        let todayNotes = try await storage.fetchTodayNotes()
        let diskUsage = try await storage.screenshotDiskUsage()
        let apps = try await storage.distinctAppNames()

        let monitor = ResourceMonitor.shared
        let resources = await monitor.currentResources()
        let throughput = await monitor.currentThroughput()

        print("ScreenMind Stats")
        print("================")
        print("Notes (total):     \(totalNotes)")
        print("Notes (today):     \(todayNotes.count)")
        print("Unique apps:       \(apps.count)")
        print("Disk usage:        \(formatBytes(diskUsage))")
        print("")
        print("Session")
        print("-------")
        print("Frames captured:   \(throughput.totalFramesCaptured)")
        print("Frames filtered:   \(throughput.framesFiltered)")
        print("OCR processed:     \(throughput.framesOCRd)")
        print("Notes generated:   \(throughput.notesGenerated)")
        print("Notes/hour:        \(String(format: "%.1f", throughput.notesPerHour))")
        print("Avg OCR time:      \(String(format: "%.0f", throughput.avgOCRTimeMs)) ms")
        print("")
        print("Resources")
        print("---------")
        print("CPU:               \(String(format: "%.1f", resources.cpuPercent))%")
        print("RAM:               \(String(format: "%.1f", resources.memoryMB)) MB")
        print("Battery:           \(resources.batteryLevel)%\(resources.isOnBattery ? " (battery)" : " (charging)")")
    }

    static func listApps() async throws {
        let storage = try createStorageActor()
        let apps = try await storage.distinctAppNames()

        if apps.isEmpty {
            print("No apps tracked yet.")
            return
        }

        print("\(apps.count) tracked app(s):\n")
        for app in apps {
            print("  - \(app)")
        }
    }

    // MARK: - Helpers

    static func createStorageActor() throws -> StorageActor {
        let schema = Schema([NoteModel.self, ScreenshotModel.self, AppContextModel.self])
        // Read-only access: safe for concurrent use alongside the running app.
        // CLI never writes to the database — only queries and reads.
        let config = ModelConfiguration(
            AppConstants.Storage.databaseName,
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: false
        )
        let container = try ModelContainer(for: schema, configurations: config)
        return StorageActor(modelContainer: container)
    }

    static func printNote(_ note: NoteModel) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let time = dateFormatter.string(from: note.createdAt)
        let tags = note.tags.isEmpty ? "" : " [\(note.tags.joined(separator: ", "))]"
        let redacted = note.redactionCount > 0 ? " [R:\(note.redactionCount)]" : ""

        print("  \(time) | \(note.appName) | \(note.title)\(tags)\(redacted)")
        print("         \(note.summary)")
        print("")
    }

    static func printUsage() {
        print("""
        screenmind-cli — ScreenMind command-line interface

        USAGE:
          screenmind-cli <command> [options]

        COMMANDS:
          search <query>          Search notes by text
          list [limit]            List recent notes (default: 10)
          today                   List today's notes
          export <format> [path]  Export notes (json, csv)
          stats                   Show pipeline & resource stats
          apps                    List tracked applications
          version                 Show version
          help                    Show this help

        EXAMPLES:
          screenmind-cli search "swift concurrency"
          screenmind-cli list 20
          screenmind-cli today
          screenmind-cli export json ~/Desktop/notes.json
          screenmind-cli export csv
          screenmind-cli stats
        """)
    }

    static func escapeCSV(_ text: String) -> String {
        text.replacingOccurrences(of: "\"", with: "\"\"")
            .replacingOccurrences(of: "\n", with: " ")
    }

    static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
