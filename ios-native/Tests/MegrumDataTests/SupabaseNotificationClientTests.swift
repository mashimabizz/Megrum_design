import Foundation
import MegrumData
import XCTest

final class SupabaseNotificationClientTests: XCTestCase {
    func testBuildsLoadNotificationsRequest() throws {
        let client = SupabaseNotificationClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let request = try client.makeLoadNotificationsRequest(userID: userID, limit: 50)

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/notifications?select=id,kind,title,body,link_path,read_at,created_at&user_id=eq.11111111-1111-1111-1111-111111111111&order=created_at.desc&limit=50")
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func testBuildsMarkReadRequest() throws {
        let client = SupabaseNotificationClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let notificationID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let readAt = Date(timeIntervalSince1970: 1_779_900_000)

        let request = try client.makeMarkReadRequest(userID: userID, notificationID: notificationID, readAt: readAt)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/notifications?select=id,kind,title,body,link_path,read_at,created_at&id=eq.22222222-2222-2222-2222-222222222222&user_id=eq.11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertEqual(json["read_at"] as? String, "2026-05-27T16:40:00Z")
    }

    func testBuildsMarkAllReadRequest() throws {
        let client = SupabaseNotificationClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let readAt = Date(timeIntervalSince1970: 1_779_900_000)

        let request = try client.makeMarkAllReadRequest(userID: userID, readAt: readAt)

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/notifications?select=id,kind,title,body,link_path,read_at,created_at&user_id=eq.11111111-1111-1111-1111-111111111111&read_at=is.null")
        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
    }

    func testBuildsLoadPushSettingRequest() throws {
        let client = SupabaseNotificationClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let request = try client.makeLoadPushSettingRequest(userID: userID)

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/user_notification_settings?select=push_enabled&user_id=eq.11111111-1111-1111-1111-111111111111&limit=1")
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func testBuildsSetPushSettingRequest() throws {
        let client = SupabaseNotificationClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let request = try client.makeSetPushSettingRequest(userID: userID, enabled: false)
        let body = try XCTUnwrap(request.httpBody)
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let payload = try XCTUnwrap(rows.first)

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/user_notification_settings?select=push_enabled&on_conflict=user_id")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "resolution=merge-duplicates,return=representation")
        XCTAssertEqual(payload["user_id"] as? String, userID.uuidString.lowercased())
        XCTAssertEqual(payload["push_enabled"] as? Bool, false)
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
