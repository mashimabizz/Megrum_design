import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseOshiClientTests: XCTestCase {
    func testBuildsGroupSearchRequest() throws {
        let client = SupabaseOshiClient(configuration: configuration)

        let request = try client.makeGroupsRequest(searchText: "TWICE", limit: 20)

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/groups_master?select=id,name,aliases,kind,genre_id,display_order,genre:genres_master(id,name,kind,display_order)&order=display_order.asc,name.asc&limit=20&name=ilike.*TWICE*")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "sb_publishable_test")
    }

    func testBuildsCharactersRequestForGroup() throws {
        let client = SupabaseOshiClient(configuration: configuration)
        let groupID = UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!

        let request = try client.makeCharactersRequest(groupID: groupID, limit: 12)

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/characters_master?select=id,group_id,name,aliases,display_order&group_id=eq.cccccccc-cccc-cccc-cccc-cccccccccccc&order=display_order.asc,name.asc&limit=12")
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func testBuildsDeleteUserSelectionsRequest() throws {
        let client = SupabaseOshiClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let request = try client.makeDeleteUserSelectionsRequest(userID: userID)

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/user_oshi?user_id=eq.11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(request.httpMethod, "DELETE")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=minimal")
    }

    func testBuildsCreateOshiRequest() throws {
        let client = SupabaseOshiClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let genreID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeCreateOshiRequest(
            userID: userID,
            input: OshiRequestCreateInput(
                requestedName: "新しい推し",
                requestedKind: .group,
                requestedGenreID: genreID,
                note: "管理人確認用"
            )
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/oshi_requests?select=id")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertEqual(json.first?["user_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(json.first?["requested_name"] as? String, "新しい推し")
        XCTAssertEqual(json.first?["requested_kind"] as? String, "group")
        XCTAssertEqual(json.first?["requested_genre_id"] as? String, "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(json.first?["note"] as? String, "管理人確認用")
    }

    func testBuildsCreateCharacterRequestForMasterGroup() throws {
        let client = SupabaseOshiClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let groupID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

        let request = try client.makeCreateCharacterRequest(
            userID: userID,
            input: CharacterRequestCreateInput(
                groupID: groupID,
                requestedName: "ミナ",
                note: "メンバー追加"
            )
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/character_requests?select=id")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertEqual(json.first?["user_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(json.first?["group_id"] as? String, "33333333-3333-3333-3333-333333333333")
        XCTAssertNil(json.first?["oshi_request_id"] as? String)
        XCTAssertEqual(json.first?["requested_name"] as? String, "ミナ")
        XCTAssertEqual(json.first?["note"] as? String, "メンバー追加")
    }

    func testBuildsCreateCharacterRequestForPendingOshiRequest() throws {
        let client = SupabaseOshiClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let oshiRequestID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

        let request = try client.makeCreateCharacterRequest(
            userID: userID,
            input: CharacterRequestCreateInput(
                groupID: nil,
                oshiRequestID: oshiRequestID,
                requestedName: "新メンバー"
            )
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/character_requests?select=id")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertNil(json.first?["group_id"] as? String)
        XCTAssertEqual(json.first?["oshi_request_id"] as? String, "44444444-4444-4444-4444-444444444444")
        XCTAssertEqual(json.first?["requested_name"] as? String, "新メンバー")
    }

    func testBuildsLoadUserSelectionsRequest() throws {
        let client = SupabaseOshiClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let request = try client.makeLoadUserSelectionsRequest(userID: userID)

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/user_oshi?select=id,user_id,group_id,character_id,oshi_request_id,character_request_id,kind,priority,group:groups_master(id,name),character:characters_master(id,name),oshi_request:oshi_requests(id,requested_name,status),character_request:character_requests(id,requested_name,status)&user_id=eq.11111111-1111-1111-1111-111111111111&order=priority.asc")
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func testBuildsUpsertUserSelectionsRequest() throws {
        let client = SupabaseOshiClient(configuration: configuration)
        let selection = UserOshiSelection(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            userID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            groupID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            characterID: nil,
            kind: .box,
            priority: 1
        )

        let request = try client.makeUpsertUserSelectionsRequest([selection])
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/user_oshi?select=id,user_id,group_id,character_id,oshi_request_id,character_request_id,kind,priority,group:groups_master(id,name),character:characters_master(id,name),oshi_request:oshi_requests(id,requested_name,status),character_request:character_requests(id,requested_name,status)")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "resolution=merge-duplicates,return=representation")
        XCTAssertEqual(json.first?["id"] as? String, "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(json.first?["user_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(json.first?["group_id"] as? String, "33333333-3333-3333-3333-333333333333")
        XCTAssertEqual(json.first?["kind"] as? String, "box")
        XCTAssertEqual(json.first?["priority"] as? Int, 1)
    }

    func testUpsertUserSelectionsRequestKeepsStableKeysForMixedSelectionTargets() throws {
        let client = SupabaseOshiClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let groupID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let characterID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let oshiRequestID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!

        let request = try client.makeUpsertUserSelectionsRequest([
            UserOshiSelection(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222221")!,
                userID: userID,
                groupID: groupID,
                characterID: nil,
                kind: .box,
                priority: 1
            ),
            UserOshiSelection(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                userID: userID,
                groupID: groupID,
                characterID: characterID,
                kind: .specific,
                priority: 2
            ),
            UserOshiSelection(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222223")!,
                userID: userID,
                groupID: nil,
                characterID: nil,
                kind: .box,
                priority: 3,
                oshiRequestID: oshiRequestID
            )
        ])
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let expectedKeys: Set<String> = [
            "id",
            "user_id",
            "group_id",
            "character_id",
            "oshi_request_id",
            "character_request_id",
            "kind",
            "priority"
        ]

        XCTAssertEqual(json.map { Set($0.keys) }, [expectedKeys, expectedKeys, expectedKeys])
        XCTAssertTrue(json[0]["character_id"] is NSNull)
        XCTAssertTrue(json[0]["oshi_request_id"] is NSNull)
        XCTAssertEqual(json[1]["character_id"] as? String, "44444444-4444-4444-4444-444444444444")
        XCTAssertTrue(json[1]["oshi_request_id"] is NSNull)
        XCTAssertTrue(json[2]["group_id"] is NSNull)
        XCTAssertEqual(json[2]["oshi_request_id"] as? String, "55555555-5555-5555-5555-555555555555")
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
