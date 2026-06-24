import MegrumData
import XCTest

final class SupabaseEntitlementClientTests: XCTestCase {
    func testBuildsLoadEntitlementsRequest() throws {
        let client = SupabaseEntitlementClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let request = try client.makeLoadEntitlementsRequest(userID: userID)

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://example.supabase.co/rest/v1/user_entitlements?select=feature_key,active,source,granted_at,expires_at,updated_at&user_id=eq.11111111-1111-1111-1111-111111111111&feature_key=in.(premium,meguri_plus)"
        )
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "sb_publishable_test")
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
