import MegrumCore
import SwiftUI

extension GoodsCollectionScreen {
    func applyBulkTag(_ tagName: String, to itemIDs: Set<UUID>) {
        guard let appState else {
            return
        }
        let targetItems = items.filter { itemIDs.contains($0.id) && isOwnedItem($0) }
        Task {
            for item in targetItems {
                guard let input = updateInput(for: item, appendingTag: tagName) else {
                    continue
                }
                _ = await appState.updateGoodsEntry(itemID: item.id, kind: entryKind, input: input)
            }
            selectedItemIDs.subtract(itemIDs)
        }
    }

    func bulkTagCandidateNames(for itemIDs: Set<UUID>) -> [String] {
        guard let appState else {
            return []
        }
        let groupIDs = orderedGroupIDs(from: bulkTagTargetItems(for: itemIDs))
        let suggestions = groupIDs.flatMap { groupID in
            GoodsEditorTagSuggestionBuilder.suggestions(
                groupID: groupID,
                selectedTags: [],
                inventory: items,
                wishes: appState.wishes,
                limit: 10
            )
        }
        return TagNameNormalizer.uniquePreservingOrder(suggestions, limit: 10)
    }

    func bulkTagPreviewItemsByTag(for itemIDs: Set<UUID>) -> [String: [TagPreviewItem]] {
        guard let appState else {
            return [:]
        }
        let groupIDs = orderedGroupIDs(from: bulkTagTargetItems(for: itemIDs))
        let selectedGroupID = groupIDs.count == 1 ? groupIDs.first : nil
        return IndividualListingConditionTagBuilder(
            inventory: items,
            wishes: appState.wishes,
            selectedGroupID: selectedGroupID
        )
        .previewItemsByTag()
    }

    func bulkTagGoogleLensItems(for itemIDs: Set<UUID>) -> [GoodsGoogleLensSearchItem] {
        GoodsGoogleLensSearchItemFactory.items(from: bulkTagTargetItems(for: itemIDs))
    }

    func openBulkTagGoogleLensSearch(itemID: GoodsGoogleLensSearchItem.ID, for itemIDs: Set<UUID>) {
        guard let item = bulkTagGoogleLensItems(for: itemIDs).first(where: { $0.id == itemID }),
              case let .imageURL(imageURL) = item.source,
              let lensURL = GoogleLensSearchURLBuilder.url(forImageURL: imageURL)
        else {
            bulkTagGoogleLensErrorMessage = "Google Lensを開けませんでした。画像を選び直してください。"
            return
        }
        bulkTagGoogleLensErrorMessage = nil
        #if os(iOS)
        bulkTagLensBrowserRoute = MegrumInAppBrowserRoute(url: lensURL)
        #else
        openURL(lensURL)
        #endif
    }

    func bulkTagTargetItems(for itemIDs: Set<UUID>) -> [GoodsItem] {
        items.filter { itemIDs.contains($0.id) && isOwnedItem($0) }
    }

    func orderedGroupIDs(from targetItems: [GoodsItem]) -> [UUID] {
        Array(Set(targetItems.compactMap(\.groupID)))
            .sorted { $0.uuidString < $1.uuidString }
    }
}
