import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseGoodsInventoryClientTests: XCTestCase {
    private let goodsInventorySelect = "id,user_id,kind,status,group_id,character_id,goods_type_id,title,photo_urls,quantity,exchange_type,group:groups_master(name),character:characters_master(name),goods_type:goods_types_master(name)"

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
            memberID: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            goodsTypeID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            quantity: 2,
            status: .keep
        )

        let request = try client.makeCreateGoodsEntryRequest(userID: userID, input: input)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/goods_inventory?select=\(goodsInventorySelect)")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "resolution=merge-duplicates,return=representation")
        XCTAssertEqual(json.first?["user_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(json.first?["kind"] as? String, "for_trade")
        XCTAssertEqual(json.first?["group_id"] as? String, "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(json.first?["character_id"] as? String, "44444444-4444-4444-4444-444444444444")
        XCTAssertEqual(json.first?["goods_type_id"] as? String, "33333333-3333-3333-3333-333333333333")
        XCTAssertEqual(json.first?["title"] as? String, "ランダムトレカ A")
        XCTAssertEqual(json.first?["condition"] as? String, "good")
        XCTAssertEqual(json.first?["exchange_type"] as? String, "any")
        XCTAssertEqual(json.first?["quantity"] as? Int, 2)
        XCTAssertEqual(json.first?["status"] as? String, "keep")
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
        XCTAssertNil(json.first?["flex_level"])
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
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/goods_inventory?select=id,user_id,kind,status,group_id,character_id,goods_type_id,title,photo_urls,quantity"))
        XCTAssertTrue(url.contains("kind=eq.for_trade"))
        XCTAssertTrue(url.contains("status=in.(active,reserved)"))
        XCTAssertTrue(url.contains("market_available_qty=gt.0"))
        XCTAssertTrue(url.contains("user_id=neq.11111111-1111-1111-1111-111111111111"))
        XCTAssertTrue(url.contains("order=updated_at.desc"))
        XCTAssertTrue(url.contains("limit=25"))
        XCTAssertTrue(url.contains("title=ilike.*%E3%83%88%E3%83%AC%E3%82%AB*"))
        XCTAssertTrue(url.contains("group_id=eq.22222222-2222-2222-2222-222222222222"))
        XCTAssertTrue(url.contains("character_id=eq.44444444-4444-4444-4444-444444444444"))
        XCTAssertTrue(url.contains("goods_type_id=eq.33333333-3333-3333-3333-333333333333"))
    }

    func testBuildsLegacySearchGoodsRequestWithQuantityAvailability() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let viewerID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let input = GoodsSearchInput(
            query: "",
            goodsTypeID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            limit: 25
        )

        let request = try client.makeLegacySearchGoodsRequest(viewerID: viewerID, input: input)
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/goods_inventory?select=id,user_id,kind,status,group_id,character_id,goods_type_id,title,photo_urls,quantity,exchange_type"))
        XCTAssertTrue(url.contains("kind=eq.for_trade"))
        XCTAssertTrue(url.contains("status=in.(active,reserved)"))
        XCTAssertTrue(url.contains("quantity=gt.0"))
        XCTAssertFalse(url.contains("market_available_qty=gt.0"))
        XCTAssertTrue(url.contains("user_id=neq.11111111-1111-1111-1111-111111111111"))
        XCTAssertTrue(url.contains("goods_type_id=eq.33333333-3333-3333-3333-333333333333"))
    }

    func testBuildsLoadPublicTradeGoodsRequest() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeLoadPublicTradeGoodsRequest(userID: userID, limit: 24)
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/goods_inventory?select=id,user_id,kind,status,group_id,character_id,goods_type_id,title,photo_urls,quantity"))
        XCTAssertTrue(url.contains("kind=eq.for_trade"))
        XCTAssertTrue(url.contains("status=in.(active,reserved)"))
        XCTAssertTrue(url.contains("market_available_qty=gt.0"))
        XCTAssertTrue(url.contains("user_id=eq.22222222-2222-2222-2222-222222222222"))
        XCTAssertTrue(url.contains("order=updated_at.desc"))
        XCTAssertTrue(url.contains("limit=24"))
    }

    func testBuildsLegacyLoadPublicTradeGoodsRequestWithQuantityAvailability() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeLegacyLoadPublicTradeGoodsRequest(userID: userID, limit: 24)
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/goods_inventory?select=id,user_id,kind,status,group_id,character_id,goods_type_id,title,photo_urls,quantity,exchange_type"))
        XCTAssertTrue(url.contains("kind=eq.for_trade"))
        XCTAssertTrue(url.contains("status=in.(active,reserved)"))
        XCTAssertTrue(url.contains("quantity=gt.0"))
        XCTAssertFalse(url.contains("market_available_qty=gt.0"))
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
            "https://example.supabase.co/rest/v1/goods_inventory?select=\(goodsInventorySelect)&id=eq.44444444-4444-4444-4444-444444444444&user_id=eq.11111111-1111-1111-1111-111111111111&status=neq.traded"
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
            "https://example.supabase.co/rest/v1/goods_inventory?select=\(goodsInventorySelect)&id=eq.44444444-4444-4444-4444-444444444444&user_id=eq.11111111-1111-1111-1111-111111111111&status=neq.traded"
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

    func testBuildsGoodsPhotoUploadRequest() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let path = "\(userID.uuidString.lowercased())/sample.jpg"
        let data = Data([0xFF, 0xD8, 0xFF])

        let request = try client.makeUploadGoodsPhotoRequest(
            userID: userID,
            path: path,
            data: data,
            contentType: "image/jpeg"
        )

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://example.supabase.co/storage/v1/object/goods-photos/11111111-1111-1111-1111-111111111111/sample.jpg"
        )
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.httpBody, data)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "image/jpeg")
        XCTAssertNil(request.value(forHTTPHeaderField: "x-upsert"))
    }

    func testGoodsPhotoUploadRequestNormalizesContentTypeWhitespaceAndAlias() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let path = "\(userID.uuidString.lowercased())/sample.jpg"

        let request = try client.makeUploadGoodsPhotoRequest(
            userID: userID,
            path: path,
            data: Data([0xFF, 0xD8, 0xFF]),
            contentType: " image/jpg\n"
        )

        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "image/jpeg")
    }

    func testGoodsPhotoUploadRequestRejectsUnsupportedContentType() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        XCTAssertThrowsError(
            try client.makeUploadGoodsPhotoRequest(
                userID: userID,
                path: "\(userID.uuidString.lowercased())/sample.heic",
                data: Data([0x00]),
                contentType: "image/heic"
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseGoodsInventoryClientError, .unsupportedImageContentType)
        }
    }

    func testGoodsPhotoUploadRequestRejectsOversizedImage() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        XCTAssertThrowsError(
            try client.makeUploadGoodsPhotoRequest(
                userID: userID,
                path: "\(userID.uuidString.lowercased())/large.jpg",
                data: Data(repeating: 0x00, count: SupabaseGoodsInventoryClient.maxGoodsPhotoUploadBytes + 1),
                contentType: "image/jpeg"
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseGoodsInventoryClientError, .imageTooLarge)
        }
    }

    func testBuildsGoodsTagRPCRequests() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let itemID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let tagID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!

        let attach = try client.makeAttachGoodsTagRequest(inventoryID: itemID, rawLabel: " #会場限定 ")
        let attachBody = try XCTUnwrap(attach.httpBody)
        let attachJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: attachBody) as? [String: Any])

        XCTAssertEqual(attach.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/attach_inventory_tag")
        XCTAssertEqual(attach.httpMethod, "POST")
        XCTAssertEqual(attachJSON["p_inventory_id"] as? String, "44444444-4444-4444-4444-444444444444")
        XCTAssertEqual(attachJSON["p_raw_label"] as? String, "会場限定")

        let detach = try client.makeDetachGoodsTagRequest(inventoryID: itemID, tagID: tagID)
        let detachBody = try XCTUnwrap(detach.httpBody)
        let detachJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: detachBody) as? [String: Any])

        XCTAssertEqual(detach.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/detach_inventory_tag")
        XCTAssertEqual(detach.httpMethod, "POST")
        XCTAssertEqual(detachJSON["p_inventory_id"] as? String, "44444444-4444-4444-4444-444444444444")
        XCTAssertEqual(detachJSON["p_tag_id"] as? String, "55555555-5555-5555-5555-555555555555")
    }

    func testAttachGoodsTagRequestRejectsBlankLabel() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let itemID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

        XCTAssertThrowsError(
            try client.makeAttachGoodsTagRequest(inventoryID: itemID, rawLabel: " # \n")
        ) { error in
            XCTAssertEqual(error as? SupabaseGoodsInventoryClientError, .emptyTag)
        }
    }

    func testBuildsLoadGoodsTagsRequest() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let request = try client.makeLoadGoodsTagsRequest(inventoryIDs: [
            UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        ])
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/goods_inventory_tags?select=inventory_id,tag:tags_master(id,label)"))
        XCTAssertTrue(url.contains("inventory_id=in.(44444444-4444-4444-4444-444444444444,55555555-5555-5555-5555-555555555555)"))
        XCTAssertTrue(url.contains("order=created_at.asc"))
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

    func testUpdateGoodsItemRequestRejectsEmptyUpdate() throws {
        let client = SupabaseGoodsInventoryClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let itemID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

        XCTAssertThrowsError(
            try client.makeUpdateGoodsItemRequest(userID: userID, itemID: itemID, input: GoodsInventoryUpdateInput())
        ) { error in
            XCTAssertEqual(error as? SupabaseGoodsInventoryClientError, .emptyUpdate)
        }
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
