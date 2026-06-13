@testable import MegrumApp
import CoreGraphics
import MegrumCore
import XCTest

final class HomeDiscoveryMatchPolicyTests: XCTestCase {
    func testGoodsConditionFollowsRequestedPriority() {
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.goodsCondition(
                for: .init(hasIndividualListingHit: true, hasWishHit: true)
            ),
            .direct
        )
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.goodsCondition(
                for: .init(hasIndividualListingHit: true, hasWishHit: false)
            ),
            .direct
        )
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.goodsCondition(
                for: .init(hasIndividualListingHit: false, hasWishHit: true)
            ),
            .wish
        )
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.goodsCondition(
                for: .init(hasIndividualListingHit: false, hasWishHit: false)
            ),
            .none
        )
    }

    func testHomeCandidateLinkCountsClampAndSumWishAndListings() {
        let counts = HomeCandidateLinkCounts(wishCount: 4, listingCount: 2)
        XCTAssertEqual(counts.totalCount, 6)

        let clamped = HomeCandidateLinkCounts(wishCount: -1, listingCount: -2)
        XCTAssertEqual(clamped.totalCount, 0)
    }

    func testExchangeConditionFollowsRequestedPriority() {
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.exchangeCondition(
                for: .init(
                    postalAcceptedByBoth: true,
                    localExchangeSelected: false,
                    prefectureMatches: false,
                    dateMatches: false
                )
            ),
            .exact
        )
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.exchangeCondition(
                for: .init(
                    postalAcceptedByBoth: false,
                    localExchangeSelected: true,
                    prefectureMatches: true,
                    dateMatches: true
                )
            ),
            .exact
        )
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.exchangeCondition(
                for: .init(
                    postalAcceptedByBoth: false,
                    localExchangeSelected: true,
                    prefectureMatches: true,
                    dateMatches: false
                )
            ),
            .possible
        )
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.exchangeCondition(
                for: .init(
                    postalAcceptedByBoth: false,
                    localExchangeSelected: true,
                    prefectureMatches: false,
                    dateMatches: true
                )
            ),
            .warning
        )
    }

    func testGoodsArtworkLayoutKeepsShapesInsideThumbnailFrames() {
        let sizes = [
            CGSize(width: 40, height: 44),
            CGSize(width: 46, height: 46),
            CGSize(width: 82, height: 112),
            CGSize(width: 118, height: 144)
        ]

        for size in sizes {
            let unit = HomeGoodsArtworkLayout.unit(in: size)
            let portraitHead = HomeGoodsArtworkLayout.portraitHeadDiameter(in: size)
            let portraitBody = HomeGoodsArtworkLayout.portraitBodySize(in: size)
            XCTAssertLessThanOrEqual(portraitHead, size.width)
            XCTAssertLessThanOrEqual(portraitHead + portraitBody.height + max(2, unit * 0.06), size.height)

            let badge = HomeGoodsArtworkLayout.badgeDiameter(in: size)
            XCTAssertLessThanOrEqual(badge, size.width)
            XCTAssertLessThanOrEqual(badge, size.height)

            let standFigure = HomeGoodsArtworkLayout.standFigureSize(in: size)
            let standBase = HomeGoodsArtworkLayout.standBaseSize(in: size)
            XCTAssertLessThanOrEqual(max(standFigure.width, standBase.width), size.width)
            XCTAssertLessThanOrEqual(standFigure.height + standBase.height, size.height)

            let ring = HomeGoodsArtworkLayout.keychainRingDiameter(in: size)
            let heart = HomeGoodsArtworkLayout.keychainHeartSize(in: size)
            XCTAssertLessThanOrEqual(max(ring, heart), size.width)
            XCTAssertLessThanOrEqual(ring + heart - max(1, unit * 0.04), size.height)

            let plushHead = HomeGoodsArtworkLayout.plushHeadDiameter(in: size)
            let plushBody = HomeGoodsArtworkLayout.plushBodySize(in: size)
            XCTAssertLessThanOrEqual(max(plushHead, plushBody.width), size.width)
            XCTAssertLessThanOrEqual(plushHead + plushBody.height - max(1, unit * 0.02), size.height)
        }
    }

    func testHomeRotaryGoodsStackLeavesSideCardsVisible() {
        XCTAssertGreaterThanOrEqual(
            HomeRotaryGoodsStackLayout.visibleSidePeek(stageWidth: 154, stageHeight: 158),
            20
        )
        XCTAssertGreaterThanOrEqual(
            HomeRotaryGoodsStackLayout.visibleSidePeek(stageWidth: 104, stageHeight: 118),
            10
        )
    }

    func testHomeRotaryGoodsStackUsesCompactHeroWidth() {
        XCTAssertLessThan(
            HomeRotaryGoodsStackLayout.heroWidth(stageWidth: 154),
            154 * 0.72
        )
    }

    func testHomeRotaryGoodsStackExpandsOrbitForPeek() {
        XCTAssertGreaterThan(
            HomeRotaryGoodsStackLayout.expandedStageWidth(154),
            154
        )
    }

    func testHomeDiscoveryUserTagTitleUsesActualTagNotGoodsType() {
        let ownerID = UUID(uuidString: "00000000-0000-0000-0000-000000000501")!
        let cardGoodsTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000502")!
        let item = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000503")!,
            ownerID: ownerID,
            goodsTypeID: cardGoodsTypeID,
            title: "ニンニン トレカ",
            tags: [
                GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000504")!, name: "トレカ"),
                GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000505")!, name: "aespa")
            ]
        )

        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: [item],
            source: .userTag,
            goodsTypes: [
                GoodsType(id: cardGoodsTypeID, name: "トレカ", category: "card", displayOrder: 1)
            ],
            conditionSignalsByItemID: [:]
        )

        XCTAssertEqual(candidates.first?.title, "ニンニン×#aespa")
        XCTAssertEqual(candidates.first?.goods.first?.displayTags, ["#aespa"])
    }
}
