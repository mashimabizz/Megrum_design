@testable import MegrumApp
import MegrumCore
import XCTest

final class HomeCandidateSummaryPolicyTests: XCTestCase {
    // MARK: - 強タグ

    func testPerfectTagRequiresDirectExactAndPaymentOK() {
        let signals = makeSignals(
            listingHit: true,
            local: true,
            prefecture: true,
            date: true,
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: true)
        )
        XCTAssertEqual(HomeCandidateSummaryPolicy.strongTag(for: signals), .perfect)
        XCTAssertEqual(HomeCandidateSummaryPolicy.rank(for: signals), 4)
    }

    func testDirectWithPaymentMismatchFallsBackToDesignated() {
        let signals = makeSignals(
            listingHit: true,
            local: true,
            prefecture: true,
            date: true,
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: false, status: .methodMismatch)
        )
        XCTAssertEqual(HomeCandidateSummaryPolicy.strongTag(for: signals), .designated)
    }

    func testLocalExactWithoutGoodsHitIsMeetable() {
        let signals = makeSignals(local: true, prefecture: true, date: true)
        XCTAssertEqual(HomeCandidateSummaryPolicy.strongTag(for: signals), .meetable)
    }

    func testPostalOnlyExactUsesPostalTag() {
        let signals = makeSignals(postal: true)
        XCTAssertEqual(HomeCandidateSummaryPolicy.strongTag(for: signals), .postalOK)
    }

    func testWishOnlyIsWishMatch() {
        let signals = makeSignals(wishHit: true, local: true, prefecture: false, date: false)
        XCTAssertEqual(HomeCandidateSummaryPolicy.strongTag(for: signals), .wishMatch)
    }

    func testNoSignalsIsDiscuss() {
        let signals = makeSignals()
        XCTAssertEqual(HomeCandidateSummaryPolicy.strongTag(for: signals), .discuss)
        XCTAssertEqual(HomeCandidateSummaryPolicy.rank(for: signals), 0)
    }

    // MARK: - 結論一文

    func testPerfectSummaryUsesVenueAndDate() {
        let signals = makeSignals(
            listingHit: true,
            local: true,
            prefecture: true,
            date: true,
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: true),
            matchedVenue: "横浜アリーナ",
            matchedDateKeys: ["2030-07-12"]
        )
        XCTAssertEqual(
            HomeCandidateSummaryPolicy.summaryText(for: signals),
            "あなたのグッズを指名中・横浜アリーナで7/12に会えそう"
        )
    }

    func testLocalExactWithoutVenueFallsBackToShortPrefecture() {
        let signals = makeSignals(
            local: true,
            prefecture: true,
            date: true,
            partnerPrefectures: ["大阪府"],
            matchedDateKeys: ["2030-07-12"]
        )
        XCTAssertEqual(
            HomeCandidateSummaryPolicy.summaryText(for: signals),
            "大阪で7/12に会えそう"
        )
    }

    func testPostalSummary() {
        let signals = makeSignals(wishHit: true, postal: true)
        XCTAssertEqual(
            HomeCandidateSummaryPolicy.summaryText(for: signals),
            "あなたのほしいものと一致・郵送OK"
        )
    }

    func testDateDiscussIncludesPartnerNearestDate() {
        let signals = makeSignals(
            local: true,
            prefecture: true,
            date: false,
            partnerPrefectures: ["東京都"],
            partnerDateKeys: ["2030-08-01"]
        )
        XCTAssertEqual(
            HomeCandidateSummaryPolicy.summaryText(for: signals),
            "東京で会える・日程は相談（相手: 8/1）"
        )
    }

    func testPlaceDiscussIncludesPartnerPrefecture() {
        let signals = makeSignals(
            local: true,
            prefecture: false,
            date: true,
            partnerPrefectures: ["福岡県"],
            matchedDateKeys: ["2030-07-02"]
        )
        XCTAssertEqual(
            HomeCandidateSummaryPolicy.summaryText(for: signals),
            "7/2に会える・場所は相談（相手: 福岡）"
        )
    }

    func testPaymentMismatchReplacesExchangeClauseWhenExact() {
        let signals = makeSignals(
            listingHit: true,
            local: true,
            prefecture: true,
            date: true,
            payment: HomePaymentConditionSignals(
                hasCompatiblePaymentMethod: false,
                status: .methodMismatch,
                partnerMethods: [.paypay]
            )
        )
        XCTAssertEqual(
            HomeCandidateSummaryPolicy.summaryText(for: signals),
            "あなたのグッズを指名中・支払い方法だけ確認（相手: PayPay）"
        )
    }

    func testPaymentUnknownIsNotMentioned() {
        let signals = makeSignals(
            wishHit: true,
            postal: true,
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: false, status: .partnerUnset)
        )
        XCTAssertEqual(
            HomeCandidateSummaryPolicy.summaryText(for: signals),
            "あなたのほしいものと一致・郵送OK"
        )
    }

    func testFallbackSummaryWhenNothingMatches() {
        XCTAssertEqual(
            HomeCandidateSummaryPolicy.summaryText(for: makeSignals()),
            "交換方法は打診で相談"
        )
    }

    func testSummaryKeepsPartnerContextWhileWithinLimit() {
        let signals = makeSignals(
            listingHit: true,
            local: true,
            prefecture: true,
            date: false,
            partnerPrefectures: ["神奈川県"],
            partnerDateKeys: ["2030-08-01", "2030-08-02"]
        )
        let summary = HomeCandidateSummaryPolicy.summaryText(for: signals)
        XCTAssertEqual(summary, "あなたのグッズを指名中・神奈川で会える・日程は相談（相手: 8/1他）")
        XCTAssertLessThanOrEqual(summary.count, HomeCandidateSummaryPolicy.maxSummaryLength)
    }

    // MARK: - 県名短縮

    func testShortPrefectureName() {
        XCTAssertEqual(HomeCandidateExchangePolicy.shortPrefectureName("東京都"), "東京")
        XCTAssertEqual(HomeCandidateExchangePolicy.shortPrefectureName("大阪府"), "大阪")
        XCTAssertEqual(HomeCandidateExchangePolicy.shortPrefectureName("神奈川県"), "神奈川")
        XCTAssertEqual(HomeCandidateExchangePolicy.shortPrefectureName("北海道"), "北海道")
    }

    // MARK: - ソート

    func testSortedCandidatesPrefersMoreEasyGoodsThenBestRank() {
        let easyPair = makeCandidate(
            title: "easy-2",
            goodsSignals: [
                makeSignals(local: true, prefecture: true, date: true),
                makeSignals(local: true, prefecture: true, date: true)
            ]
        )
        let bestSingle = makeCandidate(
            title: "best-1",
            goodsSignals: [
                makeSignals(
                    listingHit: true,
                    local: true,
                    prefecture: true,
                    date: true,
                    payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: true)
                ),
                makeSignals()
            ]
        )
        let discussOnly = makeCandidate(
            title: "discuss",
            goodsSignals: [makeSignals()]
        )

        let sorted = HomeCandidateSummaryPolicy.sortedCandidates([discussOnly, bestSingle, easyPair])
        XCTAssertEqual(sorted.map(\.title), ["easy-2", "best-1", "discuss"])
    }

    func testOrderedGoodsByRankPutsRepresentativeFirst() {
        let weak = makeSignals()
        let strong = makeSignals(listingHit: true, local: true, prefecture: true, date: true)
        let candidate = makeCandidate(title: "mixed", goodsSignals: [weak, strong])

        let ordered = HomeCandidateSummaryPolicy.orderedGoodsByRank(of: candidate)
        XCTAssertEqual(ordered.first?.id, candidate.goods[1].id)
    }

    // MARK: - Helpers

    private func makeSignals(
        listingHit: Bool = false,
        wishHit: Bool = false,
        postal: Bool = false,
        local: Bool = false,
        prefecture: Bool = false,
        date: Bool = false,
        prefectureUnset: Bool = false,
        payment: HomePaymentConditionSignals = .none,
        partnerPrefectures: Set<String> = [],
        partnerDateKeys: Set<String> = [],
        matchedVenue: String? = nil,
        matchedDateKeys: Set<String> = []
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
                dateMatches: date,
                prefectureUnset: prefectureUnset,
                partnerLocalPrefectures: partnerPrefectures,
                partnerLocalDateKeys: partnerDateKeys,
                matchedVenue: matchedVenue,
                matchedLocalDateKeys: matchedDateKeys
            ),
            payment: payment
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
        return HomeDiscoveryCandidate(
            id: UUID(),
            title: title,
            signals: goodsSignals.first ?? makeSignals(),
            conditionSignalsByGoodsID: byID,
            sheet: .wishHit(
                HomeDiscoverySheetPayload(
                    goods: usedGoods.first ?? HomeDiscoveryFixtures.sanaLavender,
                    signals: goodsSignals.first ?? makeSignals()
                )
            ),
            goods: usedGoods
        )
    }
}
