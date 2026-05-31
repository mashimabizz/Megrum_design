import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseGoodsInventoryClientTests: XCTestCase {
    func testBuildsGoodsTypesRequest() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)

        let request = try client.makeLoadGoodsTypesRequest(limit: 30)

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/goods_types_master?select=id,name,category,display_order&order=display_order.asc,name.asc&limit=30")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "sb_publishable_test")
    }

    func testBuildsCreateInventoryRequest() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let input = GoodsEntryInput(
            kind: .inventory,
            title: "ランダムトレカ A",
            groupID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            goodsTypeID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            quantity: 2
        )

        let request = try client.makeCreateGoodsEntryRequest(userID: userID, input: input)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/goods_inventory?select=id,user_id,group_id,character_id,goods_type_id,title,photo_urls,quantity")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "resolution=merge-duplicates,return=representation")
        XCTAssertEqual(json.first?["user_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(json.first?["kind"] as? String, "for_trade")
        XCTAssertEqual(json.first?["group_id"] as? String, "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(json.first?["goods_type_id"] as? String, "33333333-3333-3333-3333-333333333333")
        XCTAssertEqual(json.first?["title"] as? String, "ランダムトレカ A")
        XCTAssertEqual(json.first?["condition"] as? String, "good")
        XCTAssertEqual(json.first?["exchange_type"] as? String, "any")
        XCTAssertEqual(json.first?["quantity"] as? Int, 2)
        XCTAssertEqual(json.first?["photo_urls"] as? [String], [])
    }

    func testBuildsCreateWishRequest() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let input = GoodsEntryInput(
            kind: .wish,
            title: "会場限定フォト",
            groupID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            goodsTypeID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        )

        let request = try client.makeCreateGoodsEntryRequest(userID: userID, input: input)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(json.first?["kind"] as? String, "wanted")
        XCTAssertNil(json.first?["condition"])
        XCTAssertEqual(json.first?["priority"] as? String, "second")
        XCTAssertEqual(json.first?["flex_level"] as? String, "normal")
        XCTAssertEqual(json.first?["exchange_type"] as? String, "any")
    }

    func testBuildsCreateInventoryRequestWithPhotoURLs() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let input = GoodsEntryInput(
            kind: .inventory,
            title: "ランダムトレカ A",
            groupID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            goodsTypeID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        )

        let request = try client.makeCreateGoodsEntryRequest(
            userID: userID,
            input: input,
            photoURLs: [
                " https://cdn.example.com/goods/a.jpg ",
                "",
                "https://cdn.example.com/goods/b.jpg"
            ]
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(
            json.first?["photo_urls"] as? [String],
            [
                "https://cdn.example.com/goods/a.jpg",
                "https://cdn.example.com/goods/b.jpg"
            ]
        )
    }

    func testBuildsSearchGoodsRequest() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let viewerID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let input = GoodsSearchInput(
            query: "トレカ",
            groupID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            memberID: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            goodsTypeID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            limit: 25
        )

        let request = try client.makeSearchGoodsRequest(viewerID: viewerID, input: input)
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/goods_inventory?select=id,user_id,group_id,character_id,goods_type_id,title,photo_urls,quantity"))
        XCTAssertTrue(url.contains("kind=eq.for_trade"))
        XCTAssertTrue(url.contains("status=in.(active,reserved)"))
        XCTAssertTrue(url.contains("user_id=neq.11111111-1111-1111-1111-111111111111"))
        XCTAssertTrue(url.contains("order=updated_at.desc"))
        XCTAssertTrue(url.contains("limit=25"))
        XCTAssertTrue(url.contains("title=ilike.*%E3%83%88%E3%83%AC%E3%82%AB*"))
        XCTAssertTrue(url.contains("group_id=eq.22222222-2222-2222-2222-222222222222"))
        XCTAssertTrue(url.contains("character_id=eq.44444444-4444-4444-4444-444444444444"))
        XCTAssertTrue(url.contains("goods_type_id=eq.33333333-3333-3333-3333-333333333333"))
    }

    func testBuildsLoadPublicTradeGoodsRequest() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeLoadPublicTradeGoodsRequest(userID: userID, limit: 24)
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/goods_inventory?select=id,user_id,group_id,character_id,goods_type_id,title,photo_urls,quantity"))
        XCTAssertTrue(url.contains("kind=eq.for_trade"))
        XCTAssertTrue(url.contains("status=in.(active,reserved)"))
        XCTAssertTrue(url.contains("user_id=eq.22222222-2222-2222-2222-222222222222"))
        XCTAssertTrue(url.contains("order=updated_at.desc"))
        XCTAssertTrue(url.contains("limit=24"))
    }

    func testBuildsArchiveGoodsItemRequest() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let itemID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

        let request = try client.makeArchiveGoodsItemRequest(userID: userID, itemID: itemID)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertEqual(
            request.url?.absoluteString,
            "https://example.supabase.co/rest/v1/goods_inventory?select=id,user_id,group_id,character_id,goods_type_id,title,photo_urls,quantity&id=eq.44444444-4444-4444-4444-444444444444&user_id=eq.11111111-1111-1111-1111-111111111111&status=neq.traded"
        )
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertEqual(json["status"] as? String, "archived")
    }

    func testBuildsUpdateGoodsItemRequest() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let itemID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let input = GoodsInventoryUpdateInput(
            title: "  ラントレ B  ",
            groupID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            characterID: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            goodsTypeID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            quantity: 3,
            status: .keep,
            photoURLs: [
                " https://cdn.example.com/goods/a.jpg ",
                "\n",
                "https://cdn.example.com/goods/b.jpg"
            ]
        )

        let request = try client.makeUpdateGoodsItemRequest(userID: userID, itemID: itemID, input: input)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertEqual(
            request.url?.absoluteString,
            "https://example.supabase.co/rest/v1/goods_inventory?select=id,user_id,group_id,character_id,goods_type_id,title,photo_urls,quantity&id=eq.44444444-4444-4444-4444-444444444444&user_id=eq.11111111-1111-1111-1111-111111111111&status=neq.traded"
        )
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertEqual(json["title"] as? String, "ラントレ B")
        XCTAssertEqual(json["group_id"] as? String, "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(json["character_id"] as? String, "55555555-5555-5555-5555-555555555555")
        XCTAssertEqual(json["goods_type_id"] as? String, "33333333-3333-3333-3333-333333333333")
        XCTAssertEqual(json["quantity"] as? Int, 3)
        XCTAssertEqual(json["status"] as? String, "keep")
        XCTAssertEqual(
            json["photo_urls"] as? [String],
            [
                "https://cdn.example.com/goods/a.jpg",
                "https://cdn.example.com/goods/b.jpg"
            ]
        )
    }

    func testUpdateGoodsItemRequestCanClearCharacterID() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let itemID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let input = GoodsInventoryUpdateInput(clearsCharacterID: true)

        let request = try client.makeUpdateGoodsItemRequest(userID: userID, itemID: itemID, input: input)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertTrue(json["character_id"] is NSNull)
    }

    func testBuildsDeleteGoodsItemRequest() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let itemID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

        let request = try client.makeDeleteGoodsItemRequest(userID: userID, itemID: itemID)

        XCTAssertEqual(request.httpMethod, "DELETE")
        XCTAssertEqual(
            request.url?.absoluteString,
            "https://example.supabase.co/rest/v1/goods_inventory?id=eq.44444444-4444-4444-4444-444444444444&user_id=eq.11111111-1111-1111-1111-111111111111&status=neq.traded"
        )
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=minimal")
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
