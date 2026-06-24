extension HomeDiscoveryFixtures {
    static let miiIndividualListingSelection = HomeIndividualListingSelectionContext(
        wantedLogic: .one,
        offeredLogic: .all,
        wantedOptions: [
            HomeIndividualListingWantedOption(
                id: uuid("000000000981"),
                listingID: uuid("000000000980"),
                position: 1,
                title: "サナ トレカ",
                subtitle: "グッズ指定",
                logic: .one,
                kind: .goods,
                goodsIDs: [sanaLavender.id],
                matchingGoodsIDs: [sanaLavender.id],
                groupID: nil,
                goodsTypeID: nil
            ),
            HomeIndividualListingWantedOption(
                id: uuid("000000000982"),
                listingID: uuid("000000000980"),
                position: 2,
                title: "TWICE モモ / トレカ",
                subtitle: "条件指定・該当するグッズから選択",
                logic: .one,
                kind: .condition,
                goodsIDs: [],
                matchingGoodsIDs: [momoFanmi.id],
                groupID: nil,
                goodsTypeID: nil
            ),
            HomeIndividualListingWantedOption(
                id: uuid("000000000983"),
                listingID: uuid("000000000980"),
                position: 3,
                title: "定価1,500円",
                subtitle: "金額で受け取る条件",
                logic: .one,
                kind: .cash,
                cashAmount: 1_500
            )
        ]
    )

    static let userTagCandidates: [HomeDiscoveryCandidate] = [
        HomeDiscoveryCandidate(
            id: uuid("000000000911"),
            title: "サナ×#2026 LIVE",
            signals: miiListingHitSignals(index: 0),
            sheet: .goodsHit(.init(
                goods: selectedYellow,
                signals: miiListingHitSignals(index: 0)
            )),
            goods: [selectedYellow, sanaBadge, sanaStand]
        ),
        HomeDiscoveryCandidate(
            id: uuid("000000000912"),
            title: "モモ×#ファンミ",
            signals: signals(listingHit: false, wishHit: true, postal: false, local: true, prefecture: false, date: false),
            sheet: .wishHit(.init(
                goods: momoFanmi,
                signals: signals(listingHit: false, wishHit: true, postal: false, local: true, prefecture: false, date: false)
            )),
            goods: [momoFanmi, momoFanmiAlt, momoFanmiStand]
        )
    ]

    static let userCandidates: [HomeDiscoveryCandidate] = [
        HomeDiscoveryCandidate(
            id: uuid("000000000913"),
            title: "サナ",
            signals: signals(listingHit: false, wishHit: true, postal: false, local: true, prefecture: true, date: false),
            sheet: .wishHit(.init(
                goods: sanaLavender,
                signals: signals(listingHit: false, wishHit: true, postal: false, local: true, prefecture: true, date: false)
            )),
            goods: [sanaLavender, sanaBadge, sanaKeychain]
        ),
        HomeDiscoveryCandidate(
            id: uuid("000000000914"),
            title: "モモ",
            signals: signals(listingHit: false, wishHit: false, postal: false, local: false, prefecture: false, date: false),
            sheet: .wishHit(.init(
                goods: momoFanmi,
                signals: signals(listingHit: false, wishHit: false, postal: false, local: false, prefecture: false, date: false)
            )),
            goods: [momoFanmi, momoFanmiAlt, momoFanmiStand]
        )
    ]

    static let havesCandidates: [HomeDiscoveryCandidate] = [
        HomeDiscoveryCandidate(
            id: uuid("000000000915"),
            title: "サナ",
            signals: signals(
                listingHit: true,
                wishHit: true,
                postal: true,
                local: false,
                prefecture: false,
                date: false,
                wishCount: 8,
                listingCount: 3
            ),
            sheet: .havesLookup(
                havesPayload(
                    offeredGoods: sanaLavender,
                    signals: signals(
                        listingHit: true,
                        wishHit: true,
                        postal: true,
                        local: false,
                        prefecture: false,
                        date: false,
                        wishCount: 8,
                        listingCount: 3
                    )
                )
            ),
            goods: [sanaLavender, sanaBadge, sanaStand]
        ),
        HomeDiscoveryCandidate(
            id: uuid("000000000916"),
            title: "ぬい",
            signals: signals(
                listingHit: false,
                wishHit: true,
                postal: false,
                local: true,
                prefecture: true,
                date: false,
                wishCount: 5,
                listingCount: 0
            ),
            sheet: .havesLookup(
                havesPayload(
                    offeredGoods: plush,
                    signals: signals(
                        listingHit: false,
                        wishHit: true,
                        postal: false,
                        local: true,
                        prefecture: true,
                        date: false,
                        wishCount: 5,
                        listingCount: 0
                    )
                )
            ),
            goods: [plush, sanaKeychain, sanaBadge]
        ),
        HomeDiscoveryCandidate(
            id: uuid("000000000917"),
            title: "缶バッジ",
            signals: signals(
                listingHit: true,
                wishHit: true,
                postal: false,
                local: true,
                prefecture: false,
                date: true,
                wishCount: 4,
                listingCount: 2
            ),
            sheet: .havesLookup(
                havesPayload(
                    offeredGoods: sanaBadge,
                    signals: signals(
                        listingHit: true,
                        wishHit: true,
                        postal: false,
                        local: true,
                        prefecture: false,
                        date: true,
                        wishCount: 4,
                        listingCount: 2
                    )
                )
            ),
            goods: [sanaBadge, sanaLavender, momoFanmi]
        ),
        HomeDiscoveryCandidate(
            id: uuid("000000000918"),
            title: "アクスタ",
            signals: signals(
                listingHit: false,
                wishHit: true,
                postal: false,
                local: true,
                prefecture: true,
                date: true,
                wishCount: 3,
                listingCount: 1
            ),
            sheet: .havesLookup(
                havesPayload(
                    offeredGoods: sanaStand,
                    signals: signals(
                        listingHit: false,
                        wishHit: true,
                        postal: false,
                        local: true,
                        prefecture: true,
                        date: true,
                        wishCount: 3,
                        listingCount: 1
                    )
                )
            ),
            goods: [sanaStand, selectedYellow, sanaKeychain]
        )
    ]

    private static func havesPayload(
        offeredGoods: HomeMockGoods,
        signals: HomeCandidateConditionSignals
    ) -> HomeHavesLookupPayload {
        HomeHavesLookupPayload(
            offeredGoods: offeredGoods,
            offeredSignals: signals,
            tagMatchedCandidates: userTagCandidates,
            memberMatchedCandidates: userCandidates
        )
    }

    static let wantedGoods = [sanaBadge, sanaLavender, sanaStand]
    static let offerGoods = [sanaLavender, sanaBadge, sanaKeychain, momoFanmi]
    static let otherListingHit = [momoFanmi, plush, sanaKeychain, sanaLavender]
    static let otherWishHit = [sanaBadge, selectedYellow, sanaStand, plush]
}
