@testable import MegrumApp
import MegrumCore
import MegrumData
import XCTest

final class HomeCandidateComposerTests: XCTestCase {
    func testEmptySectionsResolveWithFallbackInventory() {
        let ownerID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let first = GoodsItem(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000031")!,
            ownerID: ownerID,
            title: "フォールバックA"
        )
        let second = GoodsItem(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000032")!,
            ownerID: ownerID,
            title: "フォールバックB"
        )

        let resolved = HomeCandidateSections().resolvedWithFallbackInventory([first, second])

        XCTAssertEqual(resolved.matchedItems, [first, second])
        XCTAssertEqual(resolved.possibleItems, [second, first])
        XCTAssertEqual(
            resolved.conditionSignalsByItemID[first.id],
            HomeCandidateConditionSignalDefaults.matched(index: 0)
        )
        XCTAssertEqual(
            resolved.conditionSignalsByItemID[second.id],
            HomeCandidateConditionSignalDefaults.matched(index: 1)
        )
    }

    func testNonEmptySectionsKeepExistingConditionSignals() {
        let ownerID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let candidate = GoodsItem(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000033")!,
            ownerID: ownerID,
            title: "既存候補"
        )
        let fallback = GoodsItem(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000034")!,
            ownerID: ownerID,
            title: "未使用フォールバック"
        )
        let sections = HomeCandidateSections(
            matchedItems: [candidate],
            possibleItems: [],
            conditionSignalsByItemID: [
                candidate.id: HomeCandidateConditionSignalDefaults.possible(index: 0)
            ]
        )

        let resolved = sections.resolvedWithFallbackInventory([fallback])

        XCTAssertEqual(resolved, sections)
    }

    func testWishRowRequiresL2MatchOnlyWhenWishSpecifiesCharacter() throws {
        let groupID = "20000000-0000-0000-0000-0000000000a1"
        let goodsTypeID = "30000000-0000-0000-0000-0000000000a1"
        let sanaID = "70000000-0000-0000-0000-0000000000a1"
        let momoID = "70000000-0000-0000-0000-0000000000a2"
        let l2Wish = try goodsRow(
            id: "10000000-0000-0000-0000-0000000000a1",
            userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
            groupID: groupID,
            characterID: sanaID,
            goodsTypeID: goodsTypeID,
            title: "相手Wish サナ"
        )
        let sameL2Item = try goodsRow(
            id: "10000000-0000-0000-0000-0000000000a2",
            userID: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
            groupID: groupID,
            characterID: sanaID,
            goodsTypeID: goodsTypeID,
            title: "自分のサナ"
        )
        let differentL2Item = try goodsRow(
            id: "10000000-0000-0000-0000-0000000000a3",
            userID: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
            groupID: groupID,
            characterID: momoID,
            goodsTypeID: goodsTypeID,
            title: "自分のモモ"
        )
        let l1OnlyWish = try goodsRow(
            id: "10000000-0000-0000-0000-0000000000a4",
            userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "相手Wish TWICE"
        )

        XCTAssertTrue(HomeCandidateComposer.wishRow(l2Wish, matches: sameL2Item))
        XCTAssertFalse(HomeCandidateComposer.wishRow(l2Wish, matches: differentL2Item))
        XCTAssertTrue(HomeCandidateComposer.wishRow(l1OnlyWish, matches: differentL2Item))
    }

    func testComposerMarksPaymentUnknownWhenViewerOrPartnerPaymentIsUnset() throws {
        func paymentStatus(
            viewerPaymentMethods: [String],
            partnerPaymentMethods: [String]
        ) throws -> HomePaymentConditionStatus? {
            let viewerID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
            let partnerID = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
            let viewerOfferID = "10000000-0000-0000-0000-0000000000b1"
            let viewerWishID = "10000000-0000-0000-0000-0000000000b2"
            let partnerOfferID = "10000000-0000-0000-0000-0000000000b3"
            let partnerWishID = "10000000-0000-0000-0000-0000000000b4"
            let groupID = "20000000-0000-0000-0000-0000000000b1"
            let goodsTypeID = "30000000-0000-0000-0000-0000000000b1"

            let composition = SupabaseHomeComposition(
                localMode: nil,
                viewerUser: try userRow(
                    id: viewerID,
                    handle: "viewer_trade",
                    primaryArea: "東京都",
                    paymentMethods: viewerPaymentMethods
                ),
                viewerInventory: [
                    try goodsRow(
                        id: viewerOfferID,
                        userID: viewerID,
                        groupID: groupID,
                        goodsTypeID: goodsTypeID,
                        title: "自分が譲るトレカ"
                    )
                ],
                viewerWishes: [
                    try goodsRow(
                        id: viewerWishID,
                        userID: viewerID,
                        groupID: groupID,
                        goodsTypeID: goodsTypeID,
                        title: "自分のWish"
                    )
                ],
                viewerListings: [],
                partnerInventory: [
                    try goodsRow(
                        id: partnerOfferID,
                        userID: partnerID,
                        groupID: groupID,
                        goodsTypeID: goodsTypeID,
                        title: "相手が譲るトレカ"
                    )
                ],
                partnerWishes: [
                    try goodsRow(
                        id: partnerWishID,
                        userID: partnerID,
                        groupID: groupID,
                        goodsTypeID: goodsTypeID,
                        title: "相手のWish"
                    )
                ],
                partnerUsers: [
                    try userRow(
                        id: partnerID,
                        handle: "partner_trade",
                        primaryArea: "東京都",
                        paymentMethods: partnerPaymentMethods
                    )
                ],
                partnerListings: [],
                listingWishOptions: [],
                viewerActivityWindows: [],
                partnerActivityWindows: [],
                inventoryTags: [],
                unreadNotificationIDs: []
            )

            let sections = HomeCandidateComposer.sections(from: composition)
            return sections.conditionSignalsByItemID[
                UUID(uuidString: partnerOfferID)!
            ]?.payment.status
        }

        XCTAssertEqual(
            try paymentStatus(viewerPaymentMethods: [], partnerPaymentMethods: ["paypay"]),
            .viewerUnset
        )
        XCTAssertEqual(
            try paymentStatus(viewerPaymentMethods: ["paypay"], partnerPaymentMethods: []),
            .partnerUnset
        )
    }

