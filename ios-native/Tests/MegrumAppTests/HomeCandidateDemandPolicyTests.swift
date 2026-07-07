@testable import MegrumApp
import MegrumCore
import XCTest

final class HomeCandidateDemandPolicyTests: XCTestCase {
    // MARK: - 需要行の優先順位

    func testGoodsOptionMatchIsHotDemand() {
        let goodsID = UUID()
        let signals = makeSignals(
            wantedOptions: [makeOption(kind: .goods, matchingGoodsIDs: [goodsID])]
        )
        XCTAssertEqual(
            HomeCandidateDemandPolicy.demandLine(for: signals),
            .hotDemand(goodsIDs: [goodsID])
        )
        XCTAssertEqual(HomeCandidateDemandPolicy.demandRank(for: signals), 4)
    }

    func testConditionOptionMatchIsHotDemand() {
        // iter1226.362：個別募集の条件選択肢を満たせる場合も激求（指名と同じ扱い）。
        let goodsID = UUID()
        let signals = makeSignals(
            wantedOptions: [makeOption(kind: .condition, matchingGoodsIDs: [goodsID])]
        )
        XCTAssertEqual(
            HomeCandidateDemandPolicy.demandLine(for: signals),
            .hotDemand(goodsIDs: [goodsID])
        )
        XCTAssertEqual(HomeCandidateDemandPolicy.demandRank(for: signals), 4)
    }

    func testWishMatchWithoutListingIsDemand() {
        let goodsID = UUID()
        let signals = makeSignals(wishMatchedOfferGoodsIDs: [goodsID])
        XCTAssertEqual(
            HomeCandidateDemandPolicy.demandLine(for: signals),
            .demand(goodsIDs: [goodsID])
        )
    }

    func testListingOptionsAreHotDemandAndBeatCash() {
        // 個別募集の選択肢（指名・条件どちらも）は激求で、定価より優先。
        let designatedID = UUID()
        let conditionID = UUID()
        let signals = makeSignals(
            wantedOptions: [
                makeOption(kind: .cash, cashAmount: 1_000),
                makeOption(kind: .condition, matchingGoodsIDs: [conditionID]),
                makeOption(kind: .goods, matchingGoodsIDs: [designatedID])
            ]
        )
        XCTAssertEqual(
            HomeCandidateDemandPolicy.demandLine(for: signals),
            .hotDemand(goodsIDs: [conditionID, designatedID])
        )
    }

    func testCashOnlyOptionIsCashLine() {
        let signals = makeSignals(
            wantedOptions: [makeOption(kind: .cash, cashAmount: 1_100)]
        )
        XCTAssertEqual(
            HomeCandidateDemandPolicy.demandLine(for: signals),
            .cash(amount: 1_100)
        )
    }

    func testLookingForWhenPartnerWishKnownButNoMatch() {
        let signals = makeSignals(partnerLookingForText: "サナのトレカ")
        XCTAssertEqual(
            HomeCandidateDemandPolicy.demandLine(for: signals),
            .lookingFor(text: "サナのトレカ")
        )
        XCTAssertEqual(HomeCandidateDemandPolicy.demandRank(for: signals), 1)
    }

    func testNoSignalsIsDiscuss() {
        let signals = makeSignals()
        XCTAssertEqual(HomeCandidateDemandPolicy.demandLine(for: signals), .discuss)
        XCTAssertEqual(HomeCandidateDemandPolicy.demandRank(for: signals), 0)
    }

    func testHotDemandGoodsIDsAreUniquedAcrossListingOptions() {
        // 激求のグッズIDは複数の個別募集選択肢を横断して重複排除される。
        let sharedID = UUID()
        let otherID = UUID()
        let signals = makeSignals(
            wantedOptions: [
                makeOption(kind: .condition, matchingGoodsIDs: [sharedID]),
                makeOption(kind: .goods, matchingGoodsIDs: [sharedID, otherID])
            ]
        )
        XCTAssertEqual(
            HomeCandidateDemandPolicy.demandLine(for: signals),
            .hotDemand(goodsIDs: [sharedID, otherID])
        )
    }

