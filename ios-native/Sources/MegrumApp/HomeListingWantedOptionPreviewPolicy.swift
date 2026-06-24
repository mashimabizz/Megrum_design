import Foundation

enum HomeListingWantedOptionPreviewPolicy {
    static func previewGoodsByOptionID(
        options: [HomeIndividualListingWantedOption],
        goodsPool: [HomeMockGoods]
    ) -> [UUID: HomeMockGoods] {
        var previews: [UUID: HomeMockGoods] = [:]
        for option in options {
            guard let preview = previewGoods(for: option, in: goodsPool) else {
                continue
            }
            previews[option.id] = preview
        }
        return previews
    }

    static func uniqueGoodsPool(_ groups: [[HomeMockGoods]]) -> [HomeMockGoods] {
        var seen: Set<UUID> = []
        var result: [HomeMockGoods] = []
        for goods in groups.flatMap({ $0 }) where seen.insert(goods.id).inserted {
            result.append(goods)
        }
        return result
    }

    private static func previewGoods(
        for option: HomeIndividualListingWantedOption,
        in goodsPool: [HomeMockGoods]
    ) -> HomeMockGoods? {
        let preferredIDs = option.matchingGoodsIDs + option.goodsIDs
        for id in preferredIDs {
            if let goods = goodsPool.first(where: { $0.id == id }) {
                return goods
            }
        }
        return nil
    }
}
