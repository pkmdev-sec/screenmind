import Foundation
import CoreSpotlight
import Shared

/// Indexes notes in Spotlight so they appear in system search.
public struct SpotlightIndexer: Sendable {

    public init() {}

    /// Index a note in Spotlight.
    public func indexNote(
        id: String,
        title: String,
        summary: String,
        category: String,
        appName: String,
        tags: [String],
        createdAt: Date
    ) async {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = title
        attributeSet.contentDescription = summary
        attributeSet.keywords = tags + [category, appName, "screenmind"]
        attributeSet.contentCreationDate = createdAt
        attributeSet.creator = "ScreenMind"

        let item = CSSearchableItem(
            uniqueIdentifier: id,
            domainIdentifier: AppConstants.bundleIdentifier,
            attributeSet: attributeSet
        )
        item.expirationDate = Calendar.current.date(
            byAdding: .day,
            value: AppConstants.Storage.retentionDays,
            to: createdAt
        )

        do {
            try await CSSearchableIndex.default().indexSearchableItems([item])
            SMLogger.system.debug("Spotlight indexed: \(title)")
        } catch {
            SMLogger.system.error("Spotlight index failed: \(error.localizedDescription)")
        }
    }

    /// Remove a note from Spotlight index.
    public func removeNote(id: String) async {
        do {
            try await CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [id])
        } catch {
            SMLogger.system.error("Spotlight remove failed: \(error.localizedDescription)")
        }
    }

    /// Remove all ScreenMind entries from Spotlight.
    public func removeAll() async {
        do {
            try await CSSearchableIndex.default().deleteSearchableItems(
                withDomainIdentifiers: [AppConstants.bundleIdentifier]
            )
            SMLogger.system.info("Spotlight index cleared")
        } catch {
            SMLogger.system.error("Spotlight clear failed: \(error.localizedDescription)")
        }
    }
}