    func testListingHotDemandBeatsWishDemand() {
        // 個別募集ヒット（激求）は、ほしいものヒット（求）より優先される。
        let listingID = UUID()
        let wishID = UUID()
        let signals = makeSignals(
            wantedOptions: [makeOption(kind: .condition, matchingGoodsIDs: [listingID])],
            wishMatchedOfferGoodsIDs: [wishID]
        )
        XCTAssertEqual(
            HomeCandidateDemandPolicy.demandLine(for: signals),
            .hotDemand(goodsIDs: [listingID])
        )
    }

    // MARK: - 物流行

    func testLogisticsVenueAndDateWithPostal() {
        let signals = makeSignals(
            postal: true,
            local: true,
            prefecture: true,
            date: true,
            matchedVenue: "新宿",
            matchedDateKeys: ["2030-03-03"]
        )
        XCTAssertEqual(
            HomeCandidateDemandPolicy.logisticsText(for: signals),
            "新宿で3/3に会えそう・郵送OK"
        )
    }

    func testLogisticsPrefectureTierWithoutDate() {
        let signals = makeSignals(
            local: true,
            prefecture: true,
            date: false,
            partnerPrefectures: ["東京都"]
        )
        XCTAssertEqual(
            HomeCandidateDemandPolicy.logisticsText(for: signals),
            "東京で会えそう"
        )
    }

    func testLogisticsPostalTier() {
        let signals = makeSignals(postal: true, shippingFeeNeedsDiscussion: true)
        XCTAssertEqual(
            HomeCandidateDemandPolicy.logisticsText(for: signals),
            "郵送OK・送料は相談"
        )
        XCTAssertEqual(
            HomeCandidateDemandPolicy.logisticsText(for: makeSignals(postal: true)),
            "郵送OK"
        )
    }

    func testLogisticsDiscussTier() {
        XCTAssertEqual(
            HomeCandidateDemandPolicy.logisticsText(for: makeSignals()),
            "交換手段は相談"
        )
    }

    // MARK: - 支払行（定価絡みのみ）

