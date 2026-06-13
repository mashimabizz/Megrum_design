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
                    primaryArea: "福岡県"
                )
            ],
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
                    id: "10000000-0000-0000-0000-000000000025",
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
        let partnerID = try XCTUnwrap(UUID(uuidString: partnerHaveID))
        let signals = try XCTUnwrap(sections.conditionSignalsByItemID[partnerID])

        XCTAssertEqual(sections.matchedItems.map(\.id), [partnerID])
        XCTAssertEqual(signals.goods, HomeGoodsConditionSignals(hasIndividualListingHit: true, hasWishHit: false))
        XCTAssertEqual(signals.linkCounts, HomeCandidateLinkCounts(wishCount: 0, listingCount: 1))
        XCTAssertEqual(HomeDiscoveryMatchPolicy.goodsCondition(for: signals.goods), .direct)
        XCTAssertEqual(HomeDiscoveryMatchPolicy.exchangeCondition(for: signals.exchange), .possible)
        XCTAssertEqual(sections.matchedItems.first?.exchangeMethod, .hand)
        XCTAssertEqual(sections.matchedItems.first?.ownerPrefecture, "福岡県")
        XCTAssertEqual(
            sections.conditionSignalsByItemID[UUID(uuidString: viewerHaveID)!]?.linkCounts,
            HomeCandidateLinkCounts(wishCount: 0, listingCount: 1)
        )
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

    private func goodsRow(
        id: String,
        userID: String,
        groupID: String?,
        goodsTypeID: String?,
        title: String,
        photoURLs: [String] = [],
        quantity: Int = 1,
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
            "exchangeType": exchangeType,
            "hue": nil,
            "status": "active"
        ]
        return try decode(SupabaseHomeGoodsRow.self, payload)
    }

    private func userRow(id: String, handle: String, primaryArea: String) throws -> SupabaseHomeUserRow {
        try decode(
            SupabaseHomeUserRow.self,
            [
                "id": id,
                "handle": handle,
                "displayName": handle,
                "primaryArea": primaryArea,
                "avatarUrl": nil
            ]
        )
    }

    private func listingRow(
        id: String,
        userID: String,
        haveIDs: [String],
        haveGroupID: String?,
        haveGoodsTypeID: String?
    ) throws -> SupabaseHomeListingRow {
        try decode(
            SupabaseHomeListingRow.self,
            [
                "id": id,
                "userId": userID,
                "haveIds": haveIDs,
                "haveQtys": haveIDs.map { _ in 1 },
                "haveLogic": "or",
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
        wishIDs: [String],
        wishGroupID: String?,
        wishGoodsTypeID: String?
    ) throws -> SupabaseHomeListingWishOptionRow {
        try decode(
            SupabaseHomeListingWishOptionRow.self,
            [
                "id": id,
                "listingId": listingID,
                "position": 1,
                "wishIds": wishIDs,
                "wishQtys": wishIDs.map { _ in 1 },
                "logic": "or",
                "exchangeType": "any",
                "isCashOffer": false,
                "cashAmount": nil,
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
