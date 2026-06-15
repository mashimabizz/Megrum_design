@testable import MegrumApp
import MegrumCore
import XCTest

final class SupabaseGoodsInventoryRowModelsTests: XCTestCase {
    func testGoodsItemClampsQuantitiesAndUsesFirstValidPhotoURL() {
        let row = makeRow(
            kind: "for_trade",
            status: "active",
            photoUrls: ["https://example.com/first.jpg", "https://example.com/second.jpg"],
            quantity: 0,
            lockedQty: -2,
            marketAvailableQty: -3
        )

        let item = row.goodsItem

        XCTAssertEqual(item.kind, .inventory)
        XCTAssertEqual(item.status, .active)
        XCTAssertEqual(item.imageURL, URL(string: "https://example.com/first.jpg"))
        XCTAssertEqual(item.quantity, 1)
        XCTAssertEqual(item.lockedQuantity, 0)
        XCTAssertEqual(item.marketAvailableQuantity, 0)
        XCTAssertEqual(item.tags, [])
    }

    func testWishItemKeepsExistingQuantityFallbackBehavior() {
        let row = makeRow(kind: "wanted", quantity: 0)

        let wish = row.wishItem

        XCTAssertEqual(wish.quantity, 0)
        XCTAssertEqual(wish.tags, [])
    }

    private func makeRow(
        kind: String?,
        status: String? = nil,
        photoUrls: [String]? = nil,
        quantity: Int? = nil,
        lockedQty: Int? = nil,
        marketAvailableQty: Int? = nil
    ) -> GoodsInventoryRow {
        GoodsInventoryRow(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000701")!,
            userId: UUID(uuidString: "00000000-0000-0000-0000-000000000702")!,
            kind: kind,
            status: status,
            groupId: UUID(uuidString: "00000000-0000-0000-0000-000000000703")!,
            characterId: UUID(uuidString: "00000000-0000-0000-0000-000000000704")!,
            goodsTypeId: UUID(uuidString: "00000000-0000-0000-0000-000000000705")!,
            title: "ミナ トレカ",
            photoUrls: photoUrls,
            quantity: quantity,
            lockedQty: lockedQty,
            marketAvailableQty: marketAvailableQty
        )
    }
}
