import Foundation
import MegrumCore

enum HomeDiscoveryFixtures {
    static func imageURL(_ name: String, fileExtension ext: String = "png") -> URL? {
        Bundle.module.url(
            forResource: name,
            withExtension: ext,
            subdirectory: "TestGoodsImages"
        ) ?? Bundle.module.url(forResource: name, withExtension: ext)
    }

    static func uuid(_ tail: String) -> UUID {
        guard let id = UUID(uuidString: "00000000-0000-0000-0000-\(tail)") else {
            preconditionFailure("Invalid home discovery fixture UUID tail: \(tail)")
        }
        return id
    }

    static let ownerID = uuid("000000000999")
    static let fixtureGroupID = NativePreviewData.groupID
    static let sanaMemberID = uuid("000000000a01")
    static let momoMemberID = uuid("000000000a02")

    static let ownerPublicProfile = PublicUserProfile(
        profile: UserProfile(
            id: ownerID,
            handle: "mii_trade",
            displayName: "mii_交換用",
            avatarURL: imageURL("twice_sana_1"),
            gender: .female,
            prefecture: "福岡県",
            age: 24,
            paymentMethods: [.paypay, .other],
            paymentNote: "差額相談可"
        ),
        averageStars: 4.8,
        evaluationCount: 12,
        completedTradeCount: 32,
        oshiTags: [
            PublicOshiTag(title: "TWICE", priority: 1),
            PublicOshiTag(title: "サナ", priority: 2)
        ]
    )

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
}
