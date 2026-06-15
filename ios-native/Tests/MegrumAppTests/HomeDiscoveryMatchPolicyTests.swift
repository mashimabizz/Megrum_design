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

    func testListingSelectionPolicyFollowsIndividualListingLogic() {
        XCTAssertEqual(
            HomeListingSelectionPolicy.initialWantedIndices(itemCount: 3, logic: .all),
            [0, 1, 2]
        )
        XCTAssertEqual(
            HomeListingSelectionPolicy.initialWantedIndices(itemCount: 3, logic: .one),
            []
        )
        XCTAssertEqual(
            HomeListingSelectionPolicy.wantedIndices(
                afterTapping: 1,
                current: [0],
                itemCount: 3,
                logic: .one
            ),
            [1]
        )
        XCTAssertEqual(
            HomeListingSelectionPolicy.wantedIndices(
                afterTapping: 1,
                current: [0],
                itemCount: 3,
                logic: .all
            ),
            [0, 1, 2]
        )
        XCTAssertEqual(
            HomeListingSelectionPolicy.offerIndices(
                afterTapping: 2,
                current: [0],
                itemCount: 3,
                logic: .all
            ),
            [0, 2]
        )
        XCTAssertEqual(
            HomeListingSelectionPolicy.offerIndices(
                afterTapping: 2,
                current: [0],
                itemCount: 3,
                logic: .one
            ),
            [2]
        )
    }

    func testOtherExchangePolicyExcludesCurrentSheetGoods() {
        let selectedGoods = HomeDiscoveryFixtures.momoFanmi
        let visibleGoods = HomeOtherExchangePolicy.visibleGoods(
            HomeDiscoveryFixtures.otherListingHit,
            excluding: [selectedGoods.id]
        )

        XCTAssertFalse(visibleGoods.map(\.id).contains(selectedGoods.id))
        XCTAssertEqual(visibleGoods.count, HomeDiscoveryFixtures.otherListingHit.count - 1)
    }

    func testMiiPreviewListingSelectionIncludesGoodsConditionAndCashOptions() async throws {
        let sections = try await PreviewMegrumRepository().loadHomeCandidateSections()
        let partnerItem = try XCTUnwrap(
            NativePreviewData.homeMatchedItems.first { $0.ownerID == NativePreviewData.partnerID }
        )
        let selection = try XCTUnwrap(
            sections.conditionSignalsByItemID[partnerItem.id]?.individualListingSelection
        )

        XCTAssertEqual(selection.wantedOptions.map(\.kind), [.goods, .condition, .cash])
        XCTAssertEqual(selection.wantedOptions.last?.cashAmount, 1_500)
        XCTAssertTrue(selection.wantedOptions.contains { $0.kind == .condition && !$0.matchingGoodsIDs.isEmpty })
    }

    func testHomeDiscoveryTitleParserKeepsMemberAndTagRulesCentralized() {
        XCTAssertEqual(HomeDiscoveryTitleParser.memberName(from: "サナ 2026 LIVE"), "サナ")
        XCTAssertEqual(HomeDiscoveryTitleParser.memberName(from: " モモ × #ファンミ "), "モモ")
        XCTAssertEqual(HomeDiscoveryTitleParser.memberTagTitle(from: "サナ 2026 LIVE"), "サナ × 2026 LIVE")
        XCTAssertEqual(HomeDiscoveryTitleParser.memberTagTitle(from: "モモ×#ファンミ"), "モモ × #ファンミ")
        XCTAssertEqual(HomeDiscoveryTitleParser.comparableMemberName(from: " SANA × #live "), "sana")
    }

    func testCandidateSorterPrioritizesDirectMatchBeforeTitleOrder() {
        let ownerID = UUID(uuidString: "00000000-0000-0000-0000-000000000571")!
        let directItem = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000572")!,
            ownerID: ownerID,
            title: "Z Direct"
        )
        let wishItem = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000573")!,
            ownerID: ownerID,
            title: "A Wish"
        )
        let sorter = HomeDiscoveryCandidateSorter(conditionSignalsByItemID: [
            directItem.id: HomeDiscoveryFixtures.signals(
                listingHit: true,
                wishHit: true,
                postal: false,
                local: true,
                prefecture: true,
                date: true
            ),
            wishItem.id: HomeDiscoveryFixtures.signals(
                listingHit: false,
                wishHit: true,
                postal: false,
                local: true,
                prefecture: true,
                date: true
            )
        ])

        XCTAssertEqual(
            [wishItem, directItem].sorted(by: sorter.areInCandidateOrder).map(\.id),
            [directItem.id, wishItem.id]
        )
    }

    func testCandidateSorterFallsBackToTitleWhenRanksTie() {
        let ownerID = UUID(uuidString: "00000000-0000-0000-0000-000000000574")!
        let first = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000575")!,
            ownerID: ownerID,
            title: "A Goods"
        )
        let second = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000576")!,
            ownerID: ownerID,
            title: "B Goods"
        )
        let sorter = HomeDiscoveryCandidateSorter(conditionSignalsByItemID: [:])

        XCTAssertEqual(
            [second, first].sorted(by: sorter.areInCandidateOrder).map(\.id),
            [first.id, second.id]
        )
    }

    func testHavesSorterPrioritizesListingLinksBeforeWishLinks() {
        let ownerID = UUID(uuidString: "00000000-0000-0000-0000-000000000577")!
        let listingLinked = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000578")!,
            ownerID: ownerID,
            title: "Z Listing"
        )
        let wishLinked = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000579")!,
            ownerID: ownerID,
            title: "A Wish"
        )
        let sorter = HomeDiscoveryCandidateSorter(conditionSignalsByItemID: [
            listingLinked.id: HomeDiscoveryFixtures.signals(
                listingHit: true,
                wishHit: true,
                postal: false,
                local: true,
                prefecture: true,
                date: true,
                wishCount: 0,
                listingCount: 1
            ),
            wishLinked.id: HomeDiscoveryFixtures.signals(
                listingHit: true,
                wishHit: true,
                postal: false,
                local: true,
                prefecture: true,
                date: true,
                wishCount: 5,
                listingCount: 0
            )
        ])

        XCTAssertEqual(
            [wishLinked, listingLinked].sorted(by: sorter.areInHavesOrder).map(\.id),
            [listingLinked.id, wishLinked.id]
        )
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
            .exact
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
            .possible
        )
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.exchangeCondition(
                for: .init(
                    postalAcceptedByBoth: false,
                    localExchangeSelected: false,
                    prefectureMatches: false,
                    dateMatches: true
                )
            ),
            .warning
        )
    }

    func testPaymentConditionUsesSharedSupportedMethodsOnly() {
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.paymentCondition(
                for: .init(hasCompatiblePaymentMethod: true)
            ),
            .compatible
        )
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.paymentCondition(
                for: .init(hasCompatiblePaymentMethod: false)
            ),
            .warning
        )
    }

    func testConditionTagTitlesUseCompactHomeLabels() {
        XCTAssertEqual(HomeGoodsCondition.direct.floatingTagTitle, "グッズ◎")
        XCTAssertEqual(HomeGoodsCondition.wish.floatingTagTitle, "グッズ○")
        XCTAssertEqual(HomeGoodsCondition.none.floatingTagTitle, "グッズ▲")
        XCTAssertEqual(HomeExchangeCondition.exact.floatingTagTitle, "交換◎")
        XCTAssertEqual(HomeExchangeCondition.possible.floatingTagTitle, "交換○")
        XCTAssertEqual(HomeExchangeCondition.warning.floatingTagTitle, "交換▲")
        XCTAssertEqual(HomePaymentCondition.compatible.floatingTagTitle, "支払○")
        XCTAssertEqual(HomePaymentCondition.warning.floatingTagTitle, "支払▲")
    }

    func testCandidateConditionTagsFollowSelectedGoodsSignals() throws {
        let ownerID = UUID(uuidString: "00000000-0000-0000-0000-000000000521")!
        let first = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000522")!,
            ownerID: ownerID,
            title: "サナ トレカ",
            tags: [
                GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000524")!, name: "2026 LIVE")
            ]
        )
        let second = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000523")!,
            ownerID: ownerID,
            title: "サナ 缶バッジ",
            tags: [
                GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000525")!, name: "2026 LIVE")
            ]
        )
        let firstSignals = HomeCandidateConditionSignals(
            goods: .init(hasIndividualListingHit: true, hasWishHit: true),
            exchange: .init(
                postalAcceptedByBoth: true,
                localExchangeSelected: false,
                prefectureMatches: false,
                dateMatches: false
            ),
            payment: .init(hasCompatiblePaymentMethod: true)
        )
        let secondSignals = HomeCandidateConditionSignals(
            goods: .init(hasIndividualListingHit: false, hasWishHit: true),
            exchange: .init(
                postalAcceptedByBoth: false,
                localExchangeSelected: true,
                prefectureMatches: false,
                dateMatches: false
            ),
            payment: .init(hasCompatiblePaymentMethod: false)
        )

        let candidate = try XCTUnwrap(HomeDiscoveryCandidateFactory.candidates(
            from: [first, second],
            source: .userTag,
            conditionSignalsByItemID: [
                first.id: firstSignals,
                second.id: secondSignals
            ]
        ).first)
        let secondGoods = try XCTUnwrap(candidate.goods.first { $0.id == second.id })

        XCTAssertEqual(
            candidate.conditionTags(for: candidate.goods.first),
            HomeConditionTagSet(goods: .direct, exchange: .exact, payment: .compatible)
        )
        XCTAssertEqual(
            candidate.conditionTags(for: secondGoods),
            HomeConditionTagSet(goods: .wish, exchange: .possible, payment: .warning)
        )

        switch candidate.sheet(selectedGoods: secondGoods) {
        case .wishHit(let payload):
            XCTAssertEqual(payload.goods.id, second.id)
            XCTAssertEqual(payload.conditionTags, HomeConditionTagSet(goods: .wish, exchange: .possible, payment: .warning))
        default:
            XCTFail("Selected wish-level goods should open the wish hit sheet.")
        }
    }

    func testHavesCandidateSheetCarriesTappedGoodsIntoLookupPayload() throws {
        let ownerID = UUID(uuidString: "00000000-0000-0000-0000-000000000531")!
        let goodsTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000532")!
        let havesItem = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000533")!,
            ownerID: ownerID,
            groupID: UUID(uuidString: "00000000-0000-0000-0000-000000000534")!,
            memberID: UUID(uuidString: "00000000-0000-0000-0000-000000000535")!,
            goodsTypeID: goodsTypeID,
            title: "サナ 2026 LIVE",
            tags: [
                GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000536")!, name: "2026 LIVE"),
                GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000537")!, name: "トレカ")
            ]
        )

        let candidate = try XCTUnwrap(HomeDiscoveryCandidateFactory.candidates(
            from: [havesItem],
            source: .haves,
            goodsTypes: [
                GoodsType(id: goodsTypeID, name: "トレカ", category: "card", displayOrder: 1)
            ],
            conditionSignalsByItemID: [:]
        ).first)

        guard case .havesLookup(let payload) = candidate.sheet else {
            return XCTFail("Haves candidates should open the haves lookup sheet.")
        }
        XCTAssertEqual(payload.offeredGoods.id, havesItem.id)
        XCTAssertEqual(payload.offeredGoods.rawTagNames, ["2026 live"])
    }

    func testSelectedMatchSheetKeepsPreferredOfferGoodsID() throws {
        let preferredOfferID = UUID(uuidString: "00000000-0000-0000-0000-000000000541")!
        let firstGoods = HomeDiscoveryFixtures.selectedYellow
        let secondGoods = HomeDiscoveryFixtures.momoFanmi
        let candidate = HomeDiscoveryCandidate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000542")!,
            title: "モモ×#ファンミ",
            signals: HomeCandidateConditionSignalDefaults.matched(index: 0),
            conditionSignalsByGoodsID: [
                secondGoods.id: HomeCandidateConditionSignalDefaults.possible(index: 1)
            ],
            sheet: .goodsHit(
                HomeDiscoverySheetPayload(
                    goods: firstGoods,
                    signals: HomeCandidateConditionSignalDefaults.matched(index: 0),
                    preferredOfferGoodsID: preferredOfferID
                )
            ),
            goods: [firstGoods, secondGoods]
        )

        switch candidate.sheet(selectedGoods: secondGoods) {
        case .wishHit(let payload):
            XCTAssertEqual(payload.goods.id, secondGoods.id)
            XCTAssertEqual(payload.preferredOfferGoodsID, preferredOfferID)
        default:
            XCTFail("Possible-level selected goods should keep the preferred offer id.")
        }
    }

    func testOtherExchangeWishHitOpensWishSelectionSheet() {
        let wishPayload = HomeExtraHitPayload(
            kind: .wish,
            goods: HomeDiscoveryFixtures.momoFanmi,
            signals: HomeCandidateConditionSignalDefaults.possible(index: 0)
        )
        let listingPayload = HomeExtraHitPayload(
            kind: .listing,
            goods: HomeDiscoveryFixtures.momoFanmi,
            signals: HomeCandidateConditionSignalDefaults.matched(index: 0)
        )

        switch wishPayload.nestedSheet {
        case .wishHit(let payload):
            XCTAssertEqual(payload.goods.id, wishPayload.goods.id)
            XCTAssertEqual(payload.signals, wishPayload.signals)
        default:
            XCTFail("Wish hits from the extra row should use the normal wish-hit selection sheet.")
        }

        switch listingPayload.nestedSheet {
        case .extraListingHit(let payload):
            XCTAssertEqual(payload.id, listingPayload.id)
        default:
            XCTFail("Listing hits should keep the listing-specific add-candidate sheet.")
        }
    }

    func testHomeProposalRouteUsesSelectedSheetPayloadWhenHomeListsDoNotContainTappedGoods() throws {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000551")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000552")!
        let receiverGoodsID = UUID(uuidString: "00000000-0000-0000-0000-000000000553")!
        let senderGoodsID = UUID(uuidString: "00000000-0000-0000-0000-000000000554")!

        let receiverGoods = HomeMockGoods(
            id: receiverGoodsID,
            ownerID: partnerID,
            groupID: nil,
            memberID: nil,
            title: "サナ 2026 LIVE",
            subtitle: "#2026 LIVE",
            displayTags: ["#2026 LIVE"],
            rawTagNames: ["2026 live"],
            ownerPaymentMethods: [.paypay],
            ownerPaymentNote: nil,
            shape: .portrait,
            palette: [],
            symbol: "サ",
            imageURL: nil
        )
        let selection = HomeDiscoveryProposalSelection(
            receiverGoodsID: receiverGoodsID,
            senderGoodsIDs: [senderGoodsID],
            matchType: .perfect,
            receiverGoods: receiverGoods,
            exchangeMethod: .mail
        )
        let inventory = [
            GoodsItem(
                id: senderGoodsID,
                ownerID: viewerID,
                title: "モモ ファンミ",
                quantity: 1
            )
        ]

        let route = try XCTUnwrap(
            HomeDiscoveryProposalRouteResolver.route(
                selection: selection,
                viewerID: viewerID,
                matchedItems: [],
                possibleItems: [],
                inventoryItems: inventory
            )
        )

        XCTAssertEqual(route.item.id, receiverGoodsID)
        XCTAssertEqual(route.item.ownerID, partnerID)
        XCTAssertEqual(route.receiverGoodsIDs, [receiverGoodsID])
        XCTAssertEqual(route.senderGoodsIDs, [senderGoodsID])
        XCTAssertEqual(route.matchType, .perfect)
        XCTAssertEqual(route.initialExchangeMethod, .mail)
        XCTAssertEqual(route.initialStep, .give)
    }

    func testHomeProposalRouteKeepsLocalExchangeButStartsAtSelection() throws {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000555")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000556")!
        let receiverGoodsID = UUID(uuidString: "00000000-0000-0000-0000-000000000557")!
        let selection = HomeDiscoveryProposalSelection(
            receiverGoodsID: receiverGoodsID,
            senderGoodsIDs: [],
            matchType: .forward,
            receiverGoods: HomeMockGoods(
                id: receiverGoodsID,
                ownerID: partnerID,
                title: "サナ",
                subtitle: "",
                displayTags: [],
                rawTagNames: [],
                ownerPaymentMethods: [],
                ownerPaymentNote: nil,
                shape: .portrait,
                palette: [],
                symbol: "サ",
                imageURL: nil
            ),
            exchangeMethod: .hand
        )

        let route = try XCTUnwrap(
            HomeDiscoveryProposalRouteResolver.route(
                selection: selection,
                viewerID: viewerID,
                matchedItems: [],
                possibleItems: [],
                inventoryItems: []
            )
        )

        XCTAssertEqual(route.initialExchangeMethod, .hand)
        XCTAssertEqual(route.initialStep, .give)
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

        XCTAssertEqual(candidates.first?.title, "ニンニン × #aespa")
        XCTAssertEqual(candidates.first?.goods.first?.displayTags, ["#aespa"])
    }

    func testHomeDiscoveryUserTagCandidatesGroupByMemberAndTagAcrossGoodsTypes() throws {
        let ownerID = UUID(uuidString: "00000000-0000-0000-0000-000000000551")!
        let memberID = UUID(uuidString: "00000000-0000-0000-0000-000000000552")!
        let tradingCardTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000553")!
        let acrylicStandTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000554")!
        let liveTradingCard = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000555")!,
            ownerID: ownerID,
            memberID: memberID,
            goodsTypeID: tradingCardTypeID,
            title: "モモ トレカ",
            tags: [
                GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000556")!, name: "2026 LIVE"),
                GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000557")!, name: "トレカ")
            ]
        )
        let liveAcrylicStand = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000558")!,
            ownerID: ownerID,
            memberID: memberID,
            goodsTypeID: acrylicStandTypeID,
            title: "モモ アクスタ",
            tags: [
                GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000559")!, name: "2026 LIVE"),
                GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000560")!, name: "アクスタ")
            ]
        )
        let fanMeetingGoods = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000561")!,
            ownerID: ownerID,
            memberID: memberID,
            goodsTypeID: tradingCardTypeID,
            title: "モモ トレカ",
            tags: [
                GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000562")!, name: "ファンミ"),
                GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000563")!, name: "トレカ")
            ]
        )

        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: [liveTradingCard, liveAcrylicStand, fanMeetingGoods],
            source: .userTag,
            goodsTypes: [
                GoodsType(id: tradingCardTypeID, name: "トレカ", category: "card", displayOrder: 1),
                GoodsType(id: acrylicStandTypeID, name: "アクスタ", category: "stand", displayOrder: 2)
            ],
            conditionSignalsByItemID: [:]
        )

        let liveCandidate = try XCTUnwrap(candidates.first)
        XCTAssertEqual(candidates.map(\.title), ["モモ × #2026 LIVE", "モモ × #ファンミ"])
        XCTAssertEqual(liveCandidate.goods.map(\.id), [liveTradingCard.id, liveAcrylicStand.id])
        XCTAssertFalse(liveCandidate.goods.contains { $0.id == fanMeetingGoods.id })
    }

    func testHomeDiscoveryCardTitleUsesSelectedGoodsMemberAndTag() {
        let title = HomeDiscoveryCardTitleFormatter.title(
            for: HomeDiscoveryFixtures.momoFanmi,
            fallback: "メンバー×タグでマッチ",
            style: .memberTag
        )

        XCTAssertEqual(title, "モモ × #ファンミ")
    }

    func testHomeDiscoveryCardTitleUsesMemberOnlyForMemberMatchShelf() {
        let title = HomeDiscoveryCardTitleFormatter.title(
            for: HomeDiscoveryFixtures.sanaLavender,
            fallback: "メンバーでマッチ",
            style: .member
        )

        XCTAssertEqual(title, "サナ")
    }
}
