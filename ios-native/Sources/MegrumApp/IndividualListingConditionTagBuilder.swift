import Foundation
import MegrumCore

struct IndividualListingConditionTagBuilder {
    var inventory: [GoodsItem]
    var wishes: [WishItem]
    var selectedGroupID: UUID?

    func candidateNames(limit: Int = 10) -> [String] {
        TagNameNormalizer.uniquePreservingOrder(
            matchingInventory.flatMap { $0.tags.map(\.name) } + matchingWishes.flatMap { $0.tags.map(\.name) },
            limit: limit
        )
    }

    func previewItemsByTag() -> [String: [TagPreviewItem]] {
        var result: [String: [TagPreviewItem]] = [:]
        for item in matchingInventory {
            appendPreview(itemID: item.id, title: item.title, imageURL: item.imageURL, tags: item.tags, to: &result)
        }
        for item in matchingWishes {
            appendPreview(itemID: item.id, title: item.title, imageURL: item.imageURL, tags: item.tags, to: &result)
        }
        return result
    }

    private var matchingInventory: [GoodsItem] {
        inventory.filter(matchesSelectedGroup)
    }

    private var matchingWishes: [WishItem] {
        wishes.filter(matchesSelectedGroup)
    }

    private func matchesSelectedGroup(_ item: GoodsItem) -> Bool {
        guard let selectedGroupID else {
            return true
        }
        return item.groupID == selectedGroupID
    }

    private func matchesSelectedGroup(_ item: WishItem) -> Bool {
        guard let selectedGroupID else {
            return true
        }
        return item.groupID == selectedGroupID
    }

    private func appendPreview(
        itemID: UUID,
        title: String,
        imageURL: URL?,
        tags: [GoodsTag],
        to result: inout [String: [TagPreviewItem]]
    ) {
        for tag in tags {
            let preview = TagPreviewItem(id: itemID, title: title, imageURL: imageURL)
            if result[tag.name]?.contains(preview) == true {
                continue
            }
            result[tag.name, default: []].append(preview)
        }
    }

}
