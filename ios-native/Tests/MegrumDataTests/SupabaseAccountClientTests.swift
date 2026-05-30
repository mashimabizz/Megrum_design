import MegrumCore
import MegrumData
import XCTest

final class SupabaseAccountClientTests: XCTestCase {
    func testBuildsProfileUpsertRequestWithSessionBearer() throws {
        let client = SupabaseAccountClient(configuration: configuration)
        let session = AuthSession(
            accessToken: "session_token",
            user: AuthUser(
                id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
                email: "michi@example.com"
            )
        )

        let request = try client.makeEnsureUserProfileRequest(
            session: session,
            handle: "@Michi-1",
            displayName: "みちりおん"
        )

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/users?select=id,handle,display_name,avatar_url,primary_area&on_conflict=id")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "sb_publishable_test")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer session_token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "resolution=merge-duplicates,return=representation")

        let body = try XCTUnwrap(request.jsonArrayBody?.first)
        XCTAssertEqual(body["id"] as? String, "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")
        XCTAssertEqual(body["handle"] as? String, "michi_1")
        XCTAssertEqual(body["display_name"] as? String, "みちりおん")
        XCTAssertEqual(body["account_status"] as? String, "onboarding")
    }

    func testFallbackHandleUsesUserIDWhenHandleIsEmpty() {
        let handle = SupabaseAccountClient.normalizedHandle(
            " @ ",
            fallbackUserID: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
        )

        XCTAssertEqual(handle, "megrum_bbbbbbbbbbbb")
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}

private extension URLRequest {
    var jsonArrayBody: [[String: Any]]? {
        guard let httpBody else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: httpBody) as? [[String: Any]]
    }
}
