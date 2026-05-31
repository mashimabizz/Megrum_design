import Foundation
import MegrumData
import XCTest

final class SupabaseActivityWindowClientTests: XCTestCase {
    func testBuildsLoadActivityWindowsRequest() throws {
        let client = SupabaseActivityWindowClient(configuration: configuration)
        let userID = uuid("11111111-1111-1111-1111-111111111111")

        let request = try client.makeLoadActivityWindowsRequest(
            userID: userID,
            status: .enabled,
            from: date("2026-05-31T01:00:00Z"),
            to: date("2026-05-31T10:00:00Z"),
            limit: 24
        )
        let url = try XCTUnwrap(request.url?.absoluteString.removingPercentEncoding)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/activity_windows?select=id,user_id,venue,center_lat,center_lng,radius_m,event_name,eventless,start_at,end_at,note,status,created_at,updated_at"))
        XCTAssertTrue(url.contains("user_id=eq.11111111-1111-1111-1111-111111111111"))
        XCTAssertTrue(url.contains("status=eq.enabled"))
        XCTAssertTrue(url.contains("end_at=gt.2026-05-31T01:00:00Z"))
        XCTAssertTrue(url.contains("start_at=lt.2026-05-31T10:00:00Z"))
        XCTAssertTrue(url.contains("order=start_at.asc"))
        XCTAssertTrue(url.contains("limit=24"))
    }

