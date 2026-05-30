import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseMailingAddressClientTests: XCTestCase {
    func testBuildsLoadAddressRequest() throws {
        let client = SupabaseMailingAddressClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let request = try client.makeLoadAddressRequest(userID: userID)

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/user_mailing_addresses?select=user_id,recipient_name,postal_code,prefecture,city,line1,line2,phone_number,created_at,updated_at&user_id=eq.11111111-1111-1111-1111-111111111111&limit=1")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "sb_publishable_test")
    }

    func testBuildsUpsertAddressRequest() throws {
        let client = SupabaseMailingAddressClient(configuration: configuration)
        let address = MailingAddress(
            userID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            recipientName: "みちりおん",
            postalCode: "1000001",
            prefecture: "東京都",
            city: "千代田区",
            line1: "千代田1-1",
            line2: "Megrumビル",
            phoneNumber: "0312345678"
        )

        let request = try client.makeUpsertAddressRequest(address)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/user_mailing_addresses?select=user_id,recipient_name,postal_code,prefecture,city,line1,line2,phone_number,created_at,updated_at&on_conflict=user_id")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "resolution=merge-duplicates,return=representation")
        XCTAssertEqual(json.first?["user_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(json.first?["postal_code"] as? String, "1000001")
        XCTAssertEqual(json.first?["recipient_name"] as? String, "みちりおん")
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
