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
            HomeDiscoveryMatchPolicy.goodsCondition(
                for: try XCTUnwrap(sections.conditionSignalsByItemID[
                    UUID(uuidString: "10000000-0000-0000-0000-000000000003")!
                ]?.goods)
            ),
            .wish
        )
        XCTAssertTrue(sections.possibleItems.isEmpty)
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
                try listingWishOptionRow(
                    id: "10000000-0000-0000-0000-000000000025",
                    listingID: listingID,
                    wishIDs: [viewerHaveID],
                    wishGroupID: nil,
                    wishGoodsTypeID: nil,
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
        XCTAssertEqual(HomeDiscoveryMatchPolicy.exchangeCondition(for: signals.exchange), .exact)
        XCTAssertEqual(HomeDiscoveryMatchPolicy.paymentCondition(for: signals.payment), .compatible)
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
                    title: "自分の指定グッズ"
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
                )
            ],
            partnerWishes: [],
            partnerUsers: [],
            partnerListings: [
                try listingRow(
                    id: listingID,
                    userID: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    haveIDs: [partnerHaveID],
                    haveGroupID: nil,
                    haveGoodsTypeID: nil
                )
            ],
            listingWishOptions: [
                try listingWishOptionRow(
                    id: "10000000-0000-0000-0000-000000000066",
                    listingID: listingID,
                    position: 1,
                    wishIDs: [viewerExactID],
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
                )
            ],
            viewerActivityWindows: [],
            partnerActivityWindows: [],
            inventoryTags: [],
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

        let viewerSignals = try XCTUnwrap(sections.conditionSignalsByItemID[UUID(uuidString: viewerExactID)!])
        XCTAssertEqual(viewerSignals.individualListingSelection?.wantedOptions.map(\.kind), [.goods])
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
        goodsTypeID: String?,
        title: String,
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
            "characterId": nil,
            "characterRequestId": nil,
            "goodsTypeId": goodsTypeID,
            "title": title,
            "photoUrls": photoURLs,
            "quantity": quantity,
            "lockedQty": lockedQty,
            "marketAvailableQty": marketAvailableQty,
            "exchangeType": exchangeType,
            "hue": nil,
            "status": "active"
        ]
        return try decode(SupabaseHomeGoodsRow.self, payload)
    }

    private func userRow(
        id: String,
        handle: String,
        primaryArea: String,
        paymentMethods: [String] = [],
        paymentNote: String? = nil
    ) throws -> SupabaseHomeUserRow {
        try decode(
            SupabaseHomeUserRow.self,
            [
                "id": id,
                "handle": handle,
                "displayName": handle,
                "primaryArea": primaryArea,
                "avatarUrl": nil,
                "paymentMethods": paymentMethods,
                "paymentNote": paymentNote
            ]
        )
    }

    private func listingRow(
        id: String,
        userID: String,
        haveIDs: [String],
        haveGroupID: String?,
        haveGoodsTypeID: String?,
        haveLogic: String = "or"
    ) throws -> SupabaseHomeListingRow {
        try decode(
            SupabaseHomeListingRow.self,
            [
                "id": id,
                "userId": userID,
                "haveIds": haveIDs,
                "haveQtys": haveIDs.map { _ in 1 },
                "haveLogic": haveLogic,
                "haveGroupId": haveGroupID,
                "haveGoodsTypeId": haveGoodsTypeID,
                "status": "active",
                "note": nil,
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
        cashAmount: Int? = nil
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
}
