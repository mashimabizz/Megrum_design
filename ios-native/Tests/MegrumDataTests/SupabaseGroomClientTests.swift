import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseGroomClientTests: XCTestCase {
    func testBuildsNearbyGroomRPCRequest() throws {
        let client = SupabaseGroomClient(configuration: configuration)

        let request = try client.makeLoadNearbyGroomsRequest(
            latitude: 35.681236,
            longitude: 139.767125,
            radiusMeters: 2_500
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/list_groom_feed_nearby")
        XCTAssertEqual(json["p_viewer_lat"] as? Double, 35.681236)
        XCTAssertEqual(json["p_viewer_lng"] as? Double, 139.767125)
        XCTAssertEqual(json["p_radius_m"] as? Int, 1_000)
    }

    func testBuildsGroomPostCreateRequest() throws {
        let client = SupabaseGroomClient(configuration: configuration)
        let authorID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

        let request = try client.makeCreatePostRequest(
            GroomPostCreateInput(
                authorID: authorID,
                imageData: Data([0xff, 0xd8, 0xff]),
                imageContentType: "image/jpeg",
                caption: " 物販列メモ ",
                latitude: 35.681236,
                longitude: 139.767125
            ),
            imagePath: "00000000-0000-0000-0000-000000000001/test.jpg"
        )
        let body = try XCTUnwrap(request.httpBody)
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let payload = try XCTUnwrap(rows.first)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/groom_posts?select=id,user_id,image_url,image_path,published_at,created_at,origin_lat,origin_lng")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertEqual(payload["user_id"] as? String, authorID.uuidString.lowercased())
        XCTAssertEqual(payload["status"] as? String, "published")
        XCTAssertEqual(payload["audience_scope"] as? String, "encountered_people")
        XCTAssertEqual(payload["image_path"] as? String, "00000000-0000-0000-0000-000000000001/test.jpg")
        XCTAssertEqual(payload["image_url"] as? String, "00000000-0000-0000-0000-000000000001/test.jpg")
        XCTAssertEqual(payload["caption"] as? String, "物販列メモ")
        XCTAssertEqual(payload["origin_lat"] as? Double, 35.681236)
        XCTAssertEqual(payload["origin_lng"] as? Double, 139.767125)
    }

    func testBuildsGroomViewAndReactionRequests() throws {
        let client = SupabaseGroomClient(configuration: configuration)
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let postID = UUID(uuidString: "00000000-0000-0000-0000-000000000501")!

        let viewRequest = try client.makeMarkViewedRequest(userID: userID, postID: postID)
        let viewBody = try XCTUnwrap(viewRequest.httpBody)
        let viewRows = try XCTUnwrap(JSONSerialization.jsonObject(with: viewBody) as? [[String: Any]])

        XCTAssertEqual(viewRequest.httpMethod, "POST")
        XCTAssertEqual(viewRequest.url?.absoluteString, "https://example.supabase.co/rest/v1/groom_views?select=*&on_conflict=groom_post_id,user_id")
        XCTAssertEqual(viewRequest.value(forHTTPHeaderField: "Prefer"), "resolution=merge-duplicates,return=representation")
        XCTAssertEqual(viewRows.first?["groom_post_id"] as? String, postID.uuidString.lowercased())
        XCTAssertEqual(viewRows.first?["user_id"] as? String, userID.uuidString.lowercased())

        let likeRequest = try client.makeSetLikedRequest(userID: userID, postID: postID, isLiked: true)
        let likeBody = try XCTUnwrap(likeRequest.httpBody)
        let likeRows = try XCTUnwrap(JSONSerialization.jsonObject(with: likeBody) as? [[String: Any]])

        XCTAssertEqual(likeRequest.url?.absoluteString, "https://example.supabase.co/rest/v1/groom_reactions?select=*&on_conflict=groom_post_id,user_id,reaction_type")
        XCTAssertEqual(likeRows.first?["reaction_type"] as? String, "like")

        let unlikeRequest = try client.makeSetLikedRequest(userID: userID, postID: postID, isLiked: false)

        XCTAssertEqual(unlikeRequest.httpMethod, "DELETE")
        XCTAssertEqual(unlikeRequest.url?.absoluteString, "https://example.supabase.co/rest/v1/groom_reactions?groom_post_id=eq.00000000-0000-0000-0000-000000000501&user_id=eq.00000000-0000-0000-0000-000000000001&reaction_type=eq.like")
    }

    func testBuildsGroomReplyAndNotificationRequests() throws {
        let client = SupabaseGroomClient(configuration: configuration)
        let senderID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let recipientID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let postID = UUID(uuidString: "00000000-0000-0000-0000-000000000501")!
        let replyID = UUID(uuidString: "00000000-0000-0000-0000-000000000701")!

        let request = try client.makeSendReplyRequest(
            GroomReplyCreateInput(
                groomPostID: postID,
                senderID: senderID,
                recipientID: recipientID,
                body: " かわいいです ",
                groomImageURL: URL(string: "https://example.com/groom.jpg")
            )
        )
        let body = try XCTUnwrap(request.httpBody)
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let payload = try XCTUnwrap(rows.first)
        let snapshot = try XCTUnwrap(payload["groom_snapshot"] as? [String: Any])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/groom_replies?select=id,groom_post_id,sender_id,recipient_id,body,groom_snapshot,read_at,created_at")
        XCTAssertEqual(payload["body"] as? String, "かわいいです")
        XCTAssertEqual(payload["groom_post_id"] as? String, postID.uuidString.lowercased())
        XCTAssertEqual(payload["sender_id"] as? String, senderID.uuidString.lowercased())
        XCTAssertEqual(payload["recipient_id"] as? String, recipientID.uuidString.lowercased())
        XCTAssertEqual(snapshot["image_url"] as? String, "https://example.com/groom.jpg")

        let notificationRequest = try client.makeReplyNotificationRequest(
            reply: GroomReply(
                id: replyID,
                groomPostID: postID,
                senderID: senderID,
                recipientID: recipientID,
                body: "かわいいです",
                groomImageURL: URL(string: "https://example.com/groom.jpg")
            )
        )
        let notificationBody = try XCTUnwrap(notificationRequest.httpBody)
        let notificationRows = try XCTUnwrap(JSONSerialization.jsonObject(with: notificationBody) as? [[String: Any]])
        let notificationPayload = try XCTUnwrap(notificationRows.first)

        XCTAssertEqual(notificationRequest.url?.absoluteString, "https://example.supabase.co/rest/v1/notifications?select=id")
        XCTAssertEqual(notificationPayload["kind"] as? String, "groom_reply")
        XCTAssertEqual(notificationPayload["groom_reply_id"] as? String, replyID.uuidString.lowercased())
        XCTAssertEqual(notificationPayload["user_id"] as? String, recipientID.uuidString.lowercased())
        XCTAssertEqual(notificationPayload["title"] as? String, "グルームに返信が届きました")
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
