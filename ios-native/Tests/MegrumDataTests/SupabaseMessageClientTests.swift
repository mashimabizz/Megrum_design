import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseMessageClientTests: XCTestCase {
    func testBuildsLoadMessagesRequest() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let proposalID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let request = try client.makeLoadMessagesRequest(proposalID: proposalID, limit: 50)
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/messages?select=id,proposal_id,sender_id,message_type,body,photo_url,location_lat,location_lng,location_label,meta,created_at"))
        XCTAssertTrue(url.contains("proposal_id=eq.11111111-1111-1111-1111-111111111111"))
        XCTAssertTrue(url.contains("order=created_at.asc"))
        XCTAssertTrue(url.contains("limit=50"))
    }

    func testBuildsSendTextMessageRequest() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeSendTextMessageRequest(
            senderID: senderID,
            input: TradeMessageCreateInput(proposalID: proposalID, body: " よろしくお願いします ")
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "resolution=merge-duplicates,return=representation")
        XCTAssertEqual(json.first?["proposal_id"] as? String, "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(json.first?["sender_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(json.first?["message_type"] as? String, "text")
        XCTAssertEqual(json.first?["body"] as? String, "よろしくお願いします")
    }

    func testBuildsSendPhotoMessageRequest() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let photoURL = URL(string: "https://example.com/chat/photo.jpg")!

        let request = try client.makeSendPhotoMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            photoURL: photoURL,
            body: " 服装写真です ",
            messageType: .outfitPhoto
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "resolution=merge-duplicates,return=representation")
        XCTAssertEqual(json.first?["proposal_id"] as? String, "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(json.first?["sender_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(json.first?["message_type"] as? String, "outfit_photo")
        XCTAssertEqual(json.first?["photo_url"] as? String, "https://example.com/chat/photo.jpg")
        XCTAssertEqual(json.first?["body"] as? String, "服装写真です")
    }

    func testRejectsNonPhotoTypeForPhotoMessageRequest() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let photoURL = URL(string: "https://example.com/chat/photo.jpg")!

        XCTAssertThrowsError(
            try client.makeSendPhotoMessageRequest(
                senderID: senderID,
                proposalID: proposalID,
                photoURL: photoURL,
                messageType: .location
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseMessageClientError, .invalidPhotoMessageType)
        }
    }

    func testBuildsLocationMessageRequestWithSchemaRequiredFields() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let locationRequest = try client.makeSendLocationMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            latitude: 35.443707,
            longitude: 139.638031,
            label: " 横浜アリーナ 北口 ",
            body: " 北口にいます "
        )
        let locationBody = try XCTUnwrap(locationRequest.httpBody)
        let locationJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: locationBody) as? [[String: Any]])

        XCTAssertEqual(locationJSON.first?["message_type"] as? String, "location")
        XCTAssertEqual(locationJSON.first?["body"] as? String, "北口にいます")
        XCTAssertEqual(locationJSON.first?["location_lat"] as? Double, 35.443707)
        XCTAssertEqual(locationJSON.first?["location_lng"] as? Double, 139.638031)
        XCTAssertEqual(locationJSON.first?["location_label"] as? String, "横浜アリーナ 北口")
        XCTAssertNil(locationJSON.first?["photo_url"])
    }

    func testRejectsLocationMessageRequestWithoutUsableCoordinates() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        XCTAssertThrowsError(
            try client.makeSendLocationMessageRequest(
                senderID: senderID,
                proposalID: proposalID,
                latitude: 135,
                longitude: 139.638031,
                label: "横浜アリーナ 北口"
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseMessageClientError, .invalidLocation)
        }
    }

    func testBuildsArrivalStatusMessageRequestWithMetadata() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeSendArrivalStatusMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            status: SupabaseMessageArrivalStatus.arrived,
            body: " 北口に着きました "
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let meta = try XCTUnwrap(json.first?["meta"] as? [String: Any])

        XCTAssertEqual(json.first?["message_type"] as? String, "arrival_status")
        XCTAssertEqual(json.first?["body"] as? String, "北口に着きました")
        XCTAssertEqual(meta["status"] as? String, "arrived")
        XCTAssertNil(json.first?["photo_url"])
    }

    func testBuildsSystemMessageRequest() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let systemRequest = try client.makeSendSystemMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            body: " 通報を受け付けました "
        )
        let systemBody = try XCTUnwrap(systemRequest.httpBody)
        let systemJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: systemBody) as? [[String: Any]])

        XCTAssertEqual(systemJSON.first?["message_type"] as? String, "system")
        XCTAssertEqual(systemJSON.first?["body"] as? String, "通報を受け付けました")
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
