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

    func testBuildsLoadProposalReadStateRequest() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let proposalID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let userID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeLoadProposalReadStateRequest(proposalID: proposalID, userID: userID)
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/proposal_read_states?select=proposal_id,user_id,last_read_at,updated_at"))
        XCTAssertTrue(url.contains("proposal_id=eq.11111111-1111-1111-1111-111111111111"))
        XCTAssertTrue(url.contains("user_id=eq.22222222-2222-2222-2222-222222222222"))
        XCTAssertTrue(url.contains("limit=1"))
    }

    func testBuildsMarkProposalMessagesReadRequest() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let proposalID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let userID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let lastReadAt = Date(timeIntervalSince1970: 1_800_000_000)
        let updatedAt = Date(timeIntervalSince1970: 1_800_000_120)

        let request = try client.makeMarkProposalMessagesReadRequest(
            proposalID: proposalID,
            userID: userID,
            lastReadAt: lastReadAt,
            updatedAt: updatedAt
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let payload = try XCTUnwrap(json.first)
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "resolution=merge-duplicates,return=representation")
        XCTAssertTrue(url.contains("on_conflict=proposal_id,user_id"))
        XCTAssertEqual(payload["proposal_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(payload["user_id"] as? String, "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(payload["last_read_at"] as? String, "2027-01-15T08:00:00.000Z")
        XCTAssertEqual(payload["updated_at"] as? String, "2027-01-15T08:02:00.000Z")
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

    func testBuildsGenericPhotoMessageRequestWithoutOperationalFields() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let photoURL = URL(string: "https://example.com/chat/photo.jpg")!

        let request = try client.makeSendPhotoMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            photoURL: photoURL,
            messageType: .photo
        )
        let payload = try messagePayload(from: request)

        XCTAssertEqual(payload["message_type"] as? String, "photo")
        XCTAssertEqual(payload["photo_url"] as? String, "https://example.com/chat/photo.jpg")
        XCTAssertNil(payload["body"])
        XCTAssertNil(payload["location_lat"])
        XCTAssertNil(payload["location_lng"])
        XCTAssertNil(payload["location_label"])
        XCTAssertNil(payload["meta"])
    }

    func testBuildsOutfitPhotoMessageRequestWithDefaultBody() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let photoURL = URL(string: "https://example.com/chat/outfit.jpg")!

        let request = try client.makeSendPhotoMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            photoURL: photoURL,
            messageType: .outfitPhoto
        )
        let payload = try messagePayload(from: request)

        XCTAssertEqual(payload["message_type"] as? String, "outfit_photo")
        XCTAssertEqual(payload["photo_url"] as? String, "https://example.com/chat/outfit.jpg")
        XCTAssertEqual(payload["body"] as? String, "服装写真を共有しました")
    }

    func testBuildsTypedOutfitPhotoMessageRequest() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let photoURL = URL(string: "https://example.com/chat/outfit.jpg")!

        let request = try client.makeSendOutfitPhotoMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            photoURL: photoURL
        )
        let payload = try messagePayload(from: request)

        XCTAssertEqual(payload["message_type"] as? String, "outfit_photo")
        XCTAssertEqual(payload["photo_url"] as? String, "https://example.com/chat/outfit.jpg")
        XCTAssertEqual(payload["body"] as? String, "服装写真を共有しました")
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

    func testRejectsPhotoMessageRequestWithoutHTTPPhotoURL() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        XCTAssertThrowsError(
            try client.makeSendMessageRequest(
                senderID: senderID,
                proposalID: proposalID,
                messageType: .photo
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseMessageClientError, .invalidPhotoURL)
        }

        XCTAssertThrowsError(
            try client.makeSendPhotoMessageRequest(
                senderID: senderID,
                proposalID: proposalID,
                photoURL: URL(fileURLWithPath: "/tmp/photo.jpg"),
                messageType: .photo
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseMessageClientError, .invalidPhotoURL)
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

    func testBuildsCurrentLocationMessageRequestWithDefaultLabel() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeSendCurrentLocationMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            latitude: 35.443707,
            longitude: 139.638031
        )
        let payload = try messagePayload(from: request)

        XCTAssertEqual(payload["message_type"] as? String, "location")
        XCTAssertEqual(payload["body"] as? String, "現在地")
        XCTAssertEqual(payload["location_lat"] as? Double, 35.443707)
        XCTAssertEqual(payload["location_lng"] as? Double, 139.638031)
        XCTAssertEqual(payload["location_label"] as? String, "現在地")
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

    func testRejectsLocationMessageRequestWithoutLabel() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        XCTAssertThrowsError(
            try client.makeSendLocationMessageRequest(
                senderID: senderID,
                proposalID: proposalID,
                latitude: 35.443707,
                longitude: 139.638031,
                label: "   "
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

    func testRejectsArrivalStatusMessageRequestWithoutStatusMetadata() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        XCTAssertThrowsError(
            try client.makeSendMessageRequest(
                senderID: senderID,
                proposalID: proposalID,
                messageType: .arrivalStatus,
                body: "到着しました"
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseMessageClientError, .invalidMetadata)
        }
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

    func testRejectsEmptyTextAndSystemMessageBodies() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        XCTAssertThrowsError(
            try client.makeSendTextMessageRequest(
                senderID: senderID,
                input: TradeMessageCreateInput(proposalID: proposalID, body: "   ")
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseMessageClientError, .invalidBody)
        }

        XCTAssertThrowsError(
            try client.makeSendSystemMessageRequest(
                senderID: senderID,
                proposalID: proposalID,
                body: "\n\t "
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseMessageClientError, .invalidBody)
        }
    }

    func testBuildsLateNoticeSystemMessageRequestWithRNCompatibleMetadata() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeSendLateNoticeMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            lateMinutes: .twenty,
            reason: " 電車遅延 ",
            note: " 北口へ向かっています "
        )
        let payload = try messagePayload(from: request)
        let meta = try XCTUnwrap(payload["meta"] as? [String: Any])

        XCTAssertEqual(payload["message_type"] as? String, "system")
        XCTAssertEqual(payload["body"] as? String, "20分遅れる旨が通知されました\n理由：電車遅延\n北口へ向かっています")
        XCTAssertEqual(meta["action"] as? String, "late_notice")
        XCTAssertEqual(meta["notified_by"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(meta["late_minutes"] as? Int, 20)
        XCTAssertEqual(meta["reason"] as? String, "電車遅延")
        XCTAssertEqual(meta["note"] as? String, "北口へ向かっています")
    }

    func testBuildsLateNoticeSystemMessageRequestFromTypedMinutesValue() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeSendLateNoticeMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            lateMinutes: 30,
            reason: " 入場列待ち "
        )
        let payload = try messagePayload(from: request)
        let meta = try XCTUnwrap(payload["meta"] as? [String: Any])

        XCTAssertEqual(payload["body"] as? String, "30分遅れる旨が通知されました\n理由：入場列待ち")
        XCTAssertEqual(meta["action"] as? String, "late_notice")
        XCTAssertEqual(meta["late_minutes"] as? Int, 30)
        XCTAssertEqual(meta["reason"] as? String, "入場列待ち")
    }

    func testRejectsUnsupportedLateMinutesValue() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        XCTAssertThrowsError(
            try client.makeSendLateNoticeMessageRequest(
                senderID: senderID,
                proposalID: proposalID,
                lateMinutes: 15,
                reason: "電車遅延"
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseMessageClientError, .invalidMetadata)
        }
    }

    func testBuildsCancelRequestSystemMessageRequestWithRNCompatibleMetadata() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeSendCancelRequestMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            reason: " 急用 ",
            note: " 明日の同時刻なら可能です "
        )
        let payload = try messagePayload(from: request)
        let meta = try XCTUnwrap(payload["meta"] as? [String: Any])

        XCTAssertEqual(payload["message_type"] as? String, "system")
        XCTAssertEqual(payload["body"] as? String, "取引キャンセルが申請されました\n理由：急用\n明日の同時刻なら可能です")
        XCTAssertEqual(meta["action"] as? String, "cancel_requested")
        XCTAssertEqual(meta["requested_by"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(meta["reason"] as? String, "急用")
        XCTAssertEqual(meta["note"] as? String, "明日の同時刻なら可能です")
    }

    func testBuildsCancelApprovedSystemMessageRequestWithMetadata() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeSendCancelApprovedMessageRequest(
            senderID: senderID,
            proposalID: proposalID
        )
        let payload = try messagePayload(from: request)
        let meta = try XCTUnwrap(payload["meta"] as? [String: Any])

        XCTAssertEqual(payload["message_type"] as? String, "system")
        XCTAssertEqual(payload["body"] as? String, "取引キャンセルが合意されました（評価への影響なし）")
        XCTAssertEqual(meta["action"] as? String, "cancel_approved")
        XCTAssertEqual(meta["approved_by"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertNil(payload["photo_url"])
        XCTAssertNil(payload["location_lat"])
        XCTAssertNil(payload["location_lng"])
        XCTAssertNil(payload["location_label"])
    }

    func testRejectsOperationalSystemMessagesWithoutReason() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        XCTAssertThrowsError(
            try client.makeSendLateNoticeMessageRequest(
                senderID: senderID,
                proposalID: proposalID,
                lateMinutes: .ten,
                reason: " "
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseMessageClientError, .invalidBody)
        }

        XCTAssertThrowsError(
            try client.makeSendCancelRequestMessageRequest(
                senderID: senderID,
                proposalID: proposalID,
                reason: "\n"
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseMessageClientError, .invalidBody)
        }
    }

    private func messagePayload(from request: URLRequest) throws -> [String: Any] {
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        return try XCTUnwrap(json.first)
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
