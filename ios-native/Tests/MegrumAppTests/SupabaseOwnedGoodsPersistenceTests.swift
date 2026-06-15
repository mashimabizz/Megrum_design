@testable import MegrumApp
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

    private func makeRow(
        kind: String?,
        status: String?,
        title: String,
        quantity: Int? = nil,
        lockedQty: Int? = nil,
        marketAvailableQty: Int? = nil
    ) -> GoodsInventoryRow {
        GoodsInventoryRow(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000952")!,
            userId: userID,
            kind: kind,
            status: status,
            groupId: UUID(uuidString: "00000000-0000-0000-0000-000000000953")!,
            characterId: UUID(uuidString: "00000000-0000-0000-0000-000000000954")!,
            goodsTypeId: UUID(uuidString: "00000000-0000-0000-0000-000000000955")!,
            title: title,
            photoUrls: nil,
            quantity: quantity,
            lockedQty: lockedQty,
            marketAvailableQty: marketAvailableQty
        )
    }
}
