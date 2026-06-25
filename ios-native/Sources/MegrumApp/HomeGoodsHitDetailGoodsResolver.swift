import Foundation
import MegrumCore

enum HomeGoodsHitDetailGoodsResolver {
    static func receiveGoods(selection: HomeDiscoverySheetPayload) -> [HomeMockGoods] {
        let offeredItems = selection.individualListingSelection.detail?.offeredItems ?? []
        let mappedGoods = offeredItems.enumerated().map { index, item in
            if item.id == selection.goods.id {
                return selection.goods
            }
            let ownerID = selection.goods.ownerID ?? HomeDiscoveryFixtures.ownerID
            return HomeMockGoods.from(
                item: GoodsItem(
                    id: item.id,
                    ownerID: ownerID,
                    title: item.title,
                    imageURL: item.imageURL,
                    quantity: item.quantity,
                    ownerPrefecture: selection.goods.ownerPrefecture,
                    ownerDisplayName: selection.goods.ownerDisplayName,
                    ownerHandle: selection.goods.ownerHandle,
                    ownerAvatarURL: selection.goods.ownerAvatarURL,
                    ownerGender: selection.goods.ownerGender,
                    ownerAge: selection.goods.ownerAge,
                    ownerAverageStars: selection.goods.ownerAverageStars,
                    ownerEvaluationCount: selection.goods.ownerEvaluationCount,
                    ownerCompletedTradeCount: selection.goods.ownerCompletedTradeCount,
                    ownerPaymentMethods: selection.goods.ownerPaymentMethods,
                    ownerPaymentNote: selection.goods.ownerPaymentNote
                ),
                index: index,
                goodsTypes: []
            )
        }
        return mappedGoods.isEmpty ? [selection.goods] : mappedGoods
    }

    static func wantedOptionPreviewGoods(
        option: HomeIndividualListingWantedOption?,
        usesListingWantedOptions: Bool,
        goodsPool: [HomeMockGoods]
    ) -> [HomeMockGoods] {
        guard usesListingWantedOptions, let option else {
            return []
        }
        let previewGoods = option.previewItems.enumerated().map { index, item in
            HomeMockGoods.from(
                wantedPreviewItem: item,
                index: index,
                subtitle: option.subtitle ?? option.title
            )
        }
        if !previewGoods.isEmpty {
            return previewGoods
        }

        let preferredIDs = option.matchingGoodsIDs + option.goodsIDs
        var seen: Set<UUID> = []
        return preferredIDs.compactMap { id in
            guard seen.insert(id).inserted else {
                return nil
            }
            return goodsPool.first { $0.id == id }
        }
    }

    static func allOfferGoods(
        viewerOfferGoods: [HomeMockGoods],
        preferredOfferGoodsID: UUID?
    ) -> [HomeMockGoods] {
        HomeOfferGoodsOrdering.ordered(
            viewerOfferGoods.isEmpty ? HomeDiscoveryFixtures.offerGoods : viewerOfferGoods,
            preferredOfferGoodsID: preferredOfferGoodsID
        )
    }

    static func offerGoods(
        usesListingWantedOptions: Bool,
        allOfferGoods: [HomeMockGoods],
        selectedWantedOptions: [HomeIndividualListingWantedOption]
    ) -> [HomeMockGoods] {
        guard usesListingWantedOptions else {
            return allOfferGoods
        }
        let matchingIDs = Set(selectedWantedOptions.flatMap(\.matchingGoodsIDs))
        guard !matchingIDs.isEmpty else {
            return []
        }
        return allOfferGoods.filter { matchingIDs.contains($0.id) }
    }

    static func wantedOptionPreviewGoodsPool(
        allOfferGoods: [HomeMockGoods],
        wantedGoods: [HomeMockGoods],
        selectedGoods: HomeMockGoods
    ) -> [HomeMockGoods] {
        HomeListingWantedOptionPreviewPolicy.uniqueGoodsPool([
            allOfferGoods,
            wantedGoods,
            HomeDiscoveryFixtures.offerGoods,
            HomeDiscoveryFixtures.wantedGoods,
            [selectedGoods]
        ])
    }
}
