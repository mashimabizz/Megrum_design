@testable import MegrumApp
import CoreGraphics
import MegrumCore
import XCTest

final class HomeDiscoveryMatchPolicyTests: XCTestCase {
    func testHorizontalSwipeIntentResolverKeepsVerticalScrollPriority() {
        XCTAssertFalse(
            HorizontalSwipeIntentResolver.isHorizontalSwipe(CGSize(width: 18, height: 44)),
            "縦方向が強いドラッグは、グッズ画像上でも親の縦スクロールを優先する。"
        )
        XCTAssertFalse(
            HorizontalSwipeIntentResolver.isHorizontalSwipe(CGSize(width: 10, height: 10)),
            "斜め気味の小さいドラッグはカルーセル切り替えにしない。"
        )
        XCTAssertTrue(
            HorizontalSwipeIntentResolver.isHorizontalSwipe(CGSize(width: -54, height: 12)),
            "横方向が明確なドラッグだけ、複数画像の切り替えに使う。"
        )
    }

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

    func testOtherExchangePolicyRemovesListingHitsFromWishHits() {
        let listingGoods = HomeDiscoveryFixtures.otherListingHit
        let visibleWishGoods = HomeOtherExchangePolicy.visibleWishGoods(
            HomeDiscoveryFixtures.otherWishHit,
            excluding: [],
            listingHitGoods: listingGoods
        )

        XCTAssertTrue(HomeDiscoveryFixtures.otherWishHit.map(\.id).contains(HomeDiscoveryFixtures.plush.id))
        XCTAssertTrue(listingGoods.map(\.id).contains(HomeDiscoveryFixtures.plush.id))
        XCTAssertFalse(visibleWishGoods.map(\.id).contains(HomeDiscoveryFixtures.plush.id))
    }

    func testOtherExchangePolicyRemovesListingPayloadsFromWishPayloads() {
        let listingPayload = HomeExtraHitPayload(
            kind: .listing,
            goods: HomeDiscoveryFixtures.plush,
            signals: HomeDiscoveryFixtures.miiListingHitSignals(index: 0)
        )
        let wishPayloads = [
            HomeExtraHitPayload(
                kind: .wish,
                goods: HomeDiscoveryFixtures.plush,
                signals: HomeCandidateConditionSignalDefaults.possible(index: 0)
            ),
            HomeExtraHitPayload(
                kind: .wish,
                goods: HomeDiscoveryFixtures.momoFanmi,
                signals: HomeCandidateConditionSignalDefaults.possible(index: 1)
            )
        ]

        let visibleWishPayloads = HomeOtherExchangePolicy.visibleWishPayloads(
            wishPayloads,
            excluding: [],
            listingHitPayloads: [listingPayload]
        )

        XCTAssertEqual(visibleWishPayloads.map(\.goods.id), [HomeDiscoveryFixtures.momoFanmi.id])
    }

    func testWishHitOfferGoodsPolicyDoesNotFallbackToAllOwnedGoodsWithoutMatchedWishIDs() {
        let offerGoods = HomeDiscoveryFixtures.offerGoods

        let filtered = HomeWishHitOfferGoodsPolicy.offerGoods(
            viewerOfferGoods: offerGoods,
            matchedOfferGoodsIDs: [],
            preferredOfferGoodsID: nil
        )

        XCTAssertTrue(filtered.isEmpty)
    }

    func testWishHitOfferGoodsPolicyShowsOnlyOfferGoodsMatchedByPartnerWish() {
        let first = HomeDiscoveryFixtures.offerGoods[0]
        let second = HomeDiscoveryFixtures.offerGoods[1]

        let filtered = HomeWishHitOfferGoodsPolicy.offerGoods(
            viewerOfferGoods: [first, second],
            matchedOfferGoodsIDs: [second.id],
            preferredOfferGoodsID: nil
        )

        XCTAssertEqual(filtered.map(\.id), [second.id])
    }