    func testComposerPromotesTwoSidedMatches() throws {
        let composition = SupabaseHomeComposition(
            localMode: nil,
            viewerInventory: [
                try goodsRow(
                    id: "10000000-0000-0000-0000-000000000001",
                    userID: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                    groupID: "20000000-0000-0000-0000-000000000001",
                    goodsTypeID: "30000000-0000-0000-0000-000000000001",
                    title: "自分のトレカ"
                )
            ],
            viewerWishes: [
                try goodsRow(
                    id: "10000000-0000-0000-0000-000000000002",
                    userID: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                    groupID: "20000000-0000-0000-0000-000000000002",
                    goodsTypeID: "30000000-0000-0000-0000-000000000002",
                    title: "探しているトレカ"
                )
            ],
            viewerListings: [],
            partnerInventory: [
                try goodsRow(
                    id: "10000000-0000-0000-0000-000000000003",
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: "20000000-0000-0000-0000-000000000002",
                    goodsTypeID: "30000000-0000-0000-0000-000000000002",
                    title: "相手の譲る候補",
                    photoURLs: ["https://example.com/item.jpg"],
                    quantity: 2
                )
            ],
            partnerWishes: [
                try goodsRow(
                    id: "10000000-0000-0000-0000-000000000004",
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: "20000000-0000-0000-0000-000000000001",
                    goodsTypeID: "30000000-0000-0000-0000-000000000001",
                    title: "相手のWish"
                )
            ],
            partnerUsers: [],
            partnerListings: [],
            listingWishOptions: [],
            viewerActivityWindows: [],
            partnerActivityWindows: [],
            inventoryTags: [
                try inventoryTagRow(
                    inventoryID: "10000000-0000-0000-0000-000000000003",
                    tagID: "40000000-0000-0000-0000-000000000001",
                    label: "会場限定"
                ),
                try inventoryTagRow(
                    inventoryID: "10000000-0000-0000-0000-000000000002",
                    tagID: "40000000-0000-0000-0000-000000000002",
                    label: "会場限定"
                )
            ],
            unreadNotificationIDs: []
        )

        let sections = HomeCandidateComposer.sections(from: composition)

        XCTAssertEqual(sections.matchedItems.map(\.id), [UUID(uuidString: "10000000-0000-0000-0000-000000000003")!])
        XCTAssertEqual(sections.matchedItems.first?.quantity, 2)
        XCTAssertEqual(sections.matchedItems.first?.imageURL?.absoluteString, "https://example.com/item.jpg")
        XCTAssertEqual(sections.matchedItems.first?.tags.map(\.name), ["会場限定"])
        XCTAssertEqual(
            sections.conditionSignalsByItemID[UUID(uuidString: "10000000-0000-0000-0000-000000000003")!]?.goods,
            HomeGoodsConditionSignals(hasIndividualListingHit: false, hasWishHit: true)
        )
        XCTAssertEqual(
            sections.conditionSignalsByItemID[UUID(uuidString: "10000000-0000-0000-0000-000000000003")!]?.linkCounts,
            HomeCandidateLinkCounts(wishCount: 1, listingCount: 0)
        )
        XCTAssertEqual(
            sections.conditionSignalsByItemID[UUID(uuidString: "10000000-0000-0000-0000-000000000003")!]?.wishMatchedOfferGoodsIDs,
            [UUID(uuidString: "10000000-0000-0000-0000-000000000001")!]
        )
        XCTAssertEqual(
            sections.conditionSignalsByItemID[UUID(uuidString: "10000000-0000-0000-0000-000000000003")!]?.wishMatchedPartnerUserIDs,
            [UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!]
        )
        XCTAssertEqual(
            sections.conditionSignalsByItemID[UUID(uuidString: "10000000-0000-0000-0000-000000000003")!]?.matchesViewerWish,
            true
        )
        XCTAssertEqual(
            sections.conditionSignalsByItemID[UUID(uuidString: "10000000-0000-0000-0000-000000000003")!]?.tagMatchCount,
            1
        )
        XCTAssertEqual(
            sections.conditionSignalsByItemID[UUID(uuidString: "10000000-0000-0000-0000-000000000001")!]?.linkCounts,
            HomeCandidateLinkCounts(wishCount: 1, listingCount: 0)
        )
        XCTAssertEqual(
            sections.conditionSignalsByItemID[UUID(uuidString: "10000000-0000-0000-0000-000000000001")!]?.wishMatchedOfferGoodsIDs,
            [UUID(uuidString: "10000000-0000-0000-0000-000000000001")!]
        )
        XCTAssertEqual(
            sections.conditionSignalsByItemID[UUID(uuidString: "10000000-0000-0000-0000-000000000001")!]?.wishMatchedPartnerUserIDs,
            [UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!]
        )
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.goodsCondition(
                for: try XCTUnwrap(sections.conditionSignalsByItemID[
                    UUID(uuidString: "10000000-0000-0000-0000-000000000003")!
                ]?.goods)
            ),
            .wish
        )
        XCTAssertTrue(sections.possibleItems.isEmpty)
    }

    func testComposerUsesMasterNamesForMemberCandidateTitlesInsteadOfGoodsTitle() throws {
        let composition = SupabaseHomeComposition(
            localMode: nil,
            viewerInventory: [],
            viewerWishes: [
                try goodsRow(
                    id: "10000000-0000-0000-0000-0000000000a1",
                    userID: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                    groupID: "20000000-0000-0000-0000-0000000000a1",
                    characterID: "21000000-0000-0000-0000-0000000000a1",
                    goodsTypeID: "30000000-0000-0000-0000-0000000000a1",
                    title: "ウジ トレカ",
                    groupName: "SEVENTEEN",
                    characterName: "ウジ",
                    goodsTypeName: "トレカ"
                )
            ],
            viewerListings: [],
            partnerInventory: [
                try goodsRow(
                    id: "10000000-0000-0000-0000-0000000000a2",
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: "20000000-0000-0000-0000-0000000000a1",
                    characterID: "21000000-0000-0000-0000-0000000000a1",
                    goodsTypeID: "30000000-0000-0000-0000-0000000000a1",
                    title: "SEVENTEEN ウジ 2026 SG トレカ",
                    groupName: "SEVENTEEN",
                    characterName: "ウジ",
                    goodsTypeName: "トレカ"
                ),
                try goodsRow(
                    id: "10000000-0000-0000-0000-0000000000a3",
                    userID: "cccccccc-cccc-cccc-cccc-cccccccccccc",
                    groupID: "20000000-0000-0000-0000-0000000000a1",
                    characterID: "21000000-0000-0000-0000-0000000000a1",
                    goodsTypeID: "30000000-0000-0000-0000-0000000000a1",
                    title: "Codex unrelated title token",
                    groupName: "SEVENTEEN",
                    characterName: "ウジ",
                    goodsTypeName: "トレカ"
                )
            ],
            partnerWishes: [],
            partnerUsers: [
                try userRow(id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", handle: "real_partner_a", primaryArea: "東京都"),
                try userRow(id: "cccccccc-cccc-cccc-cccc-cccccccccccc", handle: "real_partner_b", primaryArea: "東京都")
            ],
            partnerListings: [],
            listingWishOptions: [],
            viewerActivityWindows: [],
            partnerActivityWindows: [],
            inventoryTags: [],
            unreadNotificationIDs: []
        )

        let sections = HomeCandidateComposer.sections(from: composition)
        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: sections.possibleItems,
            source: .user,
            goodsTypes: [],
            conditionSignalsByItemID: sections.conditionSignalsByItemID
        )

        XCTAssertEqual(candidates.map(\.title), ["ウジ"])
        XCTAssertEqual(candidates.first?.goods.map(\.title), ["ウジ トレカ", "ウジ トレカ"])
        XCTAssertFalse(candidates.map(\.title).contains("Codex"))
        XCTAssertFalse(candidates.map(\.title).contains("SEVENTEEN"))
    }

    func testComposerExcludesCodexMutualMatchTestAccountsFromNormalHomeCandidates() throws {
        let composition = SupabaseHomeComposition(
            localMode: nil,
            viewerUser: try userRow(id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", handle: "michilion", primaryArea: "大阪府"),
            viewerInventory: [],
            viewerWishes: [
                try goodsRow(
                    id: "10000000-0000-0000-0000-0000000000b1",
                    userID: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                    groupID: "20000000-0000-0000-0000-0000000000b1",
                    characterID: "21000000-0000-0000-0000-0000000000b1",
                    goodsTypeID: "30000000-0000-0000-0000-0000000000b1",
                    title: "RM トレカ",
                    groupName: "BTS",
                    characterName: "RM",
                    goodsTypeName: "トレカ"
                )
            ],
            viewerListings: [],
            partnerInventory: [
                try goodsRow(
                    id: "10000000-0000-0000-0000-0000000000b2",
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: "20000000-0000-0000-0000-0000000000b1",
                    characterID: "21000000-0000-0000-0000-0000000000b1",
                    goodsTypeID: "30000000-0000-0000-0000-0000000000b1",
                    title: "Codex 金額不足 自分譲 RM トレカ",
                    groupName: "BTS",
                    characterName: "RM",
                    goodsTypeName: "トレカ"
                ),
                try goodsRow(
                    id: "10000000-0000-0000-0000-0000000000b3",
                    userID: "cccccccc-cccc-cccc-cccc-cccccccccccc",
                    groupID: "20000000-0000-0000-0000-0000000000b1",
                    characterID: "21000000-0000-0000-0000-0000000000b1",
                    goodsTypeID: "30000000-0000-0000-0000-0000000000b1",
                    title: "RM トレカ",
                    groupName: "BTS",
                    characterName: "RM",
                    goodsTypeName: "トレカ"
                )
            ],
            partnerWishes: [],
            partnerUsers: [
                try userRow(
                    id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    handle: "codex_mm_cash",
                    primaryArea: "東京都",
                    isTestAccount: true
                ),
                try userRow(id: "cccccccc-cccc-cccc-cccc-cccccccccccc", handle: "real_partner", primaryArea: "東京都")
            ],
            partnerListings: [],
            listingWishOptions: [],
            viewerActivityWindows: [],
            partnerActivityWindows: [],
            inventoryTags: [],
            unreadNotificationIDs: []
        )

        let sections = HomeCandidateComposer.sections(from: composition)

        XCTAssertEqual(
            sections.possibleItems.map(\.id),
            [UUID(uuidString: "10000000-0000-0000-0000-0000000000b3")!]
        )
        XCTAssertFalse(sections.possibleItems.map(\.title).contains { $0.contains("Codex") })
    }

    func testComposerBuildsMutualMatchFromReciprocalListings() throws {
        let viewerID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        let partnerID = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
        let viewerOfferID = "10000000-0000-0000-0000-000000000061"
        let partnerOfferID = "10000000-0000-0000-0000-000000000062"
        let viewerListingID = "50000000-0000-0000-0000-000000000061"
        let partnerListingID = "50000000-0000-0000-0000-000000000062"
        let sharedExchangeSummary = IndividualListingExchangeSummary(
            handoffMethod: .local,
            localPrefecture: "東京都",
            localPlaceMemo: "東京ドーム",
            localSchedule: "6/28",
            shippingFee: .owner
        )

        let composition = SupabaseHomeComposition(
            localMode: nil,
            viewerUser: try userRow(
                id: viewerID,
                handle: "viewer_trade",
                primaryArea: "東京都"
            ),
            viewerInventory: [
                try goodsRow(
                    id: viewerOfferID,
                    userID: viewerID,
                    groupID: "20000000-0000-0000-0000-000000000061",
                    goodsTypeID: "30000000-0000-0000-0000-000000000061",
                    title: "自分が譲るトレカ"
                )
            ],
            viewerWishes: [],
            viewerListings: [
                try listingRow(
                    id: viewerListingID,
                    userID: viewerID,
                    haveIDs: [viewerOfferID],
                    haveGroupID: "20000000-0000-0000-0000-000000000061",
                    haveGoodsTypeID: "30000000-0000-0000-0000-000000000061",
                    note: sharedExchangeSummary.storageLine
                )
            ],
            partnerInventory: [
                try goodsRow(
                    id: partnerOfferID,
                    userID: partnerID,
                    groupID: "20000000-0000-0000-0000-000000000062",
                    goodsTypeID: "30000000-0000-0000-0000-000000000061",
                    title: "相手が譲るトレカ",
                    photoURLs: ["https://example.com/partner.jpg"]
                )
            ],
            partnerWishes: [],
            partnerUsers: [
                try userRow(
                    id: partnerID,
                    handle: "partner_trade",
                    primaryArea: "東京都",
                    age: 24,
                    averageStars: 4.75,
                    evaluationCount: 12
                )
            ],
            partnerListings: [
                try listingRow(
                    id: partnerListingID,
                    userID: partnerID,
                    haveIDs: [partnerOfferID],
                    haveGroupID: "20000000-0000-0000-0000-000000000062",
                    haveGoodsTypeID: "30000000-0000-0000-0000-000000000061",
                    note: sharedExchangeSummary.storageLine
                )
            ],
            listingWishOptions: [
                try listingWishOptionRow(
                    id: "60000000-0000-0000-0000-000000000061",
                    listingID: viewerListingID,
                    wishIDs: [partnerOfferID],
                    wishGroupID: "20000000-0000-0000-0000-000000000062",
                    wishGoodsTypeID: "30000000-0000-0000-0000-000000000061"
                ),
                try listingWishOptionRow(
                    id: "60000000-0000-0000-0000-000000000062",
                    listingID: partnerListingID,
                    wishIDs: [viewerOfferID],
                    wishGroupID: "20000000-0000-0000-0000-000000000061",
                    wishGoodsTypeID: "30000000-0000-0000-0000-000000000061"
                )
            ],
            viewerActivityWindows: [],
            partnerActivityWindows: [],
            inventoryTags: [
                try inventoryTagRow(
                    inventoryID: viewerOfferID,
                    tagID: "40000000-0000-0000-0000-000000000061",
                    label: "ライブ2026"
                ),
                try inventoryTagRow(
                    inventoryID: partnerOfferID,
                    tagID: "40000000-0000-0000-0000-000000000062",
                    label: "ライブ2026"
                )
            ],
            unreadNotificationIDs: []
        )

        let sections = HomeCandidateComposer.sections(from: composition)
        let candidate = try XCTUnwrap(sections.mutualMatchCandidates.first)

        XCTAssertEqual(sections.mutualMatchCandidates.count, 1)
        XCTAssertEqual(candidate.partnerID, UUID(uuidString: partnerID))
        XCTAssertEqual(candidate.partnerGoodsItems.map(\.id), [UUID(uuidString: partnerOfferID)!])
        XCTAssertEqual(candidate.viewerGoodsItems.map(\.id), [UUID(uuidString: viewerOfferID)!])
        XCTAssertEqual(candidate.partnerGoodsItems.first?.imageURL?.absoluteString, "https://example.com/partner.jpg")
        XCTAssertEqual(candidate.attentionKinds, [.ready])
        XCTAssertEqual(candidate.signals.goods, HomeGoodsConditionSignals(hasIndividualListingHit: true, hasWishHit: false))
        XCTAssertEqual(candidate.signals.individualListingSelection?.wantedLogic, .one)
        XCTAssertEqual(candidate.signals.individualListingSelection?.offeredLogic, .one)
        XCTAssertEqual(candidate.partnerAgeRangeText, "20代")
        XCTAssertEqual(candidate.partnerEvaluationSummaryText, "評価12件 ★4.8")
    }

    func testComposerAddsMutualConditionAttentionKindsFromListingNotesAndPaymentMethods() throws {
        let viewerID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        let partnerID = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
        let viewerOfferID = "10000000-0000-0000-0000-000000000091"
        let partnerOfferID = "10000000-0000-0000-0000-000000000092"
        let viewerListingID = "50000000-0000-0000-0000-000000000091"
        let partnerListingID = "50000000-0000-0000-0000-000000000092"
        let groupID = "20000000-0000-0000-0000-000000000091"
        let goodsTypeID = "30000000-0000-0000-0000-000000000091"
        let viewerSummary = IndividualListingExchangeSummary(
            handoffMethod: .local,
            localPrefecture: "東京都",
            localSchedule: "6/28 18:00",
            shippingFee: .owner
        )
        let partnerSummary = IndividualListingExchangeSummary(
            handoffMethod: .local,
            localPrefecture: "大阪府",
            localSchedule: "6/29 18:00",
            shippingFee: .owner
        )

        let composition = SupabaseHomeComposition(
            localMode: nil,
            viewerUser: try userRow(
                id: viewerID,
                handle: "viewer_trade",
                primaryArea: "東京都",
                paymentMethods: ["bank_transfer"]
            ),
            viewerInventory: [
                try goodsRow(
                    id: viewerOfferID,
                    userID: viewerID,
                    groupID: groupID,
                    goodsTypeID: goodsTypeID,
                    title: "自分が譲るトレカ"
                )
            ],
            viewerWishes: [],
            viewerListings: [
                try listingRow(
                    id: viewerListingID,
                    userID: viewerID,
                    haveIDs: [viewerOfferID],
                    haveGroupID: groupID,
                    haveGoodsTypeID: goodsTypeID,
                    note: viewerSummary.storageLine
                )
            ],
            partnerInventory: [
                try goodsRow(
                    id: partnerOfferID,
                    userID: partnerID,
                    groupID: groupID,
                    goodsTypeID: goodsTypeID,
                    title: "相手が譲るトレカ"
                )
            ],
            partnerWishes: [],
            partnerUsers: [
                try userRow(
                    id: partnerID,
                    handle: "partner_trade",
                    primaryArea: "大阪府",
                    paymentMethods: ["paypay"]
                )
            ],
            partnerListings: [
                try listingRow(
                    id: partnerListingID,
                    userID: partnerID,
                    haveIDs: [partnerOfferID],
                    haveGroupID: groupID,
                    haveGoodsTypeID: goodsTypeID,
                    note: partnerSummary.storageLine
                )
            ],
            listingWishOptions: [
                try listingWishOptionRow(
                    id: "60000000-0000-0000-0000-000000000091",
                    listingID: viewerListingID,
                    wishIDs: [],
                    wishGroupID: nil,
                    wishGoodsTypeID: nil,
                    isCashOffer: true,
                    cashAmount: 2_000
                ),
                try listingWishOptionRow(
                    id: "60000000-0000-0000-0000-000000000092",
                    listingID: partnerListingID,
                    wishIDs: [],
                    wishGroupID: nil,
                    wishGoodsTypeID: nil,
                    isCashOffer: true,
                    cashAmount: 2_000
                )
            ],
            viewerActivityWindows: [],
            partnerActivityWindows: [],
            inventoryTags: [],
            unreadNotificationIDs: []
        )

        let candidate = try XCTUnwrap(HomeCandidateComposer.sections(from: composition).mutualMatchCandidates.first)

        XCTAssertTrue(candidate.attentionKinds.contains(.prefectureNeedsDiscussion))
        XCTAssertTrue(candidate.attentionKinds.contains(.dateNeedsDiscussion))
        XCTAssertTrue(candidate.attentionKinds.contains(.paymentMethodMismatch))
        XCTAssertEqual(candidate.signals.payment.status, .methodMismatch)
        XCTAssertTrue(candidate.signals.payment.requiresPayment)
    }

    func testComposerDoesNotBuildMutualMatchWhenWantedMemberDiffers() throws {
        let viewerID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        let partnerID = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
        let viewerOfferID = "10000000-0000-0000-0000-000000000071"
        let viewerWantedID = "10000000-0000-0000-0000-000000000072"
        let partnerOfferID = "10000000-0000-0000-0000-000000000073"
        let partnerWantedID = "10000000-0000-0000-0000-000000000074"
        let viewerListingID = "50000000-0000-0000-0000-000000000071"
        let partnerListingID = "50000000-0000-0000-0000-000000000072"
        let groupID = "20000000-0000-0000-0000-000000000071"
        let goodsTypeID = "30000000-0000-0000-0000-000000000071"

        let composition = SupabaseHomeComposition(
            localMode: nil,
            viewerInventory: [
                try goodsRow(
                    id: viewerOfferID,
                    userID: viewerID,
                    groupID: groupID,
                    characterID: "70000000-0000-0000-0000-000000000071",
                    goodsTypeID: goodsTypeID,
                    title: "自分が譲るジン トレカ"
                )
            ],
            viewerWishes: [
                try goodsRow(
                    id: viewerWantedID,
                    userID: viewerID,
                    groupID: groupID,
                    characterID: "70000000-0000-0000-0000-000000000072",
                    goodsTypeID: goodsTypeID,
                    title: "自分が求めるサナ トレカ"
                )
            ],
            viewerListings: [
                try listingRow(
                    id: viewerListingID,
                    userID: viewerID,
                    haveIDs: [viewerOfferID],
                    haveGroupID: groupID,
                    haveGoodsTypeID: goodsTypeID
                )
            ],
            partnerInventory: [
                try goodsRow(
                    id: partnerOfferID,
                    userID: partnerID,
                    groupID: groupID,
                    characterID: "70000000-0000-0000-0000-000000000073",
                    goodsTypeID: goodsTypeID,
                    title: "相手が譲るモモ トレカ"
                )
            ],
            partnerWishes: [
                try goodsRow(
                    id: partnerWantedID,
                    userID: partnerID,
                    groupID: groupID,
                    characterID: "70000000-0000-0000-0000-000000000071",
                    goodsTypeID: goodsTypeID,
                    title: "相手が求めるジン トレカ"
                )
            ],
            partnerUsers: [],
            partnerListings: [
                try listingRow(
                    id: partnerListingID,
                    userID: partnerID,
                    haveIDs: [partnerOfferID],
                    haveGroupID: groupID,
                    haveGoodsTypeID: goodsTypeID
                )
            ],
            listingWishOptions: [
                try listingWishOptionRow(
                    id: "60000000-0000-0000-0000-000000000071",
                    listingID: viewerListingID,
                    wishIDs: [viewerWantedID],
                    wishGroupID: groupID,
                    wishGoodsTypeID: goodsTypeID
                ),
                try listingWishOptionRow(
                    id: "60000000-0000-0000-0000-000000000072",
                    listingID: partnerListingID,
                    wishIDs: [partnerWantedID],
                    wishGroupID: groupID,
                    wishGoodsTypeID: goodsTypeID
                )
            ],
            viewerActivityWindows: [],
            partnerActivityWindows: [],
            inventoryTags: [],
            unreadNotificationIDs: []
        )

        let sections = HomeCandidateComposer.sections(from: composition)

        XCTAssertTrue(sections.mutualMatchCandidates.isEmpty)
    }

    func testComposerKeepsCashWantedOptionsAsMutualMatchDisplayItems() throws {
        let viewerID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        let partnerID = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
        let viewerOfferID = "10000000-0000-0000-0000-000000000081"
        let partnerOfferID = "10000000-0000-0000-0000-000000000082"
        let viewerListingID = "50000000-0000-0000-0000-000000000081"
        let partnerListingID = "50000000-0000-0000-0000-000000000082"
        let groupID = "20000000-0000-0000-0000-000000000081"
        let goodsTypeID = "30000000-0000-0000-0000-000000000081"

        let composition = SupabaseHomeComposition(
            localMode: nil,
            viewerInventory: [
                try goodsRow(
                    id: viewerOfferID,
                    userID: viewerID,
                    groupID: groupID,
                    goodsTypeID: goodsTypeID,
                    title: "自分が譲るRM トレカ"
                )
            ],
            viewerWishes: [],
            viewerListings: [
                try listingRow(
                    id: viewerListingID,
                    userID: viewerID,
                    haveIDs: [viewerOfferID],
                    haveGroupID: groupID,
                    haveGoodsTypeID: goodsTypeID
                )
            ],
            partnerInventory: [
                try goodsRow(
                    id: partnerOfferID,
                    userID: partnerID,
                    groupID: groupID,
                    goodsTypeID: goodsTypeID,
                    title: "相手が譲るジン トレカ"
                )
            ],
            partnerWishes: [],
            partnerUsers: [
                try userRow(
                    id: partnerID,
                    handle: "cash_match_fixture",
                    primaryArea: "福岡県"
                )
            ],
            partnerListings: [
                try listingRow(
                    id: partnerListingID,
                    userID: partnerID,
                    haveIDs: [partnerOfferID],
                    haveGroupID: groupID,
                    haveGoodsTypeID: goodsTypeID
                )
            ],
            listingWishOptions: [
                try listingWishOptionRow(
                    id: "60000000-0000-0000-0000-000000000081",
                    listingID: viewerListingID,
                    wishIDs: [],
                    wishGroupID: nil,
                    wishGoodsTypeID: nil,
                    isCashOffer: true,
                    cashAmount: 2_000
                ),
                try listingWishOptionRow(
                    id: "60000000-0000-0000-0000-000000000082",
                    listingID: partnerListingID,
                    wishIDs: [],
                    wishGroupID: nil,
                    wishGoodsTypeID: nil,
                    isCashOffer: true,
                    cashAmount: 1_500
                )
            ],
            viewerActivityWindows: [],
            partnerActivityWindows: [],
            inventoryTags: [],
            unreadNotificationIDs: []
        )

        let candidate = try XCTUnwrap(HomeCandidateComposer.sections(from: composition).mutualMatchCandidates.first)

        XCTAssertTrue(candidate.attentionKinds.contains(.amountInsufficient))
        XCTAssertEqual(candidate.partnerDisplayItems.map(\.title), ["¥2,000"])
        XCTAssertEqual(candidate.partnerDisplayItems.map(\.kind), [.cashAmount])
        XCTAssertEqual(candidate.viewerDisplayItems.map(\.title), ["¥1,500"])
        XCTAssertEqual(candidate.viewerDisplayItems.map(\.kind), [.cashAmount])
        XCTAssertEqual(candidate.partnerGoodsItems.map(\.title), ["相手が譲るジン トレカ"])
        XCTAssertEqual(candidate.viewerGoodsItems.map(\.title), ["自分が譲るRM トレカ"])
    }

    func testComposerMarksIndividualListingHitAsGoodsConditionDirect() throws {
        let viewerHaveID = "10000000-0000-0000-0000-000000000021"
        let viewerWishID = "10000000-0000-0000-0000-000000000022"
        let partnerHaveID = "10000000-0000-0000-0000-000000000023"
        let listingID = "10000000-0000-0000-0000-000000000024"
        let composition = SupabaseHomeComposition(
            localMode: nil,
            viewerUser: try userRow(
                id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                handle: "me",
                primaryArea: "福岡県",
                paymentMethods: ["bank_transfer", "paypay"]
            ),
            viewerInventory: [
                try goodsRow(
                    id: viewerHaveID,
                    userID: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                    groupID: "20000000-0000-0000-0000-000000000021",
                    goodsTypeID: "30000000-0000-0000-0000-000000000021",
                    title: "自分が出せるグッズ",
                    exchangeType: "hand"
                )
            ],
            viewerWishes: [
                try goodsRow(
                    id: viewerWishID,
                    userID: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                    groupID: "20000000-0000-0000-0000-000000000022",
                    goodsTypeID: "30000000-0000-0000-0000-000000000022",
                    title: "自分のWish"
                )
            ],
            viewerListings: [],
            partnerInventory: [
                try goodsRow(
                    id: partnerHaveID,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: "20000000-0000-0000-0000-000000000022",
                    goodsTypeID: "30000000-0000-0000-0000-000000000022",
                    title: "相手の個別募集対象",
                    exchangeType: "hand"
                )
            ],
            partnerWishes: [],
            partnerUsers: [
                try userRow(
                    id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    handle: "mii_trade",
                    primaryArea: "福岡県",
                    paymentMethods: ["cash_exchange", "paypay"],
                    paymentNote: "差額相談可"
                )
            ],
            partnerListings: [
                try listingRow(
                    id: listingID,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    haveIDs: [partnerHaveID],
                    haveGroupID: nil,
                    haveGoodsTypeID: nil,
                    haveLogic: "and"
                )
            ],
            listingWishOptions: [
                // 個別募集の選択肢は「相手自身のほしいもの／条件／現金」のいずれか。
                // ここは条件指定（グループ＋種別）で、viewer の在庫がその条件を満たすケース。
                // 別ユーザー間の wishIDs 直接指名（自分の在庫IDを相手が指名）という経路は存在しない。iter1226.368。
                try listingWishOptionRow(
                    id: "10000000-0000-0000-0000-000000000025",
                    listingID: listingID,
                    wishIDs: [],
                    wishGroupID: "20000000-0000-0000-0000-000000000021",
                    wishGoodsTypeID: "30000000-0000-0000-0000-000000000021",
                    logic: "and"
                )
            ],
            viewerActivityWindows: [],
            partnerActivityWindows: [],
            inventoryTags: [],
            unreadNotificationIDs: []
        )

        let sections = HomeCandidateComposer.sections(from: composition)
        let partnerID = try XCTUnwrap(UUID(uuidString: partnerHaveID))
        let signals = try XCTUnwrap(sections.conditionSignalsByItemID[partnerID])

        XCTAssertEqual(sections.matchedItems.map(\.id), [partnerID])
        XCTAssertEqual(signals.goods, HomeGoodsConditionSignals(hasIndividualListingHit: true, hasWishHit: false))
        XCTAssertEqual(signals.linkCounts, HomeCandidateLinkCounts(wishCount: 0, listingCount: 1))
        XCTAssertEqual(HomeDiscoveryMatchPolicy.goodsCondition(for: signals.goods), .direct)
        XCTAssertEqual(HomeDiscoveryMatchPolicy.exchangeCondition(for: signals.exchange), .possible)
        XCTAssertEqual(HomeDiscoveryMatchPolicy.paymentCondition(for: signals.payment), .exact)
        let partnerSelection = try XCTUnwrap(signals.individualListingSelection)
        XCTAssertEqual(partnerSelection.wantedLogic, .all)
        XCTAssertEqual(partnerSelection.offeredLogic, .all)
        XCTAssertEqual(partnerSelection.wantedOptions.map(\.matchingGoodsIDs), [[UUID(uuidString: viewerHaveID)!]])
        XCTAssertEqual(sections.matchedItems.first?.exchangeMethod, .hand)
        XCTAssertEqual(sections.matchedItems.first?.ownerPrefecture, "福岡県")
        XCTAssertEqual(sections.matchedItems.first?.ownerPaymentMethods, [.paypay, .cashExchange])
        XCTAssertEqual(sections.matchedItems.first?.ownerPaymentNote, "差額相談可")
        XCTAssertEqual(
            sections.conditionSignalsByItemID[UUID(uuidString: viewerHaveID)!]?.linkCounts,
            HomeCandidateLinkCounts(wishCount: 0, listingCount: 1)
        )
        let viewerSelection = try XCTUnwrap(sections.conditionSignalsByItemID[UUID(uuidString: viewerHaveID)!]?.individualListingSelection)
        XCTAssertEqual(viewerSelection.wantedLogic, .all)
        XCTAssertEqual(viewerSelection.offeredLogic, .all)
        XCTAssertEqual(viewerSelection.wantedOptions.map(\.matchingGoodsIDs), [[UUID(uuidString: viewerHaveID)!]])
    }

    func testComposerPassesIndividualListingWantedOptionsToHomeSheetContext() throws {
        let viewerExactID = "10000000-0000-0000-0000-000000000061"
        let viewerConditionID = "10000000-0000-0000-0000-000000000062"
        let viewerUnmatchedID = "10000000-0000-0000-0000-000000000063"
        let partnerHaveID = "10000000-0000-0000-0000-000000000064"
        let partnerSecondHaveID = "10000000-0000-0000-0000-000000000069"
        let partnerWishOnlyID = "10000000-0000-0000-0000-000000000070"
        // 指名オプションが参照するのは「相手自身のほしいもの」。viewer の在庫と同じ属性を持たせ、
        // viewer がその指名を満たせる（＝相手のほしいものに合致する）ケースを表す。iter1226.368。
        let partnerWishForExactID = "10000000-0000-0000-0000-0000000000a1"
        let listingID = "10000000-0000-0000-0000-000000000065"
        let conditionGroupID = "20000000-0000-0000-0000-000000000062"
        let conditionGoodsTypeID = "30000000-0000-0000-0000-000000000062"

        let composition = SupabaseHomeComposition(
            localMode: nil,
            viewerInventory: [
                try goodsRow(
                    id: viewerExactID,
                    userID: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                    groupID: "20000000-0000-0000-0000-000000000061",
                    goodsTypeID: "30000000-0000-0000-0000-000000000061",
                    title: "自分の指定グッズ",
                    photoURLs: ["https://example.com/viewer-exact.jpg"]
                ),
                try goodsRow(
                    id: viewerConditionID,
                    userID: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                    groupID: conditionGroupID,
                    goodsTypeID: conditionGoodsTypeID,
                    title: "TWICE モモ トレカ"
                ),
                try goodsRow(
                    id: viewerUnmatchedID,
                    userID: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                    groupID: "20000000-0000-0000-0000-000000000063",
                    goodsTypeID: "30000000-0000-0000-0000-000000000063",
                    title: "条件に合わないグッズ"
                )
            ],
            viewerWishes: [],
            viewerListings: [],
            partnerInventory: [
                try goodsRow(
                    id: partnerHaveID,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: "20000000-0000-0000-0000-000000000064",
                    goodsTypeID: "30000000-0000-0000-0000-000000000064",
                    title: "相手が譲るグッズ"
                ),
                try goodsRow(
                    id: partnerSecondHaveID,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: "20000000-0000-0000-0000-000000000064",
                    goodsTypeID: "30000000-0000-0000-0000-000000000064",
                    title: "相手が譲る別グッズ"
                )
            ],
            partnerWishes: [
                try goodsRow(
                    id: partnerWishOnlyID,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: "20000000-0000-0000-0000-000000000070",
                    goodsTypeID: "30000000-0000-0000-0000-000000000070",
                    title: "相手が登録したWish画像",
                    photoURLs: ["https://example.com/partner-wish.jpg"]
                ),
                // option[0] が指名する「相手自身のほしいもの」。viewerExactID と同属性なので viewer が満たせる。
                try goodsRow(
                    id: partnerWishForExactID,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: "20000000-0000-0000-0000-000000000061",
                    goodsTypeID: "30000000-0000-0000-0000-000000000061",
                    title: "相手が指名するほしいもの",
                    photoURLs: ["https://example.com/partner-exact-wish.jpg"]
                )
            ],
            partnerUsers: [],
            partnerListings: [
                try listingRow(
                    id: listingID,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    haveIDs: [partnerHaveID, partnerSecondHaveID],
                    haveQtys: [2, 1],
                    haveGroupID: nil,
                    haveGoodsTypeID: nil,
                    haveLogic: "or",
                    note: """
                    条件外でも写真を見て相談したいです
                    交換手段: 現地交換 / 都道府県: 東京都 / 場所メモ: 相談 / 日程: 相談して決める / 送料: 要相談 / 発送目安: 2〜4日以内 / 条件外打診: 可
                    """
                )
            ],
            listingWishOptions: [
                try listingWishOptionRow(
                    id: "10000000-0000-0000-0000-000000000066",
                    listingID: listingID,
                    position: 1,
                    wishIDs: [partnerWishForExactID],
                    wishGroupID: nil,
                    wishGoodsTypeID: nil
                ),
                try listingWishOptionRow(
                    id: "10000000-0000-0000-0000-000000000067",
                    listingID: listingID,
                    position: 2,
                    wishIDs: [],
                    wishGroupID: conditionGroupID,
                    wishGoodsTypeID: conditionGoodsTypeID
                ),
                try listingWishOptionRow(
                    id: "10000000-0000-0000-0000-000000000068",
                    listingID: listingID,
                    position: 3,
                    wishIDs: [],
                    wishGroupID: nil,
                    wishGoodsTypeID: nil,
                    isCashOffer: true,
                    cashAmount: 1_500
                ),
                try listingWishOptionRow(
                    id: "10000000-0000-0000-0000-000000000071",
                    listingID: listingID,
                    position: 4,
                    wishIDs: [partnerWishOnlyID],
                    wishGroupID: nil,
                    wishGoodsTypeID: nil
                )
            ],
            viewerActivityWindows: [],
            partnerActivityWindows: [],
            inventoryTags: [
                try inventoryTagRow(
                    inventoryID: viewerExactID,
                    tagID: "40000000-0000-0000-0000-000000000066",
                    label: "ライブ2026"
                ),
                try inventoryTagRow(
                    inventoryID: partnerWishForExactID,
                    tagID: "40000000-0000-0000-0000-0000000000a1",
                    label: "ライブ2026"
                ),
                try inventoryTagRow(
                    inventoryID: partnerWishOnlyID,
                    tagID: "40000000-0000-0000-0000-000000000071",
                    label: "会場限定"
                )
            ],
            unreadNotificationIDs: []
        )

        let sections = HomeCandidateComposer.sections(from: composition)
        let partnerSignals = try XCTUnwrap(sections.conditionSignalsByItemID[UUID(uuidString: partnerHaveID)!])
        let options = try XCTUnwrap(partnerSignals.individualListingSelection?.wantedOptions)

        XCTAssertEqual(options.map(\.kind), [.goods, .condition, .cash])
        XCTAssertEqual(options[0].matchingGoodsIDs, [UUID(uuidString: viewerExactID)!])
        XCTAssertEqual(options[1].matchingGoodsIDs, [UUID(uuidString: viewerConditionID)!])
        XCTAssertEqual(options[2].cashAmount, 1_500)
        XCTAssertFalse(options[1].matchingGoodsIDs.contains(UUID(uuidString: viewerUnmatchedID)!))
        XCTAssertEqual(partnerSignals.individualListingSelection?.listingNote, "条件外でも写真を見て相談したいです")
        let partnerDetail = try XCTUnwrap(partnerSignals.individualListingSelection?.detail)
        XCTAssertEqual(partnerDetail.listingID, UUID(uuidString: listingID)!)
        XCTAssertEqual(partnerDetail.offeredLogic, .one)
        XCTAssertEqual(partnerDetail.offeredItems.map(\.id), [UUID(uuidString: partnerHaveID)!, UUID(uuidString: partnerSecondHaveID)!])
        XCTAssertEqual(partnerDetail.offeredItems.map(\.title), ["相手が譲るグッズ", "相手が譲る別グッズ"])
        XCTAssertEqual(partnerDetail.offeredItems.map(\.quantity), [2, 1])
        XCTAssertEqual(partnerDetail.wantedOptions.map(\.kind), [.goods, .condition, .cash, .goods])
        // 指名オプションのプレビューは相手自身のほしいもの画像（partnerWishForExactID）を表示する。iter1226.368。
        XCTAssertEqual(partnerDetail.wantedOptions[0].previewItems.map(\.imageURL?.absoluteString), ["https://example.com/partner-exact-wish.jpg"])
        XCTAssertEqual(partnerDetail.wantedOptions[0].previewItems.map(\.rawTagNames), [["ライブ2026"]])
        XCTAssertEqual(partnerDetail.wantedOptions[3].previewItems.map(\.imageURL?.absoluteString), ["https://example.com/partner-wish.jpg"])
        XCTAssertEqual(partnerDetail.wantedOptions[3].previewItems.map(\.rawTagNames), [["会場限定"]])

        let viewerSignals = try XCTUnwrap(sections.conditionSignalsByItemID[UUID(uuidString: viewerExactID)!])
        XCTAssertEqual(viewerSignals.individualListingSelection?.wantedOptions.map(\.kind), [.goods])
        XCTAssertEqual(viewerSignals.individualListingSelection?.listingNote, "条件外でも写真を見て相談したいです")
        XCTAssertEqual(viewerSignals.individualListingSelection?.detail?.offeredItems.map(\.title), ["相手が譲るグッズ", "相手が譲る別グッズ"])
    }

    func testComposerExpandsConditionBasedListingOfferItemsForDetailContext() throws {
        let viewerHaveID = "10000000-0000-0000-0000-000000000072"
        let partnerFirstHaveID = "10000000-0000-0000-0000-000000000073"
        let partnerSecondHaveID = "10000000-0000-0000-0000-000000000074"
        let partnerOtherHaveID = "10000000-0000-0000-0000-000000000075"
        let listingID = "10000000-0000-0000-0000-000000000076"
        let offeredGroupID = "20000000-0000-0000-0000-000000000073"
        let offeredGoodsTypeID = "30000000-0000-0000-0000-000000000073"

        let composition = SupabaseHomeComposition(
            localMode: nil,
            viewerInventory: [
                try goodsRow(
                    id: viewerHaveID,
                    userID: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                    groupID: "20000000-0000-0000-0000-000000000072",
                    goodsTypeID: "30000000-0000-0000-0000-000000000072",
                    title: "自分が譲れるグッズ"
                )
            ],
            viewerWishes: [],
            viewerListings: [],
            partnerInventory: [
                try goodsRow(
                    id: partnerFirstHaveID,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: offeredGroupID,
                    goodsTypeID: offeredGoodsTypeID,
                    title: "条件一致の相手グッズ1"
                ),
                try goodsRow(
                    id: partnerSecondHaveID,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: offeredGroupID,
                    goodsTypeID: offeredGoodsTypeID,
                    title: "条件一致の相手グッズ2"
                ),
                try goodsRow(
                    id: partnerOtherHaveID,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: "20000000-0000-0000-0000-000000000075",
                    goodsTypeID: offeredGoodsTypeID,
                    title: "条件外の相手グッズ"
                )
            ],
            partnerWishes: [],
            partnerUsers: [],
            partnerListings: [
                try listingRow(
                    id: listingID,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    haveIDs: [],
                    haveGroupID: offeredGroupID,
                    haveGoodsTypeID: offeredGoodsTypeID,
                    haveLogic: "at_least"
                )
            ],
            listingWishOptions: [
                try listingWishOptionRow(
                    id: "10000000-0000-0000-0000-000000000077",
                    listingID: listingID,
                    wishIDs: [viewerHaveID],
                    wishGroupID: nil,
                    wishGoodsTypeID: nil
                )
            ],
            viewerActivityWindows: [],
            partnerActivityWindows: [],
            inventoryTags: [],
            unreadNotificationIDs: []
        )

        let sections = HomeCandidateComposer.sections(from: composition)
        let signals = try XCTUnwrap(sections.conditionSignalsByItemID[UUID(uuidString: partnerFirstHaveID)!])
        let detail = try XCTUnwrap(signals.individualListingSelection?.detail)

        XCTAssertEqual(detail.offeredLogic, .atLeast)
        XCTAssertEqual(detail.offeredItems.map(\.title), ["条件一致の相手グッズ1", "条件一致の相手グッズ2"])
    }

    func testExplicitHaveIDsDoNotUseStaleConditionFieldsForCandidateMatching() throws {
        let viewerHaveID = "10000000-0000-0000-0000-000000000091"
        let oldPartnerHaveID = "10000000-0000-0000-0000-000000000092"
        let targetPartnerHaveID = "10000000-0000-0000-0000-000000000093"
        let oldListingID = "10000000-0000-0000-0000-000000000094"
        let targetListingID = "10000000-0000-0000-0000-000000000095"
        let groupID = "20000000-0000-0000-0000-000000000091"
        let goodsTypeID = "30000000-0000-0000-0000-000000000091"

        let composition = SupabaseHomeComposition(
            localMode: nil,
            viewerInventory: [
                try goodsRow(
                    id: viewerHaveID,
                    userID: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                    groupID: groupID,
                    goodsTypeID: goodsTypeID,
                    title: "自分が譲るグッズ"
                )
            ],
            viewerWishes: [],
            viewerListings: [],
            partnerInventory: [
                try goodsRow(
                    id: oldPartnerHaveID,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: groupID,
                    goodsTypeID: goodsTypeID,
                    title: "古い募集の譲るグッズ"
                ),
                try goodsRow(
                    id: targetPartnerHaveID,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: groupID,
                    goodsTypeID: goodsTypeID,
                    title: "対象の譲るグッズ"
                )
            ],
            partnerWishes: [],
            partnerUsers: [
                try userRow(
                    id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    handle: "explicit_have_ids",
                    primaryArea: "大阪府"
                )
            ],
            partnerListings: [
                try listingRow(
                    id: oldListingID,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    haveIDs: [oldPartnerHaveID],
                    haveGroupID: groupID,
                    haveGoodsTypeID: goodsTypeID,
                    haveLogic: "or"
                ),
                try listingRow(
                    id: targetListingID,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    haveIDs: [targetPartnerHaveID],
                    haveGroupID: nil,
                    haveGoodsTypeID: nil,
                    haveLogic: "or"
                )
            ],
            listingWishOptions: [
                try listingWishOptionRow(
                    id: "10000000-0000-0000-0000-000000000096",
                    listingID: oldListingID,
                    wishIDs: [],
                    wishGroupID: groupID,
                    wishGoodsTypeID: goodsTypeID
                ),
                try listingWishOptionRow(
                    id: "10000000-0000-0000-0000-000000000097",
                    listingID: targetListingID,
                    wishIDs: [],
                    wishGroupID: groupID,
                    wishGoodsTypeID: goodsTypeID
                )
            ],
            viewerActivityWindows: [],
            partnerActivityWindows: [],
            inventoryTags: [],
            unreadNotificationIDs: []
        )

        let sections = HomeCandidateComposer.sections(from: composition)
        let signals = try XCTUnwrap(sections.conditionSignalsByItemID[UUID(uuidString: targetPartnerHaveID)!])
        let selection = try XCTUnwrap(signals.individualListingSelection)

        XCTAssertEqual(selection.detail?.listingID, UUID(uuidString: targetListingID))
        XCTAssertEqual(selection.detail?.offeredItems.map(\.id), [UUID(uuidString: targetPartnerHaveID)!])
    }

    func testComposerKeepsOneSidedCandidatesPossible() throws {
        let composition = SupabaseHomeComposition(
            localMode: nil,
            viewerInventory: [
                try goodsRow(
                    id: "10000000-0000-0000-0000-000000000011",
                    userID: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                    groupID: "20000000-0000-0000-0000-000000000011",
                    goodsTypeID: "30000000-0000-0000-0000-000000000011",
                    title: "自分の在庫"
                )
            ],
            viewerWishes: [
                try goodsRow(
                    id: "10000000-0000-0000-0000-000000000012",
                    userID: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                    groupID: "20000000-0000-0000-0000-000000000012",
                    goodsTypeID: nil,
                    title: "グループだけ指定したWish"
                )
            ],
            viewerListings: [],
            partnerInventory: [
                try goodsRow(
                    id: "10000000-0000-0000-0000-000000000013",
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: "20000000-0000-0000-0000-000000000012",
                    goodsTypeID: "30000000-0000-0000-0000-000000000099",
                    title: "自分のWishに合う相手在庫"
                ),
                try goodsRow(
                    id: "10000000-0000-0000-0000-000000000014",
                    userID: "cccccccc-cccc-cccc-cccc-cccccccccccc",
                    groupID: "20000000-0000-0000-0000-000000000098",
                    goodsTypeID: "30000000-0000-0000-0000-000000000098",
                    title: "相手だけが欲しい在庫"
                )
            ],
            partnerWishes: [
                try goodsRow(
                    id: "10000000-0000-0000-0000-000000000015",
                    userID: "cccccccc-cccc-cccc-cccc-cccccccccccc",
                    groupID: "20000000-0000-0000-0000-000000000011",
                    goodsTypeID: "30000000-0000-0000-0000-000000000011",
                    title: "相手のWish"
                )
            ],
            partnerUsers: [],
            partnerListings: [],
            listingWishOptions: [],
            viewerActivityWindows: [],
            partnerActivityWindows: [],
            inventoryTags: [],
            unreadNotificationIDs: []
        )

        let sections = HomeCandidateComposer.sections(from: composition)

        XCTAssertTrue(sections.matchedItems.isEmpty)
        XCTAssertEqual(
            sections.possibleItems.map(\.id),
            [
                UUID(uuidString: "10000000-0000-0000-0000-000000000013")!,
                UUID(uuidString: "10000000-0000-0000-0000-000000000014")!
            ]
        )
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.goodsCondition(
                for: try XCTUnwrap(sections.conditionSignalsByItemID[
                    UUID(uuidString: "10000000-0000-0000-0000-000000000013")!
                ]?.goods)
            ),
            .none
        )
        XCTAssertEqual(
            HomeDiscoveryMatchPolicy.goodsCondition(
                for: try XCTUnwrap(sections.conditionSignalsByItemID[
                    UUID(uuidString: "10000000-0000-0000-0000-000000000014")!
                ]?.goods)
            ),
            .wish
        )
    }

    func testComposerDoesNotTreatGroupOnlyWishAsMemberWishMatch() throws {
        let groupID = "20000000-0000-0000-0000-0000000000f1"
        let sanaID = "21000000-0000-0000-0000-0000000000f1"
        let goodsTypeID = "30000000-0000-0000-0000-0000000000f1"
        let partnerGoodsID = UUID(uuidString: "10000000-0000-0000-0000-0000000000f1")!

        let composition = SupabaseHomeComposition(
            localMode: nil,
            viewerInventory: [],
            viewerWishes: [
                try goodsRow(
                    id: "10000000-0000-0000-0000-0000000000f2",
                    userID: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                    groupID: groupID,
                    goodsTypeID: goodsTypeID,
                    title: "TWICE トレカ"
                )
            ],
            viewerListings: [],
            partnerInventory: [
                try goodsRow(
                    id: partnerGoodsID.uuidString,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: groupID,
                    characterID: sanaID,
                    goodsTypeID: goodsTypeID,
                    title: "サナ トレカ",
                    groupName: "TWICE",
                    characterName: "サナ",
                    goodsTypeName: "トレカ"
                )
            ],
            partnerWishes: [],
            partnerUsers: [],
            partnerListings: [],
            listingWishOptions: [],
            viewerActivityWindows: [],
            partnerActivityWindows: [],
            inventoryTags: [],
            unreadNotificationIDs: []
        )

        let sections = HomeCandidateComposer.sections(from: composition)
        let signals = try XCTUnwrap(sections.conditionSignalsByItemID[partnerGoodsID])

        XCTAssertTrue(signals.matchesViewerWish)
        XCTAssertFalse(signals.matchesViewerWishCharacter)
    }

    func testComposerMarksExactL2WishAsMemberWishMatch() throws {
        let groupID = "20000000-0000-0000-0000-0000000000f3"
        let sanaID = "21000000-0000-0000-0000-0000000000f3"
        let goodsTypeID = "30000000-0000-0000-0000-0000000000f3"
        let partnerGoodsID = UUID(uuidString: "10000000-0000-0000-0000-0000000000f3")!

        let composition = SupabaseHomeComposition(
            localMode: nil,
            viewerInventory: [],
            viewerWishes: [
                try goodsRow(
                    id: "10000000-0000-0000-0000-0000000000f4",
                    userID: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                    groupID: groupID,
                    characterID: sanaID,
                    goodsTypeID: goodsTypeID,
                    title: "サナ トレカ",
                    groupName: "TWICE",
                    characterName: "サナ",
                    goodsTypeName: "トレカ"
                )
            ],
            viewerListings: [],
            partnerInventory: [
                try goodsRow(
                    id: partnerGoodsID.uuidString,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: groupID,
                    characterID: sanaID,
                    goodsTypeID: goodsTypeID,
                    title: "サナ トレカ",
                    groupName: "TWICE",
                    characterName: "サナ",
                    goodsTypeName: "トレカ"
                )
            ],
            partnerWishes: [],
            partnerUsers: [],
            partnerListings: [],
            listingWishOptions: [],
            viewerActivityWindows: [],
            partnerActivityWindows: [],
            inventoryTags: [],
            unreadNotificationIDs: []
        )

        let sections = HomeCandidateComposer.sections(from: composition)
        let signals = try XCTUnwrap(sections.conditionSignalsByItemID[partnerGoodsID])

        XCTAssertTrue(signals.matchesViewerWish)
        XCTAssertTrue(signals.matchesViewerWishCharacter)
    }

    func testComposerUsesSpecificOshiWhenViewerHasNoWishes() throws {
        let viewerID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let groupID = UUID(uuidString: "20000000-0000-0000-0000-000000000101")!
        let memberID = UUID(uuidString: "21000000-0000-0000-0000-000000000101")!
        let partnerGoodsID = UUID(uuidString: "10000000-0000-0000-0000-000000000101")!
        let composition = SupabaseHomeComposition(
            localMode: nil,
            viewerInventory: [],
            viewerWishes: [],
            viewerListings: [],
            partnerInventory: [
                try goodsRow(
                    id: partnerGoodsID.uuidString,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: groupID.uuidString,
                    characterID: memberID.uuidString,
                    goodsTypeID: "30000000-0000-0000-0000-000000000101",
                    title: "Aさん トレカ",
                    groupName: "BTS",
                    characterName: "Aさん",
                    goodsTypeName: "トレカ"
                )
            ],
            partnerWishes: [],
            partnerUsers: [],
            partnerListings: [],
            listingWishOptions: [],
            viewerActivityWindows: [],
            partnerActivityWindows: [],
            inventoryTags: [],
            unreadNotificationIDs: []
        )
        let oshiSelections = [
            UserOshiSelection(
                id: UUID(uuidString: "90000000-0000-0000-0000-000000000101")!,
                userID: viewerID,
                groupID: groupID,
                characterID: memberID,
                kind: .specific,
                priority: 1,
                groupName: "BTS",
                characterName: "Aさん"
            )
        ]

        let sections = HomeCandidateComposer.sections(
            from: composition,
            viewerOshiSelections: oshiSelections
        )
        let signals = try XCTUnwrap(sections.conditionSignalsByItemID[partnerGoodsID])
        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: sections.possibleItems,
            source: .user,
            goodsTypes: [],
            conditionSignalsByItemID: sections.conditionSignalsByItemID
        )

        XCTAssertEqual(sections.possibleItems.map(\.id), [partnerGoodsID])
        XCTAssertTrue(signals.matchesViewerWish)
        XCTAssertTrue(signals.matchesViewerWishCharacter)
        XCTAssertTrue(HomeDiscoveryMatchPolicy.isMemberMatchEligible(item: sections.possibleItems[0], signals: signals))
        XCTAssertEqual(candidates.map(\.title), ["Aさん"])
    }

    func testComposerUsesSoloOshiAsGroupCandidateWhenViewerHasNoWishes() throws {
        let viewerID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let soloGroupID = UUID(uuidString: "20000000-0000-0000-0000-000000000102")!
        let partnerGoodsID = UUID(uuidString: "10000000-0000-0000-0000-000000000102")!
        let composition = SupabaseHomeComposition(
            localMode: nil,
            viewerInventory: [],
            viewerWishes: [],
            viewerListings: [],
            partnerInventory: [
                try goodsRow(
                    id: partnerGoodsID.uuidString,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: soloGroupID.uuidString,
                    goodsTypeID: "30000000-0000-0000-0000-000000000102",
                    title: "IU ペンライト",
                    groupName: "IU",
                    goodsTypeName: "ペンライト"
                )
            ],
            partnerWishes: [],
            partnerUsers: [],
            partnerListings: [],
            listingWishOptions: [],
            viewerActivityWindows: [],
            partnerActivityWindows: [],
            inventoryTags: [],
            unreadNotificationIDs: []
        )
        let oshiSelections = [
            UserOshiSelection(
                id: UUID(uuidString: "90000000-0000-0000-0000-000000000102")!,
                userID: viewerID,
                groupID: soloGroupID,
                characterID: nil,
                kind: .box,
                priority: 1,
                groupName: "IU"
            )
        ]

        let sections = HomeCandidateComposer.sections(
            from: composition,
            viewerOshiSelections: oshiSelections
        )
        let signals = try XCTUnwrap(sections.conditionSignalsByItemID[partnerGoodsID])
        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: sections.possibleItems,
            source: .user,
            goodsTypes: [],
            conditionSignalsByItemID: sections.conditionSignalsByItemID
        )

        XCTAssertEqual(sections.possibleItems.map(\.id), [partnerGoodsID])
        XCTAssertNil(sections.possibleItems.first?.memberID)
        XCTAssertTrue(signals.matchesViewerWish)
        XCTAssertTrue(signals.matchesViewerWishCharacter)
        XCTAssertTrue(HomeDiscoveryMatchPolicy.isMemberMatchEligible(item: sections.possibleItems[0], signals: signals))
        XCTAssertEqual(candidates.map(\.title), ["IU"])
    }

    func testComposerDoesNotUseOshiFallbackWhenViewerHasWishes() throws {
        let viewerID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let wishGroupID = UUID(uuidString: "20000000-0000-0000-0000-000000000103")!
        let oshiGroupID = UUID(uuidString: "20000000-0000-0000-0000-000000000104")!
        let partnerGoodsID = UUID(uuidString: "10000000-0000-0000-0000-000000000103")!
        let composition = SupabaseHomeComposition(
            localMode: nil,
            viewerInventory: [],
            viewerWishes: [
                try goodsRow(
                    id: "10000000-0000-0000-0000-000000000104",
                    userID: viewerID.uuidString,
                    groupID: wishGroupID.uuidString,
                    goodsTypeID: "30000000-0000-0000-0000-000000000103",
                    title: "登録済みWish"
                )
            ],
            viewerListings: [],
            partnerInventory: [
                try goodsRow(
                    id: partnerGoodsID.uuidString,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: oshiGroupID.uuidString,
                    goodsTypeID: "30000000-0000-0000-0000-000000000103",
                    title: "推しには合うがWishには合わないグッズ"
                )
            ],
            partnerWishes: [],
            partnerUsers: [],
            partnerListings: [],
            listingWishOptions: [],
            viewerActivityWindows: [],
            partnerActivityWindows: [],
            inventoryTags: [],
            unreadNotificationIDs: []
        )
        let oshiSelections = [
            UserOshiSelection(
                id: UUID(uuidString: "90000000-0000-0000-0000-000000000103")!,
                userID: viewerID,
                groupID: oshiGroupID,
                characterID: nil,
                kind: .box,
                priority: 1,
                groupName: "推しグループ"
            )
        ]

        let sections = HomeCandidateComposer.sections(
            from: composition,
            viewerOshiSelections: oshiSelections
        )

        XCTAssertTrue(sections.matchedItems.isEmpty)
        XCTAssertTrue(sections.possibleItems.isEmpty)
        XCTAssertFalse(sections.conditionSignalsByItemID[partnerGoodsID]?.matchesViewerWish ?? true)
        XCTAssertFalse(sections.conditionSignalsByItemID[partnerGoodsID]?.matchesViewerWishCharacter ?? true)
    }

    func testComposerHidesUnavailablePartnerStock() throws {
        let composition = SupabaseHomeComposition(
            localMode: nil,
            viewerInventory: [],
            viewerWishes: [
                try goodsRow(
                    id: "10000000-0000-0000-0000-000000000051",
                    userID: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                    groupID: "20000000-0000-0000-0000-000000000051",
                    goodsTypeID: "30000000-0000-0000-0000-000000000051",
                    title: "自分のWish"
                )
            ],
            viewerListings: [],
            partnerInventory: [
                try goodsRow(
                    id: "10000000-0000-0000-0000-000000000052",
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    groupID: "20000000-0000-0000-0000-000000000051",
                    goodsTypeID: "30000000-0000-0000-0000-000000000051",
                    title: "ロック済みで市場残数0の相手在庫",
                    quantity: 2,
                    lockedQty: 2
                ),
                try goodsRow(
                    id: "10000000-0000-0000-0000-000000000053",
                    userID: "cccccccc-cccc-cccc-cccc-cccccccccccc",
                    groupID: "20000000-0000-0000-0000-000000000051",
                    goodsTypeID: "30000000-0000-0000-0000-000000000051",
                    title: "表示できる相手在庫",
                    quantity: 2,
                    lockedQty: 1
                )
            ],
            partnerWishes: [],
            partnerUsers: [],
            partnerListings: [],
            listingWishOptions: [],
            viewerActivityWindows: [],
            partnerActivityWindows: [],
            inventoryTags: [],
            unreadNotificationIDs: []
        )

        let sections = HomeCandidateComposer.sections(from: composition)

        XCTAssertTrue(sections.matchedItems.isEmpty)
        XCTAssertEqual(
            sections.possibleItems.map(\.id),
            [UUID(uuidString: "10000000-0000-0000-0000-000000000053")!]
        )
        XCTAssertEqual(sections.possibleItems.first?.quantity, 1)
        XCTAssertNil(sections.conditionSignalsByItemID[UUID(uuidString: "10000000-0000-0000-0000-000000000052")!])
    }

    private func goodsRow(
        id: String,
        userID: String,
        groupID: String?,
        characterID: String? = nil,
        goodsTypeID: String?,
        title: String,
        groupName: String? = nil,
        characterName: String? = nil,
        goodsTypeName: String? = nil,
        photoURLs: [String] = [],
        quantity: Int = 1,
        lockedQty: Int? = nil,
        marketAvailableQty: Int? = nil,
        exchangeType: String? = nil
    ) throws -> SupabaseHomeGoodsRow {
        let payload: [String: Any?] = [
            "id": id,
            "userId": userID,
            "kind": "for_trade",
            "groupId": groupID,
            "characterId": characterID,
            "characterRequestId": nil,
            "goodsTypeId": goodsTypeID,
            "title": title,
            "photoUrls": photoURLs,
            "quantity": quantity,
            "lockedQty": lockedQty,
            "marketAvailableQty": marketAvailableQty,
            "exchangeType": exchangeType,
            "hue": nil,
            "status": "active",
            "group": groupName.map { ["name": $0] },
            "character": characterName.map { ["name": $0] },
            "goodsType": goodsTypeName.map { ["name": $0] }
        ]
        return try decode(SupabaseHomeGoodsRow.self, payload)
    }

    private func userRow(
        id: String,
        handle: String,
        primaryArea: String,
        paymentMethods: [String] = [],
        paymentNote: String? = nil,
        isTestAccount: Bool? = nil,
        age: Int? = nil,
        averageStars: Double? = nil,
        evaluationCount: Int? = nil,
        completedTradeCount: Int? = nil
    ) throws -> SupabaseHomeUserRow {
        try decode(
            SupabaseHomeUserRow.self,
            [
                "id": id,
                "handle": handle,
                "displayName": handle,
                "primaryArea": primaryArea,
                "avatarUrl": nil,
                "age": age,
                "paymentMethods": paymentMethods,
                "paymentNote": paymentNote,
                "isTestAccount": isTestAccount,
                "averageStars": averageStars,
                "evaluationCount": evaluationCount,
                "completedTradeCount": completedTradeCount
            ]
        )
    }

    private func listingRow(
        id: String,
        userID: String,
        haveIDs: [String],
        haveQtys: [Int]? = nil,
        haveGroupID: String?,
        haveGoodsTypeID: String?,
        haveLogic: String = "or",
        note: String? = nil
    ) throws -> SupabaseHomeListingRow {
        try decode(
            SupabaseHomeListingRow.self,
            [
                "id": id,
                "userId": userID,
                "haveIds": haveIDs,
                "haveQtys": haveQtys ?? haveIDs.map { _ in 1 },
                "haveLogic": haveLogic,
                "haveGroupId": haveGroupID,
                "haveGoodsTypeId": haveGoodsTypeID,
                "status": "active",
                "note": note,
                "createdAt": nil,
                "updatedAt": nil
            ]
        )
    }

    private func listingWishOptionRow(
        id: String,
        listingID: String,
        position: Int = 1,
        wishIDs: [String],
        wishGroupID: String?,
        wishGoodsTypeID: String?,
        logic: String = "or",
        isCashOffer: Bool = false,
        cashAmount: Int? = nil,
        wishMemberIDs: [String] = [],
        excludesWishMembers: Bool = false,
        wishSeriesNames: [String] = [],
        wishQuantity: Int = 1
    ) throws -> SupabaseHomeListingWishOptionRow {
        try decode(
            SupabaseHomeListingWishOptionRow.self,
            [
                "id": id,
                "listingId": listingID,
                "position": position,
                "wishIds": wishIDs,
                "wishQtys": wishIDs.map { _ in 1 },
                "logic": logic,
                "exchangeType": "any",
                "isCashOffer": isCashOffer,
                "cashAmount": cashAmount,
                "wishGroupId": wishGroupID,
                "wishGoodsTypeId": wishGoodsTypeID,
                "wishMemberIds": wishMemberIDs,
                "excludesWishMembers": excludesWishMembers,
                "wishSeriesNames": wishSeriesNames,
                "wishQuantity": wishQuantity,
                "createdAt": nil,
                "updatedAt": nil
            ]
        )
    }

    private func inventoryTagRow(inventoryID: String, tagID: String, label: String) throws -> SupabaseHomeInventoryTagRow {
        try decode(
            SupabaseHomeInventoryTagRow.self,
            [
                "inventoryId": inventoryID,
                "tagId": tagID,
                "tag": ["label": label]
            ]
        )
    }

    private func decode<T: Decodable>(_ type: T.Type, _ payload: [String: Any?]) throws -> T {
        let sanitized = payload.compactMapValues { $0 }
        let data = try JSONSerialization.data(withJSONObject: sanitized, options: [])
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - 条件指定型選択肢（メンバー/シリーズ/数量）のマッチ

    func testConditionOptionRespectsMemberInclusionAndExclusion() throws {
        let groupID = "aaaaaaaa-0000-0000-0000-000000000001"
        let typeID = "aaaaaaaa-0000-0000-0000-000000000002"
        let memberA = "aaaaaaaa-0000-0000-0000-00000000000a"
        let memberB = "aaaaaaaa-0000-0000-0000-00000000000b"

        let itemOfA = try goodsRow(
            id: "bbbbbbbb-0000-0000-0000-000000000001",
            userID: "cccccccc-0000-0000-0000-000000000001",
            groupID: groupID,
            characterID: memberA,
            goodsTypeID: typeID,
            title: "Aのトレカ"
        )
        let itemOfB = try goodsRow(
            id: "bbbbbbbb-0000-0000-0000-000000000002",
            userID: "cccccccc-0000-0000-0000-000000000001",
            groupID: groupID,
            characterID: memberB,
            goodsTypeID: typeID,
            title: "Bのトレカ"
        )

        // Aを指定 → Aのグッズだけマッチ
        let includeOption = try listingWishOptionRow(
            id: "dddddddd-0000-0000-0000-000000000001",
            listingID: "eeeeeeee-0000-0000-0000-000000000001",
            wishIDs: [],
            wishGroupID: groupID,
            wishGoodsTypeID: typeID,
            wishMemberIDs: [memberA]
        )
        XCTAssertTrue(
            HomeMutualMatchListingEvaluator.mutualOptionWantsCounterpartGoods(
                includeOption, counterpartItem: itemOfA, rowsByID: [:]
            )
        )
        XCTAssertFalse(
            HomeMutualMatchListingEvaluator.mutualOptionWantsCounterpartGoods(
                includeOption, counterpartItem: itemOfB, rowsByID: [:]
            )
        )

        // A以外を指定 → Bのグッズだけマッチ
        let excludeOption = try listingWishOptionRow(
            id: "dddddddd-0000-0000-0000-000000000002",
            listingID: "eeeeeeee-0000-0000-0000-000000000001",
            wishIDs: [],
            wishGroupID: groupID,
            wishGoodsTypeID: typeID,
            wishMemberIDs: [memberA],
            excludesWishMembers: true
        )
        XCTAssertFalse(
            HomeMutualMatchListingEvaluator.mutualOptionWantsCounterpartGoods(
                excludeOption, counterpartItem: itemOfA, rowsByID: [:]
            )
        )
        XCTAssertTrue(
            HomeMutualMatchListingEvaluator.mutualOptionWantsCounterpartGoods(
                excludeOption, counterpartItem: itemOfB, rowsByID: [:]
            )
        )
    }

    func testConditionOptionRespectsSeriesNames() throws {
        let groupID = "aaaaaaaa-0000-0000-0000-000000000001"
        let typeID = "aaaaaaaa-0000-0000-0000-000000000002"
        let itemID = "bbbbbbbb-0000-0000-0000-000000000001"
        let item = try goodsRow(
            id: itemID,
            userID: "cccccccc-0000-0000-0000-000000000001",
            groupID: groupID,
            goodsTypeID: typeID,
            title: "トレカ"
        )
        let option = try listingWishOptionRow(
            id: "dddddddd-0000-0000-0000-000000000001",
            listingID: "eeeeeeee-0000-0000-0000-000000000001",
            wishIDs: [],
            wishGroupID: groupID,
            wishGoodsTypeID: typeID,
            wishSeriesNames: ["MAP OF THE SOUL"]
        )
        let matchingTag = try inventoryTagRow(
            inventoryID: itemID,
            tagID: "ffffffff-0000-0000-0000-000000000001",
            label: "#map of the soul"
        )
        let differentTag = try inventoryTagRow(
            inventoryID: itemID,
            tagID: "ffffffff-0000-0000-0000-000000000002",
            label: "#persona"
        )

        // 一致シリーズ → 確定マッチ。
        XCTAssertEqual(
            HomeMutualMatchListingEvaluator.mutualOptionMatchConfidence(
                option,
                counterpartItem: item,
                rowsByID: [:],
                tagsByInventoryID: [item.id: [matchingTag]]
            ),
            .confirmed
        )
        // シリーズ無記載 → 不確定マッチ（iter1226.363）。
        XCTAssertEqual(
            HomeMutualMatchListingEvaluator.mutualOptionMatchConfidence(
                option,
                counterpartItem: item,
                rowsByID: [:],
                tagsByInventoryID: [:]
            ),
            .tentative
        )
        // 別シリーズ（記載あり・不一致）→ 非マッチ。
        XCTAssertNil(
            HomeMutualMatchListingEvaluator.mutualOptionMatchConfidence(
                option,
                counterpartItem: item,
                rowsByID: [:],
                tagsByInventoryID: [item.id: [differentTag]]
            )
        )
    }
}
