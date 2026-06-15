import MegrumDesign
import SwiftUI

enum HomeDiscoveryFixtures {
    private static func imageURL(_ name: String, fileExtension ext: String = "png") -> URL? {
        Bundle.module.url(
            forResource: name,
            withExtension: ext,
            subdirectory: "TestGoodsImages"
        ) ?? Bundle.module.url(forResource: name, withExtension: ext)
    }

    private static func uuid(_ tail: String) -> UUID {
        guard let id = UUID(uuidString: "00000000-0000-0000-0000-\(tail)") else {
            preconditionFailure("Invalid home discovery fixture UUID tail: \(tail)")
        }
        return id
    }

    static func signals(
        listingHit: Bool,
        wishHit: Bool,
        postal: Bool,
        local: Bool,
        prefecture: Bool,
        date: Bool,
        wishCount: Int = 0,
        listingCount: Int = 0,
        individualListingSelection: HomeIndividualListingSelectionContext? = nil
    ) -> HomeCandidateConditionSignals {
        HomeCandidateConditionSignals(
            goods: HomeGoodsConditionSignals(
                hasIndividualListingHit: listingHit,
                hasWishHit: wishHit
            ),
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: postal,
                localExchangeSelected: local,
                prefectureMatches: prefecture,
                dateMatches: date
            ),
            linkCounts: HomeCandidateLinkCounts(
                wishCount: wishCount,
                listingCount: listingCount
            ),
            individualListingSelection: individualListingSelection,
            matchesViewerWish: true,
            tagMatchCount: listingHit || wishHit ? 1 : 0
        )
    }

    static func miiListingHitSignals(index: Int = 0) -> HomeCandidateConditionSignals {
        signals(
            listingHit: true,
            wishHit: true,
            postal: false,
            local: true,
            prefecture: index.isMultiple(of: 2),
            date: true,
            wishCount: 4,
            listingCount: 2,
            individualListingSelection: miiIndividualListingSelection
        )
    }

    static func conditionTags(
        goods: HomeGoodsCondition,
        exchange: HomeExchangeCondition = .exact,
        payment: HomePaymentCondition = .compatible
    ) -> HomeConditionTagSet {
        HomeConditionTagSet(goods: goods, exchange: exchange, payment: payment)
    }

    static func wantedConditionTags(base: HomeConditionTagSet) -> [HomeConditionTagSet] {
        [
            base,
            conditionTags(goods: .wish, exchange: base.exchange, payment: base.payment),
            conditionTags(goods: .none, exchange: .possible, payment: .warning)
        ]
    }

    static func offerConditionTags(base: HomeConditionTagSet) -> [HomeConditionTagSet] {
        [
            conditionTags(goods: .direct, exchange: base.exchange, payment: base.payment),
            conditionTags(goods: .wish, exchange: base.exchange, payment: .warning),
            conditionTags(goods: .none, exchange: .possible, payment: .warning),
            conditionTags(goods: .wish, exchange: .warning, payment: base.payment)
        ]
    }

    static let selectedYellow = HomeMockGoods.make(
        "000000000901",
        title: "サナ",
        subtitle: "2026 LIVE",
        shape: .portrait,
        palette: [
            Color(red: 0.95, green: 0.84, blue: 0.58),
            MegrumTheme.pink.opacity(0.56),
            MegrumTheme.lavender.opacity(0.34)
        ],
        symbol: "S",
        imageURL: imageURL("twice_sana_1")
    )

    static let sanaLavender = HomeMockGoods.make(
        "000000000902",
        title: "サナ",
        subtitle: "トレカ",
        displayTags: ["#2026 LIVE"],
        rawTagNames: ["2026 live"],
        shape: .portrait,
        palette: [
            MegrumTheme.lavender.opacity(0.78),
            Color.white.opacity(0.78),
            MegrumTheme.sky.opacity(0.38)
        ],
        symbol: "S",
        imageURL: imageURL("twice_momo_2")
    )

    static let momoFanmi = HomeMockGoods.make(
        "000000000903",
        title: "モモ",
        subtitle: "ファンミ",
        displayTags: ["#ファンミ"],
        rawTagNames: ["ファンミ"],
        shape: .portrait,
        palette: [
            Color(red: 0.92, green: 0.70, blue: 0.58),
            MegrumTheme.pink.opacity(0.68),
            MegrumTheme.lavender.opacity(0.36)
        ],
        symbol: "M",
        imageURL: imageURL("twice_momo_1")
    )

    static let sanaBadge = HomeMockGoods.make(
        "000000000904",
        title: "サナ",
        subtitle: "缶バッジ",
        shape: .badge,
        palette: [
            MegrumTheme.sky.opacity(0.60),
            Color.white.opacity(0.92),
            MegrumTheme.pink.opacity(0.38)
        ],
        symbol: "S",
        imageURL: imageURL("twice_dahyun_1")
    )

    static let sanaStand = HomeMockGoods.make(
        "000000000905",
        title: "サナ",
        subtitle: "アクスタ",
        shape: .stand,
        palette: [
            Color.white,
            MegrumTheme.lavender.opacity(0.28),
            MegrumTheme.sky.opacity(0.22)
        ],
        symbol: "S",
        imageURL: imageURL("aespa_ningning")
    )

    static let sanaKeychain = HomeMockGoods.make(
        "000000000906",
        title: "サナ",
        subtitle: "キーホルダー",
        shape: .keychain,
        palette: [
            Color.white,
            MegrumTheme.pink.opacity(0.30),
            MegrumTheme.lavender.opacity(0.42)
        ],
        symbol: "S",
        imageURL: imageURL("bts_jungkook")
    )

    static let plush = HomeMockGoods.make(
        "000000000907",
        title: "サナ",
        subtitle: "ぬい",
        shape: .plush,
        palette: [
            MegrumTheme.lavender.opacity(0.46),
            Color.white.opacity(0.82),
            MegrumTheme.sky.opacity(0.28)
        ],
        symbol: "♡",
        imageURL: imageURL("bts_v")
    )

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
            goods: [momoFanmi, sanaLavender, sanaKeychain]
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
            goods: [momoFanmi, plush, sanaStand]
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
