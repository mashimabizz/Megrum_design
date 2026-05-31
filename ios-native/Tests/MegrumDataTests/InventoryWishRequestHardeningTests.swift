import Foundation
import MegrumCore
import MegrumData
import XCTest

final class InventoryWishRequestHardeningTests: XCTestCase {
    func testGoodsTypeLimitIsClampedForFilterLoading() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)

        let lowRequest = try client.makeLoadGoodsTypesRequest(limit: 0)
        let highRequest = try client.makeLoadGoodsTypesRequest(limit: 999)

        XCTAssertTrue(try XCTUnwrap(lowRequest.url?.absoluteString).contains("limit=1"))
        XCTAssertTrue(try XCTUnwrap(highRequest.url?.absoluteString).contains("limit=100"))
    }

    func testCreateWishRequestTrimsTitleAndClampsQuantity() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let input = GoodsEntryInput(
            kind: .wish,
            title: "  会場限定フォト  ",
            groupID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            goodsTypeID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            quantity: 0
        )

        let request = try client.makeCreateGoodsEntryRequest(userID: userID, input: input)
        let body = try XCTUnwrap(request.httpBody)
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let payload = try XCTUnwrap(rows.first)

        XCTAssertEqual(payload["kind"] as? String, "wanted")
        XCTAssertEqual(payload["title"] as? String, "会場限定フォト")
        XCTAssertEqual(payload["quantity"] as? Int, 1)
    }

    func testCreateGoodsEntryRequestRejectsBlankTitle() {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let input = GoodsEntryInput(
            kind: .inventory,
            title: "  \n",
            groupID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            goodsTypeID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        )

        XCTAssertThrowsError(try client.makeCreateGoodsEntryRequest(userID: userID, input: input)) { error in
            XCTAssertEqual(error as? SupabaseGoodsInventoryClientError, .emptyTitle)
        }
    }

    func testUpdateGoodsItemRequestRejectsBlankTitle() {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let itemID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

        XCTAssertThrowsError(
            try client.makeUpdateGoodsItemRequest(
                userID: userID,
                itemID: itemID,
                input: GoodsInventoryUpdateInput(title: "  \n")
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseGoodsInventoryClientError, .emptyTitle)
        }
    }

    func testUpdateGoodsItemRequestRejectsInvalidQuantity() {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let itemID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

        for quantity in [0, 1_000] {
            XCTAssertThrowsError(
                try client.makeUpdateGoodsItemRequest(
                    userID: userID,
                    itemID: itemID,
                    input: GoodsInventoryUpdateInput(quantity: quantity)
                )
            ) { error in
                XCTAssertEqual(error as? SupabaseGoodsInventoryClientError, .invalidQuantity)
            }
        }
    }

    func testUpdateGoodsItemRequestRejectsEmptyPatch() {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let itemID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

        XCTAssertThrowsError(
            try client.makeUpdateGoodsItemRequest(
                userID: userID,
                itemID: itemID,
                input: GoodsInventoryUpdateInput()
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseGoodsInventoryClientError, .emptyUpdate)
        }
    }

    func testUpdateGoodsItemRequestDoesNotWriteTagsBecauseTagsUseJoinTable() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let itemID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

        let request = try client.makeUpdateGoodsItemRequest(
            userID: userID,
            itemID: itemID,
            input: GoodsInventoryUpdateInput(title: "ランダムトレカ")
        )
        let body = try XCTUnwrap(request.httpBody)
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertNil(payload["tags"])
        XCTAssertNil(payload["tag_names"])
        XCTAssertNil(payload["goods_inventory_tags"])
    }

    func testBlankGoodsReportNoteIsOmitted() throws {
        let client = SupabaseGoodsReportClient(configuration: configuration)
        let input = GoodsReportCreateInput(
            goodsItemID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            reportedUserID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            reason: .fakeItem,
            note: "   \n"
        )

        let request = try client.makeCreateReportRequest(
            reporterID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            input: input
        )
        let body = try XCTUnwrap(request.httpBody)
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let payload = try XCTUnwrap(rows.first)

        XCTAssertNil(payload["note"])
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
