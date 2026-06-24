import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseListingClientTests: XCTestCase {
    func testBuildsLoadListingsRequest() throws {
        let client = SupabaseListingClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let request = try client.makeLoadListingsRequest(userID: userID)
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/listings?select=id,user_id,have_ids,have_qtys,have_logic,have_min_count,have_group_id,have_goods_type_id,status,note,created_at,updated_at"))
        XCTAssertTrue(url.contains("user_id=eq.11111111-1111-1111-1111-111111111111"))
        XCTAssertTrue(url.contains("status=in.(active,paused,matched)"))
        XCTAssertTrue(url.contains("order=updated_at.desc"))
    }

    func testBuildsLoadPublicListingsRequest() throws {
        let client = SupabaseListingClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let request = try client.makeLoadPublicListingsRequest(userID: userID)
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/listings?select=id,user_id,have_ids,have_qtys,have_logic,have_min_count,have_group_id,have_goods_type_id,status,note,created_at,updated_at"))
        XCTAssertTrue(url.contains("user_id=eq.11111111-1111-1111-1111-111111111111"))
        XCTAssertTrue(url.contains("status=eq.active"))
        XCTAssertTrue(url.contains("order=updated_at.desc"))
    }

    func testBuildsLoadListingWishOptionsRequest() throws {
        let client = SupabaseListingClient(configuration: configuration)
        let firstID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let secondID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

        let request = try client.makeLoadListingWishOptionsRequest(listingIDs: [firstID, secondID])
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/listing_wish_options?select=id,listing_id,position,wish_ids,wish_qtys,logic,min_count,exchange_type,is_cash_offer,cash_amount,wish_group_id,wish_goods_type_id,created_at,updated_at"))
        XCTAssertTrue(url.contains("listing_id=in.(22222222-2222-2222-2222-222222222222,33333333-3333-3333-3333-333333333333)"))
        XCTAssertTrue(url.contains("order=position.asc,created_at.asc"))
    }

    func testBuildsCreateListingRequest() throws {
        let client = SupabaseListingClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let input = IndividualListingCreateInput(
            haveItems: [
                ListingItemQuantity(itemID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, quantity: 2)
            ],
            haveLogic: .all,
            wishItems: [
                ListingItemQuantity(itemID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!, quantity: 1)
            ],
            wishLogic: .one,
            exchangeType: .any,
            note: "会場で交換したい"
        )

        let request = try client.makeCreateListingRequest(userID: userID, input: input)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertEqual(json.first?["user_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(json.first?["have_ids"] as? [String], ["22222222-2222-2222-2222-222222222222"])
        XCTAssertEqual(json.first?["have_qtys"] as? [Int], [2])
        XCTAssertEqual(json.first?["have_logic"] as? String, "and")
        XCTAssertEqual(json.first?["have_min_count"] as? Int, 1)
        XCTAssertEqual(json.first?["status"] as? String, "active")
        XCTAssertEqual(json.first?["note"] as? String, "会場で交換したい")
    }

    func testBuildsCreateListingWishOptionRequest() throws {
        let client = SupabaseListingClient(configuration: configuration)
        let listingID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let input = IndividualListingCreateInput(
            haveItems: [
                ListingItemQuantity(itemID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, quantity: 1)
            ],
            haveLogic: .all,
            wishItems: [
                ListingItemQuantity(itemID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!, quantity: 3)
            ],
            wishLogic: .all,
            exchangeType: .sameKind
        )

        let request = try client.makeCreateListingWishOptionRequest(listingID: listingID, position: 1, input: input)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertEqual(json.first?["listing_id"] as? String, "44444444-4444-4444-4444-444444444444")
        XCTAssertEqual(json.first?["position"] as? Int, 1)
        XCTAssertEqual(json.first?["wish_ids"] as? [String], ["33333333-3333-3333-3333-333333333333"])
        XCTAssertEqual(json.first?["wish_qtys"] as? [Int], [3])
        XCTAssertEqual(json.first?["logic"] as? String, "and")
        XCTAssertEqual(json.first?["min_count"] as? Int, 1)
        XCTAssertEqual(json.first?["exchange_type"] as? String, "same_kind")
        XCTAssertEqual(json.first?["is_cash_offer"] as? Bool, false)
        XCTAssertNil(json.first?["cash_amount"] ?? nil)
    }

    func testBuildsUpdateListingRequest() throws {
        let client = SupabaseListingClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let listingID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let input = SupabaseListingUpdateInput(
            haveItems: [
                ListingItemQuantity(itemID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, quantity: 120)
            ],
            haveLogic: .one,
            status: .paused,
            note: "  条件変更  "
        )

        let request = try client.makeUpdateListingRequest(userID: userID, listingID: listingID, input: input)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/listings?select=id,user_id,have_ids,have_qtys,have_logic,have_min_count,have_group_id,have_goods_type_id,status,note,created_at,updated_at"))
        XCTAssertTrue(url.contains("id=eq.44444444-4444-4444-4444-444444444444"))
        XCTAssertTrue(url.contains("user_id=eq.11111111-1111-1111-1111-111111111111"))
        XCTAssertEqual(json["have_ids"] as? [String], ["22222222-2222-2222-2222-222222222222"])
        XCTAssertEqual(json["have_qtys"] as? [Int], [99])
        XCTAssertEqual(json["have_logic"] as? String, "or")
        XCTAssertEqual(json["status"] as? String, "paused")
        XCTAssertEqual(json["note"] as? String, "条件変更")
    }

    func testUpdateListingRequestCanClearNote() throws {
        let client = SupabaseListingClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let listingID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

        let request = try client.makeUpdateListingRequest(
            userID: userID,
            listingID: listingID,
            input: SupabaseListingUpdateInput(clearsNote: true)
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertTrue(json["note"] is NSNull)
    }

    func testBuildsUpdateListingWishOptionRequest() throws {
        let client = SupabaseListingClient(configuration: configuration)
        let listingID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let optionID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
        let input = SupabaseListingWishOptionUpdateInput(
            wishItems: [
                ListingItemQuantity(itemID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!, quantity: 2)
            ],
            logic: .all,
            exchangeType: .sameKind,
            isCashOffer: false,
            clearsCashAmount: true
        )

        let request = try client.makeUpdateListingWishOptionRequest(listingID: listingID, optionID: optionID, input: input)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/listing_wish_options?select=id,listing_id,position,wish_ids,wish_qtys,logic,min_count,exchange_type,is_cash_offer,cash_amount,wish_group_id,wish_goods_type_id,created_at,updated_at"))
        XCTAssertTrue(url.contains("id=eq.55555555-5555-5555-5555-555555555555"))
        XCTAssertTrue(url.contains("listing_id=eq.44444444-4444-4444-4444-444444444444"))
        XCTAssertEqual(json["wish_ids"] as? [String], ["33333333-3333-3333-3333-333333333333"])
        XCTAssertEqual(json["wish_qtys"] as? [Int], [2])
        XCTAssertEqual(json["logic"] as? String, "and")
        XCTAssertEqual(json["exchange_type"] as? String, "same_kind")
        XCTAssertEqual(json["is_cash_offer"] as? Bool, false)
        XCTAssertTrue(json["cash_amount"] is NSNull)
    }

    func testBuildsArchiveListingRequest() throws {
        let client = SupabaseListingClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let listingID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

        let request = try client.makeArchiveListingRequest(userID: userID, listingID: listingID)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertEqual(json["status"] as? String, "closed")
        XCTAssertTrue(request.url?.absoluteString.contains("id=eq.44444444-4444-4444-4444-444444444444") ?? false)
        XCTAssertTrue(request.url?.absoluteString.contains("user_id=eq.11111111-1111-1111-1111-111111111111") ?? false)
    }

    func testBuildsDeleteListingRequest() throws {
        let client = SupabaseListingClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let listingID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

        let request = try client.makeDeleteListingRequest(userID: userID, listingID: listingID)

        XCTAssertEqual(request.httpMethod, "DELETE")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=minimal")
        XCTAssertEqual(
            request.url?.absoluteString,
            "https://example.supabase.co/rest/v1/listings?id=eq.44444444-4444-4444-4444-444444444444&user_id=eq.11111111-1111-1111-1111-111111111111"
        )
    }

    func testRejectsEmptyListingUpdates() {
        let client = SupabaseListingClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let listingID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let optionID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!

        XCTAssertThrowsError(
            try client.makeUpdateListingRequest(
                userID: userID,
                listingID: listingID,
                input: SupabaseListingUpdateInput()
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseListingClientError, .emptyUpdate)
        }
        XCTAssertThrowsError(
            try client.makeUpdateListingWishOptionRequest(
                listingID: listingID,
                optionID: optionID,
                input: SupabaseListingWishOptionUpdateInput()
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseListingClientError, .emptyUpdate)
        }
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
