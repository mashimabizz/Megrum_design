import MegrumCore
import MegrumData
import XCTest

final class SupabaseEntitlementClientTests: XCTestCase {
    func testBuildsLoadEntitlementsRequest() throws {
        let client = SupabaseEntitlementClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let request = try client.makeLoadEntitlementsRequest(userID: userID)

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://example.supabase.co/rest/v1/user_entitlements?select=feature_key,active,source,granted_at,expires_at,updated_at&user_id=eq.11111111-1111-1111-1111-111111111111&feature_key=in.(megrum_plus,premium,meguri_plus)"
        )
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "sb_publishable_test")
    }

    func testBuildsSyncMegrumPlusPurchaseRequest() throws {
        let client = SupabaseEntitlementClient(configuration: configuration)
        let input = MegrumPlusPurchaseSyncInput(
            productID: "megrum.plus.monthly",
            transactionID: "100000000001",
            originalTransactionID: "100000000000",
            expiresAt: Date(timeIntervalSince1970: 1_800),
            verifiedAt: Date(timeIntervalSince1970: 1_200)
        )

        let request = try client.makeSyncMegrumPlusPurchaseRequest(input)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://example.supabase.co/rest/v1/rpc/sync_megrum_plus_purchase_for_viewer"
        )
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(json["p_product_id"] as? String, "megrum.plus.monthly")
        XCTAssertEqual(json["p_transaction_id"] as? String, "100000000001")
        XCTAssertEqual(json["p_original_transaction_id"] as? String, "100000000000")
        XCTAssertEqual(json["p_expires_at"] as? String, "1970-01-01T00:30:00.000Z")
        XCTAssertEqual(json["p_verified_at"] as? String, "1970-01-01T00:20:00.000Z")
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
