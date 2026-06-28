import Foundation
import MegrumData
import XCTest

final class SupabaseHomeClientTests: XCTestCase {
    func testBuildsViewerInventoryAndWishRequestsForHomeComposition() throws {
        let client = SupabaseHomeClient(configuration: configuration)
        let userID = uuid("11111111-1111-1111-1111-111111111111")

        let tradeRequest = try client.makeLoadViewerTradeGoodsRequest(userID: userID)
        let tradeQuery = try queryItems(in: tradeRequest)
        let tradeSelect = try XCTUnwrap(tradeQuery["select"])

        XCTAssertEqual(tradeRequest.httpMethod, "GET")
        XCTAssertEqual(tradeRequest.url?.path, "/rest/v1/goods_inventory")
        XCTAssertEqual(tradeRequest.value(forHTTPHeaderField: "apikey"), "sb_publishable_test")
        XCTAssertEqual(tradeRequest.value(forHTTPHeaderField: "Authorization"), "Bearer sb_publishable_test")
        XCTAssertNil(tradeRequest.httpBody)
        XCTAssertEqual(tradeQuery["user_id"], "eq.11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(tradeQuery["kind"], "eq.for_trade")
        XCTAssertEqual(tradeQuery["status"], "eq.active")
        XCTAssertNil(tradeQuery["limit"])
        XCTAssertTrue(tradeSelect.contains("group:groups_master(name)"))
        XCTAssertTrue(tradeSelect.contains("character:characters_master(name)"))
        XCTAssertTrue(tradeSelect.contains("goods_type:goods_types_master(name)"))
        XCTAssertTrue(tradeSelect.contains("character_request_id"))
        XCTAssertTrue(tradeSelect.contains("exchange_type"))
        XCTAssertTrue(tradeSelect.contains("hue"))
        XCTAssertTrue(tradeSelect.contains("locked_qty"))
        XCTAssertTrue(tradeSelect.contains("market_available_qty"))

        let wishRequest = try client.makeLoadViewerWishesRequest(userID: userID)
        let wishQuery = try queryItems(in: wishRequest)

        XCTAssertEqual(wishRequest.httpMethod, "GET")
        XCTAssertEqual(wishRequest.url?.path, "/rest/v1/goods_inventory")
        XCTAssertEqual(wishQuery["user_id"], "eq.11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(wishQuery["kind"], "eq.wanted")
        XCTAssertEqual(wishQuery["status"], "neq.archived")
        XCTAssertNil(wishQuery["limit"])
        XCTAssertNil(wishRequest.httpBody)
    }

    func testBuildsPartnerGoodsAndUserRequestsWithBoundedLimits() throws {
        let client = SupabaseHomeClient(configuration: configuration)
        let userID = uuid("11111111-1111-1111-1111-111111111111")

        let tradeRequest = try client.makeLoadPartnerTradeGoodsRequest(excludingUserID: userID, limit: 900)
        let tradeQuery = try queryItems(in: tradeRequest)

        XCTAssertEqual(tradeRequest.url?.path, "/rest/v1/goods_inventory")
        XCTAssertEqual(tradeQuery["user_id"], "neq.11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(tradeQuery["kind"], "eq.for_trade")
        XCTAssertEqual(tradeQuery["status"], "eq.active")
        XCTAssertEqual(tradeQuery["limit"], "500")

        let wishRequest = try client.makeLoadPartnerWishesRequest(excludingUserID: userID, limit: 0)
        let wishQuery = try queryItems(in: wishRequest)

        XCTAssertEqual(wishQuery["user_id"], "neq.11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(wishQuery["kind"], "eq.wanted")
        XCTAssertEqual(wishQuery["status"], "neq.archived")
        XCTAssertEqual(wishQuery["limit"], "1")

        let usersRequest = try client.makeLoadPartnerUsersRequest(excludingUserID: userID, limit: 42)
        let usersQuery = try queryItems(in: usersRequest)

        XCTAssertEqual(usersRequest.url?.path, "/rest/v1/users")
        XCTAssertEqual(usersQuery["select"], "id,handle,display_name,primary_area,avatar_url,gender,age,payment_methods,payment_note,is_test_account")
        XCTAssertEqual(usersQuery["id"], "neq.11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(usersQuery["limit"], "42")
        XCTAssertNil(usersRequest.httpBody)

        let userSummariesRequest = try client.makeLoadPartnerUserSummariesRequest(excludingUserID: userID, limit: 42)
        let userSummariesBody = try XCTUnwrap(userSummariesRequest.httpBody)
        let userSummariesPayload = try JSONSerialization.jsonObject(with: userSummariesBody) as? [String: Any]

        XCTAssertEqual(userSummariesRequest.httpMethod, "POST")
        XCTAssertEqual(userSummariesRequest.url?.path, "/rest/v1/rpc/list_home_user_summaries_for_viewer")
        XCTAssertEqual(userSummariesPayload?["p_excluded_user_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(userSummariesPayload?["p_limit"] as? Int, 42)
    }

    func testBuildsListingsAndListingWishOptionsRequests() throws {
        let client = SupabaseHomeClient(configuration: configuration)
        let userID = uuid("11111111-1111-1111-1111-111111111111")
        let firstListingID = uuid("22222222-2222-2222-2222-222222222222")
        let secondListingID = uuid("33333333-3333-3333-3333-333333333333")

        let viewerListingsRequest = try client.makeLoadViewerListingsRequest(userID: userID)
        let viewerListingsQuery = try queryItems(in: viewerListingsRequest)
        let viewerListingSelect = try XCTUnwrap(viewerListingsQuery["select"])

        XCTAssertEqual(viewerListingsRequest.url?.path, "/rest/v1/listings")
        XCTAssertEqual(viewerListingsQuery["user_id"], "eq.11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(viewerListingsQuery["status"], "eq.active")
        XCTAssertNil(viewerListingsQuery["limit"])
        XCTAssertTrue(viewerListingSelect.contains("have_ids"))
        XCTAssertTrue(viewerListingSelect.contains("have_logic"))
        XCTAssertTrue(viewerListingSelect.contains("have_min_count"))
        XCTAssertTrue(viewerListingSelect.contains("have_group_id"))
        XCTAssertTrue(viewerListingSelect.contains("have_goods_type_id"))

        let partnerListingsRequest = try client.makeLoadPartnerListingsRequest(excludingUserID: userID, limit: 24)
        let partnerListingsQuery = try queryItems(in: partnerListingsRequest)

        XCTAssertEqual(partnerListingsQuery["user_id"], "neq.11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(partnerListingsQuery["status"], "eq.active")
        XCTAssertEqual(partnerListingsQuery["limit"], "24")

        let optionsRequest = try client.makeLoadListingWishOptionsRequest(
            listingIDs: [firstListingID, secondListingID, firstListingID]
        )
        let optionsQuery = try queryItems(in: optionsRequest)
        let optionsSelect = try XCTUnwrap(optionsQuery["select"])

        XCTAssertEqual(optionsRequest.url?.path, "/rest/v1/listing_wish_options")
        XCTAssertEqual(
            optionsQuery["listing_id"],
            "in.(22222222-2222-2222-2222-222222222222,33333333-3333-3333-3333-333333333333)"
        )
        XCTAssertEqual(optionsQuery["order"], "position.asc")
        XCTAssertTrue(optionsSelect.contains("wish_ids"))
        XCTAssertTrue(optionsSelect.contains("min_count"))
        XCTAssertTrue(optionsSelect.contains("is_cash_offer"))
        XCTAssertTrue(optionsSelect.contains("cash_amount"))
        XCTAssertNil(optionsRequest.httpBody)

        XCTAssertThrowsError(try client.makeLoadListingWishOptionsRequest(listingIDs: [])) { error in
            XCTAssertEqual(error as? SupabaseHomeClientError, .emptyIdentifierList)
        }
    }

    func testBuildsLocalModeActivityWindowAndUnreadNotificationRequests() throws {
        let client = SupabaseHomeClient(configuration: configuration)
        let userID = uuid("11111111-1111-1111-1111-111111111111")

        let localModeRequest = try client.makeLoadLocalModeRequest(userID: userID)
        let localModeQuery = try queryItems(in: localModeRequest)
        let localModeSelect = try XCTUnwrap(localModeQuery["select"])

        XCTAssertEqual(localModeRequest.url?.path, "/rest/v1/user_local_mode_settings")
        XCTAssertEqual(localModeQuery["user_id"], "eq.11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(localModeQuery["limit"], "1")
        XCTAssertTrue(localModeSelect.contains("enabled"))
        XCTAssertTrue(localModeSelect.contains("aw_id"))
        XCTAssertTrue(localModeSelect.contains("selected_carrying_ids"))
        XCTAssertTrue(localModeSelect.contains("last_lat"))
        XCTAssertNil(localModeRequest.httpBody)

        let viewerAWRequest = try client.makeLoadViewerActivityWindowsRequest(userID: userID)
        let viewerAWQuery = try queryItems(in: viewerAWRequest)
        let awSelect = try XCTUnwrap(viewerAWQuery["select"])

        XCTAssertEqual(viewerAWRequest.url?.path, "/rest/v1/activity_windows")
        XCTAssertEqual(viewerAWQuery["user_id"], "eq.11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(viewerAWQuery["status"], "eq.enabled")
        XCTAssertNil(viewerAWQuery["limit"])
        XCTAssertTrue(awSelect.contains("start_at"))
        XCTAssertTrue(awSelect.contains("end_at"))
        XCTAssertTrue(awSelect.contains("center_lat"))
        XCTAssertTrue(awSelect.contains("center_lng"))

        let partnerAWRequest = try client.makeLoadPartnerActivityWindowsRequest(excludingUserID: userID, limit: 999)
        let partnerAWQuery = try queryItems(in: partnerAWRequest)

        XCTAssertEqual(partnerAWQuery["user_id"], "neq.11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(partnerAWQuery["status"], "eq.enabled")
        XCTAssertEqual(partnerAWQuery["limit"], "500")

        let notificationsRequest = try client.makeLoadUnreadNotificationsRequest(userID: userID, limit: 5_000)
        let notificationsQuery = try queryItems(in: notificationsRequest)

        XCTAssertEqual(notificationsRequest.url?.path, "/rest/v1/notifications")
        XCTAssertEqual(notificationsQuery["select"], "id")
        XCTAssertEqual(notificationsQuery["user_id"], "eq.11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(notificationsQuery["read_at"], "is.null")
        XCTAssertEqual(notificationsQuery["limit"], "1000")
        XCTAssertNil(notificationsRequest.httpBody)
    }

    func testBuildsInventoryTagsRequestForCandidateTagScores() throws {
        let client = SupabaseHomeClient(configuration: configuration)
        let firstInventoryID = uuid("22222222-2222-2222-2222-222222222222")
        let secondInventoryID = uuid("33333333-3333-3333-3333-333333333333")

        let request = try client.makeLoadInventoryTagsRequest(
            inventoryIDs: [firstInventoryID, firstInventoryID, secondInventoryID]
        )
        let query = try queryItems(in: request)

        XCTAssertEqual(request.url?.path, "/rest/v1/goods_inventory_tags")
        XCTAssertEqual(query["select"], "inventory_id,tag_id,tag:tags_master(label)")
        XCTAssertEqual(
            query["inventory_id"],
            "in.(22222222-2222-2222-2222-222222222222,33333333-3333-3333-3333-333333333333)"
        )
        XCTAssertNil(request.httpBody)

        XCTAssertThrowsError(try client.makeLoadInventoryTagsRequest(inventoryIDs: [])) { error in
            XCTAssertEqual(error as? SupabaseHomeClientError, .emptyIdentifierList)
        }
    }

    func testBuildsMegrumPlusUserIDsRequestForRanking() throws {
        let client = SupabaseHomeClient(configuration: configuration)
        let firstUserID = uuid("22222222-2222-2222-2222-222222222222")
        let secondUserID = uuid("33333333-3333-3333-3333-333333333333")

        let request = try client.makeLoadMegrumPlusUserIDsRequest(userIDs: [firstUserID, secondUserID])
        let body = try XCTUnwrap(request.httpBody)
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let userIDs = try XCTUnwrap(payload["p_user_ids"] as? [String])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.path, "/rest/v1/rpc/list_megrum_plus_user_ids_for_viewer")
        XCTAssertEqual(
            userIDs,
            [
                "22222222-2222-2222-2222-222222222222",
                "33333333-3333-3333-3333-333333333333"
            ]
        )
    }

    func testDecodesMegrumPlusUserIDRowFromSupabaseSnakeCase() throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let rows = try decoder.decode([SupabaseMegrumPlusUserIDRow].self, from: Data("""
        [
          {
            "user_id": "22222222-2222-2222-2222-222222222222"
          }
        ]
        """.utf8))

        XCTAssertEqual(rows.first?.userID, uuid("22222222-2222-2222-2222-222222222222"))
        XCTAssertEqual(rows.first?.id, uuid("22222222-2222-2222-2222-222222222222"))
    }

    func testDecodesHomeDTOsWithEmbeddedRelationsAndFlexibleNumericValues() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let goods = try decoder.decode(
            SupabaseHomeGoodsRow.self,
            from: Data(
                #"""
                {
                  "id": "22222222-2222-2222-2222-222222222222",
                  "user_id": "11111111-1111-1111-1111-111111111111",
                  "kind": "for_trade",
                  "group_id": "33333333-3333-3333-3333-333333333333",
                  "character_id": "44444444-4444-4444-4444-444444444444",
                  "character_request_id": null,
                  "goods_type_id": "55555555-5555-5555-5555-555555555555",
                  "title": "スア 春ver.",
                  "photo_urls": ["https://cdn.example.com/goods/a.jpg"],
                  "quantity": 2,
                  "locked_qty": 1,
                  "market_available_qty": 1,
                  "exchange_type": "any",
                  "hue": 214,
                  "status": "active",
                  "group": { "name": "aespa" },
                  "character": [{ "name": "スア" }],
                  "goods_type": { "name": "トレカ" },
                  "updated_at": "2026-05-31T01:02:03Z"
                }
                """#.utf8
            )
        )

        XCTAssertEqual(goods.id, uuid("22222222-2222-2222-2222-222222222222"))
        XCTAssertEqual(goods.photoUrls, ["https://cdn.example.com/goods/a.jpg"])
        XCTAssertEqual(goods.quantity, 2)
        XCTAssertEqual(goods.lockedQty, 1)
        XCTAssertEqual(goods.marketAvailableQty, 1)
        XCTAssertEqual(goods.hue, "214")
        XCTAssertEqual(goods.groupName, "aespa")
        XCTAssertEqual(goods.characterName, "スア")
        XCTAssertEqual(goods.goodsTypeName, "トレカ")

        let activityWindow = try decoder.decode(
            SupabaseHomeActivityWindowRow.self,
            from: Data(
                #"""
                {
                  "id": "66666666-6666-6666-6666-666666666666",
                  "user_id": "77777777-7777-7777-7777-777777777777",
                  "venue": "東京ドーム",
                  "start_at": "2026-05-31T02:00:00Z",
                  "end_at": "2026-05-31T04:00:00Z",
                  "radius_m": 800,
                  "center_lat": "35.705640",
                  "center_lng": 139.75189,
                  "status": "enabled"
                }
                """#.utf8
            )
        )

        XCTAssertEqual(activityWindow.venue, "東京ドーム")
        XCTAssertEqual(try XCTUnwrap(activityWindow.centerLat), 35.70564, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(activityWindow.centerLng), 139.75189, accuracy: 0.000001)

        let user = try decoder.decode(
            SupabaseHomeUserRow.self,
            from: Data(
                #"""
                {
                  "id": "77777777-7777-7777-7777-777777777777",
                  "handle": "mii_trade",
                  "display_name": "みい",
                  "primary_area": "東京都",
                  "avatar_url": null,
                  "gender": "female",
                  "age": 24,
                  "payment_methods": ["bank_transfer", "cash_exchange"],
                  "payment_note": "メルペイ相談可",
                  "is_test_account": true,
                  "average_stars": 4.75,
                  "evaluation_count": 12,
                  "completed_trade_count": 20
                }
                """#.utf8
            )
        )

        XCTAssertEqual(user.age, 24)
        XCTAssertEqual(user.gender, "female")
        XCTAssertEqual(user.paymentMethods, ["bank_transfer", "cash_exchange"])
        XCTAssertEqual(user.paymentNote, "メルペイ相談可")
        XCTAssertEqual(user.isTestAccount, true)
        XCTAssertEqual(user.averageStars, 4.75)
        XCTAssertEqual(user.evaluationCount, 12)
        XCTAssertEqual(user.completedTradeCount, 20)

        let listing = try decoder.decode(
            SupabaseHomeListingRow.self,
            from: Data(
                #"""
                {
                  "id": "99999999-9999-9999-9999-999999999999",
                  "user_id": "11111111-1111-1111-1111-111111111111",
                  "have_ids": null,
                  "have_qtys": null,
                  "have_logic": null,
                  "status": "active"
                }
                """#.utf8
            )
        )

        XCTAssertEqual(listing.haveIds, [])
        XCTAssertEqual(listing.haveQtys, [])

        let tag = try decoder.decode(
            SupabaseHomeInventoryTagRow.self,
            from: Data(
                #"""
                {
                  "inventory_id": "22222222-2222-2222-2222-222222222222",
                  "tag_id": "88888888-8888-8888-8888-888888888888",
                  "tag": { "label": "会場限定" }
                }
                """#.utf8
            )
        )

        XCTAssertEqual(tag.inventoryId, uuid("22222222-2222-2222-2222-222222222222"))
        XCTAssertEqual(tag.label, "会場限定")
    }

    private func queryItems(in request: URLRequest) throws -> [String: String] {
        let url = try XCTUnwrap(request.url)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        return Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
                item.value.map { (item.name, $0) }
            }
        )
    }

    private func uuid(_ value: String) -> UUID {
        UUID(uuidString: value)!
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