    func testWantedOptionPreviewPolicyUsesConditionMatchingGoodsImages() {
        let conditionOption = HomeDiscoveryFixtures.miiIndividualListingSelection.wantedOptions[1]
        let previews = HomeListingWantedOptionPreviewPolicy.previewGoodsByOptionID(
            options: [conditionOption],
            goodsPool: HomeDiscoveryFixtures.offerGoods
        )

        XCTAssertEqual(previews[conditionOption.id]?.id, HomeDiscoveryFixtures.momoFanmi.id)
    }

    func testWantedOptionPreviewPolicyFallsBackToExactWishGoodsID() {
        let goodsOption = HomeDiscoveryFixtures.miiIndividualListingSelection.wantedOptions[0]
        let previews = HomeListingWantedOptionPreviewPolicy.previewGoodsByOptionID(
            options: [goodsOption],
            goodsPool: [HomeDiscoveryFixtures.sanaLavender]
        )

        XCTAssertEqual(previews[goodsOption.id]?.id, HomeDiscoveryFixtures.sanaLavender.id)
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
        XCTAssertEqual(HomeDiscoveryTitleParser.memberName(from: "サナ 2026 LIVE"), "サナ 2026 LIVE")
        XCTAssertEqual(HomeDiscoveryTitleParser.memberName(from: " モモ × #ファンミ "), "モモ")
        XCTAssertEqual(HomeDiscoveryTitleParser.memberTagTitle(from: "サナ 2026 LIVE"), "サナ 2026 LIVE")
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
            .possible
        )
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.exchangeCondition(
                for: .init(
                    postalAcceptedByBoth: false,
                    localExchangeSelected: true,
                    prefectureMatches: false,
                    dateMatches: false
                )
            ),
            .warning
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

    func testDefaultExchangeSettingsApplyViewerPreferenceBeforePolicy() {
        let rawSignals = HomeExchangeConditionSignals(
            postalAcceptedByBoth: true,
            localExchangeSelected: true,
            prefectureMatches: true,
            dateMatches: false
        )

        let localDateRequired = HomeDefaultExchangeSettings(
            preference: .local,
            requiresSamePrefecture: true,
            requiresDateOverlap: true
        )
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.exchangeCondition(for: localDateRequired.applying(to: rawSignals)),
            .possible
        )

