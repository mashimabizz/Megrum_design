import MegrumData
import XCTest

final class SupabaseAuthClientTests: XCTestCase {
    func testBuildsPasswordSignInRequest() throws {
        let client = SupabaseAuthClient(configuration: configuration)

        let request = try client.makePasswordSignInRequest(
            email: "michi@example.com",
            password: "password123"
        )

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/auth/v1/token?grant_type=password")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "sb_publishable_test")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer sb_publishable_test")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = try XCTUnwrap(request.jsonBody)
        XCTAssertEqual(body["email"] as? String, "michi@example.com")
        XCTAssertEqual(body["password"] as? String, "password123")
    }

    func testBuildsSignUpRequestWithMetadataAndRedirect() throws {
        let client = SupabaseAuthClient(configuration: configuration)

        let request = try client.makeSignUpRequest(
            email: "michi@example.com",
            password: "password123",
            metadata: SupabaseAuthProfileMetadata(handle: "michi1", displayName: "みちりおん"),
            emailRedirectTo: URL(string: "https://megrum.jp/auth/callback?next=mobile&scheme=megrum-preview")
        )

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/auth/v1/signup")
        let body = try XCTUnwrap(request.jsonBody)
        XCTAssertEqual(body["email"] as? String, "michi@example.com")
        XCTAssertEqual(body["password"] as? String, "password123")
        XCTAssertEqual(body["email_redirect_to"] as? String, "https://megrum.jp/auth/callback?next=mobile&scheme=megrum-preview")

        let data = try XCTUnwrap(body["data"] as? [String: Any])
        XCTAssertEqual(data["handle"] as? String, "michi1")
        XCTAssertEqual(data["display_name"] as? String, "みちりおん")
    }

    func testBuildsSignOutRequestWithSessionBearer() throws {
        let client = SupabaseAuthClient(configuration: configuration)

        let request = try client.makeSignOutRequest(accessToken: "session_token")

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/auth/v1/logout")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer session_token")
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}

private extension URLRequest {
    var jsonBody: [String: Any]? {
        guard let httpBody else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: httpBody) as? [String: Any]
    }
}
