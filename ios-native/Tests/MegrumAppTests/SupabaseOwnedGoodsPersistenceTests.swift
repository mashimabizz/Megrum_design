@testable import MegrumApp
import MegrumCore
import XCTest

final class SupabaseOwnedGoodsPersistenceTests: XCTestCase {
    private let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000951")!

    func testOwnGoodsQueryItemsFilterViewerKindAndActiveRows() {
        let items = SupabaseOwnedGoodsPersistence.ownGoodsQueryItems(
            userID: userID,
            kind: "for_trade"
        )

        XCTAssertEqual(items.map(\.name), ["user_id", "kind", "status"])
        XCTAssertEqual(
            items.map(\.value),
            ["eq.00000000-0000-0000-0000-000000000951", "eq.for_trade", "neq.archived"]
        )
    }

    func testGoodsItemsMapRowsThroughGoodsItemProjection() {
        let row = makeRow(
            kind: "for_trade",
            status: "active",
            title: "ミナ トレカ",
            quantity: 2,
            lockedQty: 1,
            marketAvailableQty: 1
        )

        let items = SupabaseOwnedGoodsPersistence.goodsItems(from: [row])

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].id, row.id)
        XCTAssertEqual(items[0].ownerID, row.userId)
        XCTAssertEqual(items[0].kind, .inventory)
        XCTAssertEqual(items[0].status, .active)
        XCTAssertEqual(items[0].title, "ミナ トレカ")
        XCTAssertEqual(items[0].quantity, 2)
        XCTAssertEqual(items[0].lockedQuantity, 1)
        XCTAssertEqual(items[0].marketAvailableQuantity, 1)
    }

    func testGoodsItemsApplyLoadedTags() {
        let row = makeRow(
            kind: "for_trade",
            status: "active",
            title: "ミナ トレカ"
        )
        let tag = GoodsTag(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000956")!,
            name: "会場限定"
        )

        let items = SupabaseOwnedGoodsPersistence.goodsItems(from: [row], tagMap: [row.id: [tag]])

        XCTAssertEqual(items[0].tags, [tag])
    }

    func testGoodsItemsResolveRawPhotoPathWithProjectURL() throws {
        let row = makeRow(
            kind: "for_trade",
            status: "active",
            title: "ミナ トレカ",
            photoUrls: ["00000000-0000-0000-0000-000000000951/photo.jpg"]
        )
        let projectURL = try XCTUnwrap(URL(string: "https://example.supabase.co"))

        let items = SupabaseOwnedGoodsPersistence.goodsItems(from: [row], tagMap: [:], projectURL: projectURL)

        XCTAssertEqual(
            items.first?.imageURL?.absoluteString,
            "https://example.supabase.co/storage/v1/object/public/goods-photos/00000000-0000-0000-0000-000000000951/photo.jpg"
        )
    }

    func testWishItemsMapRowsThroughWishItemProjection() {
        let row = makeRow(
            kind: "wanted",
            status: "active",
            title: "サナ ペンライト",
            quantity: 3
        )

        let wishes = SupabaseOwnedGoodsPersistence.wishItems(from: [row])

        XCTAssertEqual(wishes.count, 1)
        XCTAssertEqual(wishes[0].id, row.id)
        XCTAssertEqual(wishes[0].ownerID, row.userId)
        XCTAssertEqual(wishes[0].title, "サナ ペンライト")
        XCTAssertEqual(wishes[0].quantity, 3)
    }

    func testWishItemsApplyLoadedTags() {
        let row = makeRow(
            kind: "wanted",
            status: "active",
            title: "サナ ペンライト"
        )
        let tag = GoodsTag(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000957")!,
            name: "缶バッジ"
        )

        let wishes = SupabaseOwnedGoodsPersistence.wishItems(from: [row], tagMap: [row.id: [tag]])

        XCTAssertEqual(wishes[0].tags, [tag])
    }

    func testWishItemsResolveRawPhotoPathWithProjectURL() throws {
        let row = makeRow(
            kind: "wanted",
            status: "active",
            title: "サナ ペンライト",
            photoUrls: ["00000000-0000-0000-0000-000000000951/wish.jpg"]
        )
        let projectURL = try XCTUnwrap(URL(string: "https://example.supabase.co"))

        let wishes = SupabaseOwnedGoodsPersistence.wishItems(from: [row], tagMap: [:], projectURL: projectURL)

        XCTAssertEqual(
            wishes.first?.imageURL?.absoluteString,
            "https://example.supabase.co/storage/v1/object/public/goods-photos/00000000-0000-0000-0000-000000000951/wish.jpg"
        )
    }

    func testGoodsTagQueryItemsSortInventoryIDsAndKeepCreatedOrder() {
        let items = SupabaseOwnedGoodsPersistence.goodsTagQueryItems(inventoryIDs: [
            UUID(uuidString: "00000000-0000-0000-0000-000000000959")!,
            UUID(uuidString: "00000000-0000-0000-0000-000000000958")!
        ])

        XCTAssertEqual(items.map(\.name), ["inventory_id", "order"])
        XCTAssertEqual(
            items.map(\.value),
            [
                "in.(00000000-0000-0000-0000-000000000958,00000000-0000-0000-0000-000000000959)",
                "created_at.asc"
            ]
        )
    }

    func testGoodsTagMapPreservesRowsByInventory() {
        let inventoryID = UUID(uuidString: "00000000-0000-0000-0000-000000000952")!
        let tagID = UUID(uuidString: "00000000-0000-0000-0000-000000000956")!
        let rows = [
            OwnedGoodsInventoryTagRow(
                inventoryId: inventoryID,
                tag: OwnedGoodsTagRow(id: tagID, label: "会場限定")
            )
        ]

        let tagMap = SupabaseOwnedGoodsPersistence.goodsTagMap(from: rows)

        XCTAssertEqual(tagMap[inventoryID], [GoodsTag(id: tagID, name: "会場限定")])
    }

    private func makeRow(
        kind: String?,
        status: String?,
        title: String,
        id: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000952")!,
        photoUrls: [String]? = nil,
        quantity: Int? = nil,
        lockedQty: Int? = nil,
        marketAvailableQty: Int? = nil
    ) -> GoodsInventoryRow {
        GoodsInventoryRow(
            id: id,
            userId: userID,
            kind: kind,
            status: status,
            groupId: UUID(uuidString: "00000000-0000-0000-0000-000000000953")!,
            characterId: UUID(uuidString: "00000000-0000-0000-0000-000000000954")!,
            goodsTypeId: UUID(uuidString: "00000000-0000-0000-0000-000000000955")!,
            title: title,
            photoUrls: photoUrls,
            quantity: quantity,
            lockedQty: lockedQty,
            marketAvailableQty: marketAvailableQty
        )
    }
}