    func testPaymentTextOnlyForCashLine() {
        let cashSignals = makeSignals(
            payment: HomePaymentConditionSignals(
                hasCompatiblePaymentMethod: true,
                partnerMethods: [.paypay, .cashExchange]
            ),
            wantedOptions: [makeOption(kind: .cash, cashAmount: 500)]
        )
        XCTAssertEqual(
            HomeCandidateDemandPolicy.paymentText(for: cashSignals),
            "PayPay・現金交換OK"
        )

        let cashNoMethods = makeSignals(wantedOptions: [makeOption(kind: .cash)])
        XCTAssertEqual(
            HomeCandidateDemandPolicy.paymentText(for: cashNoMethods),
            "支払方法は要相談"
        )

        let hotSignals = makeSignals(
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: true, partnerMethods: [.paypay]),
            wantedOptions: [makeOption(kind: .goods, matchingGoodsIDs: [UUID()])]
        )
        XCTAssertNil(HomeCandidateDemandPolicy.paymentText(for: hotSignals))
    }

    // MARK: - 並び順（激求含む塊 > 求 > 定価 > 合致なし）

    func testSortedCandidatesOrderByDemandRank() {
        let discuss = makeCandidate(title: "相談", goodsSignals: [makeSignals()])
        let cash = makeCandidate(
            title: "定価",
            goodsSignals: [makeSignals(wantedOptions: [makeOption(kind: .cash, cashAmount: 900)])]
        )
        let demand = makeCandidate(
            title: "求",
            goodsSignals: [makeSignals(wishMatchedOfferGoodsIDs: [UUID()])]
        )
        let hot = makeCandidate(
            title: "激求",
            goodsSignals: [makeSignals(wantedOptions: [makeOption(kind: .goods, matchingGoodsIDs: [UUID()])])]
        )

        let sorted = HomeCandidateDemandPolicy.sortedCandidates([discuss, cash, demand, hot])
        XCTAssertEqual(sorted.map(\.title), ["激求", "求", "定価", "相談"])
    }

    func testSortTieBreaksByDemandGoodsCountThenOriginalOrder() {
        let single = makeCandidate(
            title: "求1件",
            goodsSignals: [makeSignals(wishMatchedOfferGoodsIDs: [UUID()])]
        )
        let double = makeCandidate(
            title: "求2件",
            goodsSignals: [
                makeSignals(wishMatchedOfferGoodsIDs: [UUID()]),
                makeSignals(wishMatchedOfferGoodsIDs: [UUID()])
            ]
        )
        let sorted = HomeCandidateDemandPolicy.sortedCandidates([single, double])
        XCTAssertEqual(sorted.map(\.title), ["求2件", "求1件"])
    }

    func testOrderedGoodsByDemandPutsHighestRankFirst() {
        let candidate = makeCandidate(
            title: "塊",
            goodsSignals: [
                makeSignals(),
                makeSignals(wantedOptions: [makeOption(kind: .goods, matchingGoodsIDs: [UUID()])])
            ]
        )
        let ordered = HomeCandidateDemandPolicy.orderedGoodsByDemand(of: candidate)
        XCTAssertEqual(ordered.map(\.id), [candidate.goods[1].id, candidate.goods[0].id])
    }

    // MARK: - Helpers

    private func makeOption(
        kind: HomeIndividualListingWantedOption.Kind,
        matchingGoodsIDs: [UUID] = [],
        cashAmount: Int? = nil
    ) -> HomeIndividualListingWantedOption {
        HomeIndividualListingWantedOption(
            id: UUID(),
            listingID: UUID(),
            position: 0,
            title: "選択肢",
            kind: kind,
            goodsIDs: kind == .goods ? matchingGoodsIDs : [],
            matchingGoodsIDs: matchingGoodsIDs,
            cashAmount: cashAmount
        )
    }

    private func makeSignals(
        postal: Bool = false,
        local: Bool = false,
        prefecture: Bool = false,
        date: Bool = false,
        shippingFeeNeedsDiscussion: Bool = false,
        payment: HomePaymentConditionSignals = .none,
        partnerPrefectures: Set<String> = [],
        matchedVenue: String? = nil,
        matchedDateKeys: Set<String> = [],
        wantedOptions: [HomeIndividualListingWantedOption] = [],
        wishMatchedOfferGoodsIDs: [UUID] = [],
        partnerLookingForText: String? = nil
    ) -> HomeCandidateConditionSignals {
        HomeCandidateConditionSignals(
            goods: HomeGoodsConditionSignals(
                hasIndividualListingHit: !wantedOptions.isEmpty,
                hasWishHit: !wishMatchedOfferGoodsIDs.isEmpty
            ),
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: postal,
                localExchangeSelected: local,
                prefectureMatches: prefecture,
                dateMatches: date,
                shippingFeeNeedsDiscussion: shippingFeeNeedsDiscussion,
                partnerLocalPrefectures: partnerPrefectures,
                matchedVenue: matchedVenue,
                matchedLocalDateKeys: matchedDateKeys
            ),
            payment: payment,
            individualListingSelection: wantedOptions.isEmpty
                ? nil
                : HomeIndividualListingSelectionContext(wantedOptions: wantedOptions),
            wishMatchedOfferGoodsIDs: wishMatchedOfferGoodsIDs,
            partnerLookingForText: partnerLookingForText
        )
    }

    private func makeCandidate(
        title: String,
        goodsSignals: [HomeCandidateConditionSignals]
    ) -> HomeDiscoveryCandidate {
        let goods = [
            HomeDiscoveryFixtures.sanaLavender,
            HomeDiscoveryFixtures.sanaBadge,
            HomeDiscoveryFixtures.sanaStand,
            HomeDiscoveryFixtures.sanaKeychain
        ]
        let usedGoods = Array(goods.prefix(goodsSignals.count))
        var byID: [UUID: HomeCandidateConditionSignals] = [:]
        for (index, goodsItem) in usedGoods.enumerated() {
            byID[goodsItem.id] = goodsSignals[index]
        }
        let primary = goodsSignals.first ?? makeSignals()
        return HomeDiscoveryCandidate(
            id: UUID(),
            title: title,
            signals: primary,
            conditionSignalsByGoodsID: byID,
            sheet: .goodsHit(HomeDiscoverySheetPayload(goods: usedGoods.first ?? goods[0], signals: primary)),
            goods: usedGoods
        )
    }
}
