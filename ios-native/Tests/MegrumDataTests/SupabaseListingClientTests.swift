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
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/listings?select=id,user_id,have_ids,have_qtys,have_logic,have_group_id,have_goods_type_id,status,note,created_at,updated_at"))
        XCTAssertTrue(url.contains("user_id=eq.11111111-1111-1111-1111-111111111111"))
        XCTAssertTrue(url.contains("status=in.(active,paused,matched)"))
        XCTAssertTrue(url.contains("order=updated_at.desc"))
    }

    func testBuildsLoadListingWishOptionsRequest() throws {
        let client = SupabaseListingClient(configuration: configuration)
        let firstID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let secondID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

        let request = try client.makeLoadListingWishOptionsRequest(listingIDs: [firstID, secondID])
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/listing_wish_options?select=id,listing_id,position,wish_ids,wish_qtys,logic,exchange_type,is_cash_offer,cash_amount,wish_group_id,wish_goods_type_id,created_at,updated_at"))
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
        XCTAssertEqual(json.first?["exchange_type"] as? String, "same_kind")
        XCTAssertEqual(json.first?["is_cash_offer"] as? Bool, false)
        XCTAssertNil(json.first?["cash_amount"] ?? nil)
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
