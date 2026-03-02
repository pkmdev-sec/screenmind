import Foundation
import Shared

/// Lightweight update checker using GitHub Releases API.
/// No external dependencies (no Sparkle needed).
public actor UpdateChecker {
    public static let shared = UpdateChecker()

    /// Available update info.
    public struct UpdateInfo: Sendable {
        public let currentVersion: String
        public let latestVersion: String
        public let downloadURL: String
        public let releaseNotes: String
        public let isUpdateAvailable: Bool
    }

    private let repo = "pkmdev-sec/screenmind"
    private var lastCheck: Date?
    private var cachedUpdate: UpdateInfo?
    private let checkInterval: TimeInterval = 86400 // 24 hours

    private init() {}

    /// Check for updates (rate-limited to once per 24h).
    public func checkForUpdates(force: Bool = false) async -> UpdateInfo? {
        // Rate limit: check once per 24 hours unless forced
        if !force, let lastCheck, Date.now.timeIntervalSince(lastCheck) < checkInterval {
            return cachedUpdate
        }

        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

        do {
            let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            request.setValue("ScreenMind/\(currentVersion)", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }

            let tagName = (json["tag_name"] as? String ?? "").replacingOccurrences(of: "v", with: "")
            let body = json["body"] as? String ?? ""
            let htmlURL = json["html_url"] as? String ?? ""

            // Find DMG asset
            let assets = json["assets"] as? [[String: Any]] ?? []
            let dmgAsset = assets.first { ($0["name"] as? String ?? "").hasSuffix(".dmg") }
            let downloadURL = dmgAsset?["browser_download_url"] as? String ?? htmlURL

            let update = UpdateInfo(
                currentVersion: currentVersion,
                latestVersion: tagName,
                downloadURL: downloadURL,
                releaseNotes: String(body.prefix(500)),
                isUpdateAvailable: isNewerVersion(tagName, than: currentVersion)
            )

            lastCheck = .now
            cachedUpdate = update
            SMLogger.system.info("Update check: current=\(currentVersion), latest=\(tagName), update=\(update.isUpdateAvailable)")
            return update

        } catch {
            SMLogger.system.warning("Update check failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Simple semantic version comparison.
    private func isNewerVersion(_ latest: String, than current: String) -> Bool {
        let latestParts = latest.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(latestParts.count, currentParts.count) {
            let l = i < latestParts.count ? latestParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            if l > c { return true }
            if l < c { return false }
        }
        return false
    }
}