    func testBuildsLoadVisibleActivityWindowsRequest() throws {
        let client = SupabaseActivityWindowClient(configuration: configuration)
        let userID = uuid("11111111-1111-1111-1111-111111111111")

        let request = try client.makeLoadVisibleActivityWindowsRequest(
            excludingUserID: userID,
            limit: 800
        )
        let url = try XCTUnwrap(request.url?.absoluteString.removingPercentEncoding)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.contains("/rest/v1/activity_windows?select=id,user_id,venue"))
        XCTAssertTrue(url.contains("user_id=neq.11111111-1111-1111-1111-111111111111"))
        XCTAssertTrue(url.contains("status=eq.enabled"))
        XCTAssertTrue(url.contains("limit=500"))
    }

    func testBuildsCreateActivityWindowRequest() throws {
        let client = SupabaseActivityWindowClient(configuration: configuration)
        let userID = uuid("11111111-1111-1111-1111-111111111111")

        let request = try client.makeCreateActivityWindowRequest(
            userID: userID,
            input: SupabaseActivityWindowCreateInput(
                venue: " 東京ドーム 22ゲート ",
                center: SupabaseActivityWindowCoordinate(latitude: 35.70564, longitude: 139.75189),
                radiusMeters: 800,
                startAt: date("2026-05-31T02:00:00Z"),
                endAt: date("2026-05-31T04:00:00Z"),
                note: " 青いバッグ "
            )
        )
        let rows = try payloadRows(from: request)
        let payload = try XCTUnwrap(rows.first)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertTrue(request.url?.absoluteString.contains("/rest/v1/activity_windows?select=id,user_id,venue,center_lat,center_lng,radius_m,event_name,eventless,start_at,end_at,note,status,created_at,updated_at") ?? false)
        XCTAssertEqual(payload["user_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(payload["venue"] as? String, "東京ドーム 22ゲート")
        XCTAssertEqual(try XCTUnwrap(payload["center_lat"] as? Double), 35.70564, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(payload["center_lng"] as? Double), 139.75189, accuracy: 0.000001)
        XCTAssertEqual(payload["radius_m"] as? Int, 800)
        XCTAssertTrue(payload["event_name"] is NSNull)
        XCTAssertEqual(payload["eventless"] as? Bool, true)
        XCTAssertEqual(payload["start_at"] as? String, "2026-05-31T02:00:00Z")
        XCTAssertEqual(payload["end_at"] as? String, "2026-05-31T04:00:00Z")
        XCTAssertEqual(payload["note"] as? String, "青いバッグ")
        XCTAssertEqual(payload["status"] as? String, "enabled")
    }

    func testBuildsUpdateActivityWindowRequest() throws {
        let client = SupabaseActivityWindowClient(configuration: configuration)
        let userID = uuid("11111111-1111-1111-1111-111111111111")
        let activityWindowID = uuid("22222222-2222-2222-2222-222222222222")

        let request = try client.makeUpdateActivityWindowRequest(
            userID: userID,
            activityWindowID: activityWindowID,
            input: SupabaseActivityWindowUpdateInput(
                venue: " 幕張メッセ 北ホール ",
                center: SupabaseActivityWindowCoordinate(latitude: 35.6484, longitude: 140.0347),
                radiusMeters: 1_000,
                eventName: "   ",
                startAt: date("2026-05-31T03:00:00Z"),
                endAt: date("2026-05-31T06:00:00Z"),
                clearsNote: true,
                status: .disabled
            )
        )
        let payload = try objectPayload(from: request)
        let url = try XCTUnwrap(request.url?.absoluteString.removingPercentEncoding)

        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertTrue(url.contains("id=eq.22222222-2222-2222-2222-222222222222"))
        XCTAssertTrue(url.contains("user_id=eq.11111111-1111-1111-1111-111111111111"))
        XCTAssertEqual(payload["venue"] as? String, "幕張メッセ 北ホール")
        XCTAssertEqual(try XCTUnwrap(payload["center_lat"] as? Double), 35.6484, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(payload["center_lng"] as? Double), 140.0347, accuracy: 0.000001)
        XCTAssertEqual(payload["radius_m"] as? Int, 1_000)
        XCTAssertTrue(payload["event_name"] is NSNull)
        XCTAssertEqual(payload["start_at"] as? String, "2026-05-31T03:00:00Z")
        XCTAssertEqual(payload["end_at"] as? String, "2026-05-31T06:00:00Z")
        XCTAssertTrue(payload["note"] is NSNull)
        XCTAssertEqual(payload["status"] as? String, "disabled")
    }

    func testBuildsDisableOtherEnabledActivityWindowsRequest() throws {
        let client = SupabaseActivityWindowClient(configuration: configuration)
        let userID = uuid("11111111-1111-1111-1111-111111111111")
        let keepingID = uuid("22222222-2222-2222-2222-222222222222")

        let request = try client.makeDisableOtherEnabledActivityWindowsRequest(
            userID: userID,
            keeping: keepingID
        )
        let payload = try objectPayload(from: request)
        let url = try XCTUnwrap(request.url?.absoluteString.removingPercentEncoding)

        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertTrue(url.contains("user_id=eq.11111111-1111-1111-1111-111111111111"))
        XCTAssertTrue(url.contains("status=eq.enabled"))
        XCTAssertTrue(url.contains("id=neq.22222222-2222-2222-2222-222222222222"))
        XCTAssertEqual(payload["status"] as? String, "disabled")
    }

    func testBuildsLoadLocalModeSettingsRequest() throws {
        let client = SupabaseActivityWindowClient(configuration: configuration)
        let userID = uuid("11111111-1111-1111-1111-111111111111")

        let request = try client.makeLoadLocalModeSettingsRequest(userID: userID)
        let url = try XCTUnwrap(request.url?.absoluteString.removingPercentEncoding)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/user_local_mode_settings?select=user_id,enabled,aw_id,radius_m,selected_carrying_ids,selected_wish_ids,last_lat,last_lng,updated_at"))
        XCTAssertTrue(url.contains("user_id=eq.11111111-1111-1111-1111-111111111111"))
        XCTAssertTrue(url.contains("limit=1"))
    }

    func testBuildsUpsertLocalModeSettingsRequest() throws {
        let client = SupabaseActivityWindowClient(configuration: configuration)
        let userID = uuid("11111111-1111-1111-1111-111111111111")
        let activityWindowID = uuid("22222222-2222-2222-2222-222222222222")
        let carryingID = uuid("33333333-3333-3333-3333-333333333333")
        let wishID = uuid("44444444-4444-4444-4444-444444444444")

        let request = try client.makeUpsertLocalModeSettingsRequest(
            userID: userID,
            input: SupabaseLocalModeSettingsUpsertInput(
                enabled: true,
                activityWindowID: activityWindowID,
                radiusMeters: 1_000,
                selectedCarryingIDs: [carryingID],
                selectedWishIDs: [wishID],
                lastLocation: SupabaseActivityWindowCoordinate(latitude: 35.70564, longitude: 139.75189)
            )
        )
        let rows = try payloadRows(from: request)
        let payload = try XCTUnwrap(rows.first)
        let url = try XCTUnwrap(request.url?.absoluteString.removingPercentEncoding)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertTrue(url.contains("/rest/v1/user_local_mode_settings?select=user_id,enabled,aw_id,radius_m,selected_carrying_ids,selected_wish_ids,last_lat,last_lng,updated_at"))
        XCTAssertTrue(url.contains("on_conflict=user_id"))
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "resolution=merge-duplicates,return=representation")
        XCTAssertEqual(payload["user_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(payload["enabled"] as? Bool, true)
        XCTAssertEqual(payload["aw_id"] as? String, "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(payload["radius_m"] as? Int, 1_000)
        XCTAssertEqual(payload["selected_carrying_ids"] as? [String], ["33333333-3333-3333-3333-333333333333"])
        XCTAssertEqual(payload["selected_wish_ids"] as? [String], ["44444444-4444-4444-4444-444444444444"])
        XCTAssertEqual(try XCTUnwrap(payload["last_lat"] as? Double), 35.70564, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(payload["last_lng"] as? Double), 139.75189, accuracy: 0.000001)
    }

    func testLocalModeOffUpsertCanPreservePreviousActivityWindowSelection() throws {
        let client = SupabaseActivityWindowClient(configuration: configuration)
        let userID = uuid("11111111-1111-1111-1111-111111111111")

        let request = try client.makeUpsertLocalModeSettingsRequest(
            userID: userID,
            input: SupabaseLocalModeSettingsUpsertInput(enabled: false)
        )
        let rows = try payloadRows(from: request)
        let payload = try XCTUnwrap(rows.first)

        XCTAssertEqual(payload["enabled"] as? Bool, false)
        XCTAssertNil(payload["aw_id"])
        XCTAssertNil(payload["radius_m"])
        XCTAssertNil(payload["selected_carrying_ids"])
        XCTAssertNil(payload["selected_wish_ids"])
        XCTAssertNil(payload["last_lat"])
        XCTAssertNil(payload["last_lng"])
    }

    func testRejectsInvalidCreateActivityWindowInputs() {
        let client = SupabaseActivityWindowClient(configuration: configuration)
        let userID = uuid("11111111-1111-1111-1111-111111111111")

        XCTAssertThrowsError(
            try client.makeCreateActivityWindowRequest(
                userID: userID,
                input: SupabaseActivityWindowCreateInput(
                    venue: "   ",
                    startAt: date("2026-05-31T02:00:00Z"),
                    endAt: date("2026-05-31T04:00:00Z")
                )
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseActivityWindowClientError, .invalidVenue)
        }

        XCTAssertThrowsError(
            try client.makeCreateActivityWindowRequest(
                userID: userID,
                input: SupabaseActivityWindowCreateInput(
                    venue: "東京ドーム",
                    radiusMeters: 20,
                    startAt: date("2026-05-31T02:00:00Z"),
                    endAt: date("2026-05-31T04:00:00Z")
                )
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseActivityWindowClientError, .invalidRadius)
        }
    }

    func testRejectsEmptyActivityWindowUpdate() {
        let client = SupabaseActivityWindowClient(configuration: configuration)

        XCTAssertThrowsError(
            try client.makeUpdateActivityWindowRequest(
                userID: uuid("11111111-1111-1111-1111-111111111111"),
                activityWindowID: uuid("22222222-2222-2222-2222-222222222222"),
                input: SupabaseActivityWindowUpdateInput()
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseActivityWindowClientError, .emptyUpdate)
        }
    }

    private func payloadRows(from request: URLRequest) throws -> [[String: Any]] {
        let body = try XCTUnwrap(request.httpBody)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
    }

    private func objectPayload(from request: URLRequest) throws -> [String: Any] {
        let body = try XCTUnwrap(request.httpBody)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }

    private func uuid(_ value: String) -> UUID {
        UUID(uuidString: value)!
    }

    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
