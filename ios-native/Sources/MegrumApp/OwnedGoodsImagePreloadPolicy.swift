import Foundation
import MegrumCore

enum OwnedGoodsImagePreloadPolicy {
    static let defaultLimitPerCollection = 60

    static func urls(
        inventory: [GoodsItem],
        wishes: [WishItem],
        limitPerCollection: Int = defaultLimitPerCollection
    ) -> [URL] {
        let limit = max(0, limitPerCollection)
        let inventoryURLs = inventory.prefix(limit).compactMap(\.imageURL)
        let wishURLs = wishes.prefix(limit).compactMap(\.imageURL)
        return stableUniqueURLs(Array(inventoryURLs) + Array(wishURLs))
    }

    private static func stableUniqueURLs(_ urls: [URL]) -> [URL] {
        var seen = Set<URL>()
        return urls.filter { url in
            guard !seen.contains(url) else {
                return false
            }
            seen.insert(url)
            return true
        }
    }
}
