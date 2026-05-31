@testable import MegrumApp
import MegrumData
import XCTest

final class HomeCandidateComposerTests: XCTestCase {
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
        XCTAssertTrue(sections.possibleItems.isEmpty)
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
    }

    private func goodsRow(
        id: String,
        userID: String,
        groupID: String?,
        goodsTypeID: String?,
        title: String,
        photoURLs: [String] = [],
        quantity: Int = 1
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
            "exchangeType": nil,
            "hue": nil,
            "status": "active"
        ]
        return try decode(SupabaseHomeGoodsRow.self, payload)
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