        let localDateFlexible = HomeDefaultExchangeSettings(
            preference: .local,
            requiresSamePrefecture: true,
            requiresDateOverlap: false
        )
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.exchangeCondition(for: localDateFlexible.applying(to: rawSignals)),
            .exact
        )

        let mailOnly = HomeDefaultExchangeSettings(
            preference: .mail,
            requiresSamePrefecture: true,
            requiresDateOverlap: true
        )
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.exchangeCondition(for: mailOnly.applying(to: rawSignals)),
            .exact
        )
    }

    func testDefaultExchangeSettingsSummaryReflectsStoredChoices() {
        XCTAssertEqual(
            HomeDefaultExchangeSettings(
                preference: .both,
                requiresSamePrefecture: true,
                requiresDateOverlap: false
            ).summaryText,
            "現地交換・郵送OK"
        )
        XCTAssertEqual(
            HomeDefaultExchangeSettings(
                preference: .mail,
                requiresSamePrefecture: true,
                requiresDateOverlap: true
            ).summaryText,
            "郵送交換"
        )
    }

    func testDefaultExchangeSettingsRestoresOnlyPreferenceFromStorage() {
        let restored = HomeDefaultExchangeSettings(
            preferenceRawValue: HomeExchangePreference.local.rawValue,
            requiresSamePrefecture: false,
            requiresDateOverlap: true
        )

        XCTAssertEqual(restored.preference, .local)
        XCTAssertEqual(restored.requiresSamePrefecture, HomeDefaultExchangeSettings.standard.requiresSamePrefecture)
        XCTAssertEqual(restored.requiresDateOverlap, HomeDefaultExchangeSettings.standard.requiresDateOverlap)
        XCTAssertEqual(restored.summaryText, "現地交換")

        let fallback = HomeDefaultExchangeSettings(
            preferenceRawValue: "unknown",
            requiresSamePrefecture: false,
            requiresDateOverlap: true
        )
        XCTAssertEqual(fallback.preference, .both)
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
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.paymentCondition(
                for: .init(hasCompatiblePaymentMethod: false, status: .viewerUnset)
            ),
            .unknown
        )
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.paymentCondition(
                for: .init(hasCompatiblePaymentMethod: false, status: .partnerUnset)
            ),
            .unknown
        )
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.paymentCondition(
                for: .init(hasCompatiblePaymentMethod: false, status: .unset)
            ),
            .unknown
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
        XCTAssertEqual(HomePaymentCondition.unknown.floatingTagTitle, "支払?")
        XCTAssertEqual(HomePaymentCondition.warning.floatingTagTitle, "支払▲")
    }

    func testHomeCandidateTagSetHidesExchangeWhenGoodsConditionIsWish() {
        let wishTags = HomeConditionTagSet(
            goods: .wish,
            exchange: .possible,
            payment: .unknown
        )
        XCTAssertFalse(wishTags.homeCandidateShowsExchangeTag)
        XCTAssertEqual(wishTags.homeCandidateAccessibilityText, "グッズ○、支払?")

        let directTags = HomeConditionTagSet(
            goods: .direct,
            exchange: .exact,
            payment: .compatible
        )
        XCTAssertTrue(directTags.homeCandidateShowsExchangeTag)
        XCTAssertEqual(directTags.homeCandidateAccessibilityText, "グッズ◎、交換◎、支払○")
    }

    func testCandidateConditionTagsFollowSelectedGoodsSignals() throws {
        let ownerID = UUID(uuidString: "00000000-0000-0000-0000-000000000521")!
        let memberID = UUID(uuidString: "00000000-0000-0000-0000-000000000526")!
        let first = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000522")!,
            ownerID: ownerID,
            memberID: memberID,
            memberName: "サナ",
            title: "サナ トレカ",
            tags: [
                GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000524")!, name: "2026 LIVE")
            ]
        )
        let second = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000523")!,
            ownerID: ownerID,
            memberID: memberID,
            memberName: "サナ",
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
            HomeConditionTagSet(goods: .wish, exchange: .warning, payment: .warning)
        )

        switch candidate.sheet(selectedGoods: secondGoods) {
        case .wishHit(let payload):
            XCTAssertEqual(payload.goods.id, second.id)
            XCTAssertEqual(payload.conditionTags, HomeConditionTagSet(goods: .wish, exchange: .warning, payment: .warning))
        default:
            XCTFail("Selected wish-level goods should open the wish hit sheet.")
        }
    }

    func testMemberMatchEligibilityRequiresExactWishL2() throws {
        let memberID = UUID(uuidString: "00000000-0000-0000-0000-0000000005f1")!
        let item = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000005f2")!,
            ownerID: UUID(uuidString: "00000000-0000-0000-0000-0000000005f3")!,
            memberID: memberID,
            memberName: "サナ",
            title: "サナ トレカ"
        )
        let groupOnlySignals = HomeCandidateConditionSignals(
            goods: .init(hasIndividualListingHit: false, hasWishHit: true),
            exchange: .init(
                postalAcceptedByBoth: false,
                localExchangeSelected: true,
                prefectureMatches: false,
                dateMatches: false
            ),
            matchesViewerWish: true,
            matchesViewerWishCharacter: false,
            tagMatchCount: 1
        )
        let exactL2Signals = HomeCandidateConditionSignals(
            goods: .init(hasIndividualListingHit: false, hasWishHit: true),
            exchange: .init(
                postalAcceptedByBoth: false,
                localExchangeSelected: true,
                prefectureMatches: false,
                dateMatches: false
            ),
            matchesViewerWish: true,
            matchesViewerWishCharacter: true,
            tagMatchCount: 1
        )

        XCTAssertFalse(HomeDiscoveryMatchPolicy.isMemberMatchEligible(item: item, signals: groupOnlySignals))
        XCTAssertFalse(HomeDiscoveryMatchPolicy.isMemberTagMatchEligible(item: item, signals: groupOnlySignals))
        XCTAssertTrue(HomeDiscoveryMatchPolicy.isMemberMatchEligible(item: item, signals: exactL2Signals))
        XCTAssertTrue(HomeDiscoveryMatchPolicy.isMemberTagMatchEligible(item: item, signals: exactL2Signals))
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

    func testHavesCandidateLinkedCountUsesLookupDisplayCandidateCount() {
        let payload = HomeHavesLookupPayload(
            offeredGoods: HomeDiscoveryFixtures.selectedYellow,
            offeredSignals: HomeCandidateConditionSignalDefaults.possible(index: 0),
            tagMatchedCandidates: [HomeDiscoveryFixtures.userTagCandidates[0]],
            memberMatchedCandidates: [
                HomeDiscoveryFixtures.userCandidates[0],
                HomeDiscoveryFixtures.userCandidates[1]
            ]
        )
        let candidate = HomeDiscoveryCandidate(
            id: HomeDiscoveryFixtures.selectedYellow.id,
            title: "求められているグッズ",
            signals: HomeCandidateConditionSignalDefaults.matched(index: 0),
            sheet: .havesLookup(payload),
            goods: [HomeDiscoveryFixtures.selectedYellow]
        )

        XCTAssertEqual(payload.displayCandidateCount, 3)
        XCTAssertEqual(candidate.linkedCount, 3)
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
        case .goodsHit(let payload):
            XCTAssertEqual(payload.goods.id, listingPayload.goods.id)
            XCTAssertEqual(payload.signals, listingPayload.signals)
        default:
            XCTFail("Listing hits from the extra row should use the normal goods-hit selection sheet.")
        }
    }

    func testHomeDiscoveryProposalSelectionMergesExtraGoodsSelections() {
        let firstReceiverID = UUID(uuidString: "00000000-0000-0000-0000-000000000541")!
        let secondReceiverID = UUID(uuidString: "00000000-0000-0000-0000-000000000542")!
        let firstSenderID = UUID(uuidString: "00000000-0000-0000-0000-000000000543")!
        let secondSenderID = UUID(uuidString: "00000000-0000-0000-0000-000000000544")!

        let base = HomeDiscoveryProposalSelection(
            receiverGoodsID: firstReceiverID,
            senderGoodsIDs: [firstSenderID],
            matchType: .perfect
        )
        let extra = HomeDiscoveryProposalSelection(
            receiverGoodsID: secondReceiverID,
            senderGoodsIDs: [secondSenderID],
            matchType: .forward
        )

        let merged = base.includingExtraSelections([extra])

        XCTAssertEqual(merged.receiverGoodsIDs, [firstReceiverID, secondReceiverID])
        XCTAssertEqual(merged.senderGoodsIDs, [firstSenderID, secondSenderID])
        XCTAssertEqual(merged.receiverGoodsID, firstReceiverID)
        XCTAssertEqual(merged.matchType, .perfect)
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

    func testHomeProposalRouteKeepsAdditionalReceiverGoodsIDsFromDiscoverySelection() throws {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000571")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000572")!
        let firstReceiverGoodsID = UUID(uuidString: "00000000-0000-0000-0000-000000000573")!
        let secondReceiverGoodsID = UUID(uuidString: "00000000-0000-0000-0000-000000000574")!

        let receiverGoods = HomeMockGoods(
            id: firstReceiverGoodsID,
            ownerID: partnerID,
            title: "サナ トレカ",
            subtitle: "",
            displayTags: [],
            rawTagNames: [],
            ownerPaymentMethods: [],
            ownerPaymentNote: nil,
            shape: .portrait,
            palette: [],
            symbol: "サ",
            imageURL: nil
        )
        let selection = HomeDiscoveryProposalSelection(
            receiverGoodsID: firstReceiverGoodsID,
            receiverGoodsIDs: [firstReceiverGoodsID, secondReceiverGoodsID],
            senderGoodsIDs: [],
            matchType: .perfect,
            receiverGoods: receiverGoods
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

        XCTAssertEqual(route.item.id, firstReceiverGoodsID)
        XCTAssertEqual(route.receiverGoodsIDs, [firstReceiverGoodsID, secondReceiverGoodsID])
    }

    func testHomeProposalRouteUsesFixtureOwnerForFallbackHomeCard() throws {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000563")!
        let selection = HomeDiscoveryProposalSelection(
            receiverGoodsID: HomeDiscoveryFixtures.selectedYellow.id,
            senderGoodsIDs: [],
            matchType: .perfect,
            receiverGoods: HomeDiscoveryFixtures.selectedYellow,
            exchangeMethod: .hand,
            cashAmount: 1_500
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

        XCTAssertEqual(route.item.id, HomeDiscoveryFixtures.selectedYellow.id)
        XCTAssertEqual(route.item.ownerID, HomeDiscoveryFixtures.ownerID)
        XCTAssertEqual(route.initialCashAmount, 1_500)
        XCTAssertEqual(route.initialExchangeMethod, .hand)
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

    func testHomeWishCopyInputCopiesTappedGoodsAsIndependentWish() throws {
        let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000000558")!
        let memberID = UUID(uuidString: "00000000-0000-0000-0000-000000000559")!
        let goodsTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000560")!
        let imageURL = try XCTUnwrap(URL(string: "https://example.com/source-card.jpg"))
        let goods = HomeMockGoods(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000561")!,
            ownerID: UUID(uuidString: "00000000-0000-0000-0000-000000000562")!,
            groupID: groupID,
            memberID: memberID,
            goodsTypeID: goodsTypeID,
            title: "サナ 2026 LIVE トレカ",
            subtitle: "#2026 LIVE",
            displayTags: ["#2026 LIVE"],
            rawTagNames: ["2026 live", " #会場限定 "],
            ownerPaymentMethods: [.paypay],
            ownerPaymentNote: nil,
            shape: .portrait,
            palette: [],
            symbol: "サ",
            imageURL: imageURL
        )

        let input = try XCTUnwrap(HomeWishCopyInputBuilder.input(from: goods, goodsTypes: []))

        XCTAssertEqual(input.kind, .wish)
        XCTAssertEqual(input.title, "サナ 2026 LIVE トレカ")
        XCTAssertEqual(input.groupID, groupID)
        XCTAssertEqual(input.memberID, memberID)
        XCTAssertEqual(input.goodsTypeID, goodsTypeID)
        XCTAssertEqual(input.quantity, 1)
        XCTAssertEqual(input.tagNames, ["2026 live", "会場限定"])
        XCTAssertEqual(input.photoURLs, ["https://example.com/source-card.jpg"])
    }

    func testHomeWishCopyInputCanInferGoodsTypeFromVisibleCopy() throws {
        let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000000563")!
        let goodsTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000564")!
        let goods = HomeMockGoods(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000565")!,
            ownerID: UUID(uuidString: "00000000-0000-0000-0000-000000000566")!,
            groupID: groupID,
            memberID: nil,
            goodsTypeID: nil,
            title: "モモ トレカ",
            subtitle: "トレカ",
            displayTags: [],
            rawTagNames: [],
            ownerPaymentMethods: [],
            ownerPaymentNote: nil,
            shape: .portrait,
            palette: [],
            symbol: "モ",
            imageURL: nil
        )

        let input = try XCTUnwrap(
            HomeWishCopyInputBuilder.input(
                from: goods,
                goodsTypes: [GoodsType(id: goodsTypeID, name: "トレカ")]
            )
        )

        XCTAssertEqual(input.goodsTypeID, goodsTypeID)
    }

    func testHomeWishCopyInputFallsBackToLoadedMastersForLegacyHomeCards() throws {
        let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000000565")!
        let goodsTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000566")!
        let goods = HomeMockGoods(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000567")!,
            ownerID: UUID(uuidString: "00000000-0000-0000-0000-000000000568")!,
            groupID: nil,
            memberID: nil,
            goodsTypeID: nil,
            title: "サナ 2026 LIVE",
            subtitle: "2026 LIVE",
            displayTags: [],
            rawTagNames: [],
            ownerPaymentMethods: [],
            ownerPaymentNote: nil,
            shape: .portrait,
            palette: [],
            symbol: "サ",
            imageURL: nil
        )

        let input = try XCTUnwrap(
            HomeWishCopyInputBuilder.input(
                from: goods,
                groups: [OshiGroup(id: groupID, name: "TWICE")],
                goodsTypes: [GoodsType(id: goodsTypeID, name: "トレカ")]
            )
        )

        XCTAssertEqual(input.groupID, groupID)
        XCTAssertEqual(input.goodsTypeID, goodsTypeID)
    }

    func testHomeWishCopyInputReplacesUnknownFallbackIDsWithLoadedMasters() throws {
        let staleGroupID = UUID(uuidString: "00000000-0000-0000-0000-000000000569")!
        let staleGoodsTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000570")!
        let liveGroupID = UUID(uuidString: "00000000-0000-0000-0000-000000000571")!
        let liveGoodsTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000572")!
        let goods = HomeMockGoods(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000573")!,
            ownerID: UUID(uuidString: "00000000-0000-0000-0000-000000000574")!,
            groupID: staleGroupID,
            memberID: nil,
            goodsTypeID: staleGoodsTypeID,
            title: "サナ 2026 LIVE",
            subtitle: "トレカ",
            displayTags: [],
            rawTagNames: [],
            ownerPaymentMethods: [],
            ownerPaymentNote: nil,
            shape: .portrait,
            palette: [],
            symbol: "サ",
            imageURL: nil
        )

        let input = try XCTUnwrap(
            HomeWishCopyInputBuilder.input(
                from: goods,
                groups: [OshiGroup(id: liveGroupID, name: "TWICE")],
                goodsTypes: [GoodsType(id: liveGoodsTypeID, name: "トレカ")]
            )
        )

        XCTAssertEqual(input.groupID, liveGroupID)
        XCTAssertEqual(input.goodsTypeID, liveGoodsTypeID)
    }

    func testHomeWishCopyInputRequiresCopyableMasterIDs() {
        let goodsTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000567")!
        let missingGroup = HomeMockGoods(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000568")!,
            ownerID: nil,
            groupID: nil,
            memberID: nil,
            goodsTypeID: goodsTypeID,
            title: "グループなし",
            subtitle: "",
            displayTags: [],
            rawTagNames: [],
            ownerPaymentMethods: [],
            ownerPaymentNote: nil,
            shape: .portrait,
            palette: [],
            symbol: "G",
            imageURL: nil
        )

        XCTAssertNil(HomeWishCopyInputBuilder.input(from: missingGroup, goodsTypes: []))
        XCTAssertGreaterThan(HomeDiscoveryDeferredPresentationPolicy.sheetDismissalDelayNanoseconds, 0)
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
            memberID: UUID(uuidString: "00000000-0000-0000-0000-000000000506")!,
            goodsTypeID: cardGoodsTypeID,
            memberName: "ニンニン",
            goodsTypeName: "トレカ",
            title: "Codex ニンニン トレカ",
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
            memberName: "モモ",
            goodsTypeName: "トレカ",
            title: "Codex モモ トレカ",
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
            memberName: "モモ",
            goodsTypeName: "アクスタ",
            title: "SEVENTEEN モモ アクスタ",
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
            memberName: "モモ",
            goodsTypeName: "トレカ",
            title: "Codex モモ トレカ",
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

    func testHomeDiscoveryMemberCandidatesGroupOnlySameMemberGoods() throws {
        let ownerID = UUID(uuidString: "00000000-0000-0000-0000-000000000581")!
        let sanaID = UUID(uuidString: "00000000-0000-0000-0000-000000000582")!
        let momoID = UUID(uuidString: "00000000-0000-0000-0000-000000000583")!
        let sanaTradingCard = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000584")!,
            ownerID: ownerID,
            memberID: sanaID,
            memberName: "サナ",
            title: "Codex サナ トレカ"
        )
        let sanaBadge = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000585")!,
            ownerID: ownerID,
            memberID: sanaID,
            memberName: "サナ",
            title: "SEVENTEEN サナ 缶バッジ"
        )
        let momoTradingCard = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000586")!,
            ownerID: ownerID,
            memberID: momoID,
            memberName: "モモ",
            title: "Codex モモ トレカ"
        )

        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: [sanaTradingCard, sanaBadge, momoTradingCard],
            source: .user,
            conditionSignalsByItemID: [:]
        )

        let sanaCandidate = try XCTUnwrap(candidates.first { $0.title == "サナ" })
        XCTAssertEqual(candidates.map(\.title), ["サナ", "モモ"])
        XCTAssertEqual(sanaCandidate.goods.map(\.id), [sanaTradingCard.id, sanaBadge.id])
        XCTAssertFalse(sanaCandidate.goods.contains { $0.title.hasPrefix("モモ") })
    }

    func testHomeDiscoveryMemberCandidatesUseMasterNameWhenTitleLooksLikeAnotherToken() throws {
        let ownerID = UUID(uuidString: "00000000-0000-0000-0000-000000000587")!
        let wooziID = UUID(uuidString: "00000000-0000-0000-0000-000000000588")!
        let firstWooziGoods = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000589")!,
            ownerID: ownerID,
            memberID: wooziID,
            memberName: "ウジ",
            title: "SEVENTEEN ウジ 2026 SG トレカ"
        )
        let secondWooziGoods = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000058a")!,
            ownerID: ownerID,
            memberID: wooziID,
            memberName: "ウジ",
            title: "Codex smoke fixture"
        )

        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: [firstWooziGoods, secondWooziGoods],
            source: .user,
            conditionSignalsByItemID: [:]
        )

        let wooziCandidate = try XCTUnwrap(candidates.first { $0.title == "ウジ" })
        XCTAssertEqual(candidates.map(\.title), ["ウジ"])
        XCTAssertEqual(wooziCandidate.goods.map(\.id), [firstWooziGoods.id, secondWooziGoods.id])
        XCTAssertFalse(candidates.map(\.title).contains("Codex"))
        XCTAssertFalse(candidates.map(\.title).contains("SEVENTEEN"))
    }

    func testHomeMockGoodsCarriesActualOwnerSummary() throws {
        let ownerID = UUID(uuidString: "00000000-0000-0000-0000-00000000058b")!
        let item = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000058c")!,
            ownerID: ownerID,
            title: "サナ トレカ",
            ownerPrefecture: "大阪府",
            ownerDisplayName: "長いユーザーネームの交換者",
            ownerHandle: "real_owner",
            ownerGender: .female,
            ownerAge: 27,
            ownerAverageStars: 4.6,
            ownerEvaluationCount: 9,
            ownerCompletedTradeCount: 14
        )

        let goods = HomeMockGoods.from(item: item, index: 0, goodsTypes: [])
        let owner = try XCTUnwrap(goods.ownerSummary)

        XCTAssertEqual(owner.id, ownerID)
        XCTAssertEqual(owner.displayName, "長いユーザーネームの交換者")
        XCTAssertEqual(owner.genderAgeText, "女性 / 27歳")
        XCTAssertEqual(owner.evaluationText, "評価9件 ★4.6")
        XCTAssertEqual(owner.tradeText, "交換14件")
        XCTAssertEqual(owner.prefecture, "大阪府")
    }

    func testHomeDiscoverySearchCriteriaUsesSelectedMemberAndTag() throws {
        let groupID = UUID(uuidString: "00000000-0000-0000-0000-00000000058d")!
        let memberID = UUID(uuidString: "00000000-0000-0000-0000-00000000058e")!
        let item = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000058f")!,
            ownerID: UUID(uuidString: "00000000-0000-0000-0000-000000000590")!,
            groupID: groupID,
            memberID: memberID,
            groupName: "TWICE",
            memberName: "サナ",
            title: "SEVENTEENっぽい自由文字列",
            tags: [GoodsTag(id: UUID(), name: "2026 LIVE")]
        )
        let candidate = try XCTUnwrap(
            HomeDiscoveryCandidateFactory.candidates(
                from: [item],
                source: .userTag,
                conditionSignalsByItemID: [:]
            ).first
        )

        let criteria = HomeDiscoverySearchRoutePolicy.criteria(
            for: candidate,
            selectedGoods: candidate.goods.first,
            source: .userTag
        )

        XCTAssertEqual(criteria.groupID, groupID)
        XCTAssertEqual(criteria.memberID, memberID)
        XCTAssertEqual(criteria.tagNames, ["2026 live"])
        XCTAssertEqual(criteria.query, "")
    }

    func testHomeDiscoveryFixtureMemberCandidatesContainOnlyDisplayedMemberGoods() {
        for candidate in HomeDiscoveryFixtures.userCandidates {
            XCTAssertTrue(
                candidate.goods.allSatisfy { $0.masterDisplayName == candidate.title },
                "\(candidate.title) contains another member goods: \(candidate.goods.map(\.title))"
            )
        }
    }

    func testHomeDiscoveryFixtureMemberTagCandidatesContainOnlyDisplayedMemberGoods() {
        for candidate in HomeDiscoveryFixtures.userTagCandidates {
            let memberName = HomeDiscoveryTitleParser.memberName(from: candidate.title)
            XCTAssertTrue(
                candidate.goods.allSatisfy { $0.masterDisplayName == memberName },
                "\(candidate.title) contains another member goods: \(candidate.goods.map(\.title))"
            )
        }
    }

    func testHomeDiscoveryMemberCandidatesClampToTenMembers() {
        let ownerID = UUID(uuidString: "00000000-0000-0000-0000-000000000590")!
        let items = (0..<11).map { index in
            GoodsItem(
                id: UUID(uuidString: String(format: "00000000-0000-0000-0000-0000000006%02d", index))!,
                ownerID: ownerID,
                memberID: UUID(uuidString: String(format: "00000000-0000-0000-0000-0000000007%02d", index))!,
                memberName: "メンバー\(index)",
                title: "Codex fixture \(index)"
            )
        }

        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: items,
            source: .user,
            conditionSignalsByItemID: [:]
        )

        XCTAssertEqual(candidates.count, HomeDiscoveryCandidateFactory.memberCandidateDisplayLimit)
        XCTAssertEqual(candidates.map(\.title), (0..<10).map { "メンバー\($0)" })
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

    func testPreviewRepositoryLoadsHomeDiscoveryFixtureOwnerProfile() async throws {
        let profile = try await PreviewMegrumRepository()
            .loadPublicUserProfile(userID: HomeDiscoveryFixtures.ownerID)

        XCTAssertEqual(profile?.profile.displayName, "mii_交換用")
        XCTAssertEqual(profile?.averageStars, 4.8)
        XCTAssertEqual(profile?.completedTradeCount, 32)
    }
}
