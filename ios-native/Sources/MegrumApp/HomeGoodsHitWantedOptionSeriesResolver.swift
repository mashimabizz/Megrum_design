import Foundation

enum HomeGoodsHitWantedOptionSeriesResolver {
    static func prioritizedWantedOptions(
        _ options: [HomeIndividualListingWantedOption],
        usesListingWantedOptions: Bool,
        previewGoodsPool: [HomeMockGoods],
        allOfferGoods: [HomeMockGoods]
    ) -> [HomeIndividualListingWantedOption] {
        options.enumerated()
            .sorted { lhs, rhs in
                let lhsMatched = wantedOptionHasSeriesMatch(
                    lhs.element,
                    usesListingWantedOptions: usesListingWantedOptions,
                    previewGoodsPool: previewGoodsPool,
                    allOfferGoods: allOfferGoods
                )
                let rhsMatched = wantedOptionHasSeriesMatch(
                    rhs.element,
                    usesListingWantedOptions: usesListingWantedOptions,
                    previewGoodsPool: previewGoodsPool,
                    allOfferGoods: allOfferGoods
                )
                if lhsMatched != rhsMatched {
                    return lhsMatched && !rhsMatched
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    static func orderedPreviewGoods(
        for option: HomeIndividualListingWantedOption?,
        usesListingWantedOptions: Bool,
        previewGoodsPool: [HomeMockGoods],
        allOfferGoods: [HomeMockGoods]
    ) -> [HomeMockGoods] {
        let previewGoods = HomeGoodsHitDetailGoodsResolver.wantedOptionPreviewGoods(
            option: option,
            usesListingWantedOptions: usesListingWantedOptions,
            goodsPool: previewGoodsPool
        )
        return HomeSeriesMatchPolicy.orderedBySeriesMatch(
            previewGoods,
            matchedIDs: seriesMatchedPreviewGoodsIDs(
                option: option,
                previewGoods: previewGoods,
                allOfferGoods: allOfferGoods
            )
        )
    }

    static func badgeTextByGoodsID(
        option: HomeIndividualListingWantedOption?,
        previewGoods: [HomeMockGoods],
        allOfferGoods: [HomeMockGoods]
    ) -> [UUID: String] {
        let matchedIDs = seriesMatchedPreviewGoodsIDs(
            option: option,
            previewGoods: previewGoods,
            allOfferGoods: allOfferGoods
        )
        return Dictionary(uniqueKeysWithValues: matchedIDs.map { ($0, HomeSeriesMatchPolicy.badgeTitle) })
    }

    private static func wantedOptionHasSeriesMatch(
        _ option: HomeIndividualListingWantedOption,
        usesListingWantedOptions: Bool,
        previewGoodsPool: [HomeMockGoods],
        allOfferGoods: [HomeMockGoods]
    ) -> Bool {
        let previewGoods = HomeGoodsHitDetailGoodsResolver.wantedOptionPreviewGoods(
            option: option,
            usesListingWantedOptions: usesListingWantedOptions,
            goodsPool: previewGoodsPool
        )
        return !seriesMatchedPreviewGoodsIDs(
            option: option,
            previewGoods: previewGoods,
            allOfferGoods: allOfferGoods
        ).isEmpty
    }

    private static func seriesMatchedPreviewGoodsIDs(
        option: HomeIndividualListingWantedOption?,
        previewGoods: [HomeMockGoods],
        allOfferGoods: [HomeMockGoods]
    ) -> Set<UUID> {
        guard let option else {
            return []
        }
        return HomeSeriesMatchPolicy.matchedGoodsIDs(
            goods: previewGoods,
            offerGoods: offerGoodsForSeriesComparison(option: option, allOfferGoods: allOfferGoods)
        )
    }

    private static func offerGoodsForSeriesComparison(
        option: HomeIndividualListingWantedOption,
        allOfferGoods: [HomeMockGoods]
    ) -> [HomeMockGoods] {
        let matchingIDs = Set(option.matchingGoodsIDs)
        guard !matchingIDs.isEmpty else {
            return allOfferGoods
        }
        return allOfferGoods.filter { matchingIDs.contains($0.id) }
    }
}
