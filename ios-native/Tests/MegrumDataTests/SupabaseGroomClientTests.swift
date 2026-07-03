import Foundation
import MegrumCore
@testable import MegrumData
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

    func testBuildsNearbyGroomRPCRequestWithNullLocationAndMinimumRadius() throws {
        let client = SupabaseGroomClient(configuration: configuration)

        let request = try client.makeLoadNearbyGroomsRequest(
            latitude: nil,
            longitude: nil,
            radiusMeters: 20
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertTrue(json["p_viewer_lat"] is NSNull)
        XCTAssertTrue(json["p_viewer_lng"] is NSNull)
        XCTAssertEqual(json["p_radius_m"] as? Int, 100)
    }

    func testBuildsGroomMapRPCRequestWithWiderRadius() throws {
        let client = SupabaseGroomClient(configuration: configuration)

        let request = try client.makeLoadGroomMapPostsRequest(
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
        XCTAssertEqual(json["p_radius_m"] as? Int, 2_500)
    }

    func testBuildsGroomMapRPCRequestWithMapMaximumRadius() throws {
        let client = SupabaseGroomClient(configuration: configuration)

        let request = try client.makeLoadGroomMapPostsRequest(
            latitude: 35.681236,
            longitude: 139.767125,
            radiusMeters: 12_000
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(json["p_radius_m"] as? Int, 3_000)
    }

    func testBuildsDeleteGroomPostRequestAsHiddenStatusPatch() throws {
        let client = SupabaseGroomClient(configuration: configuration)
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let postID = UUID(uuidString: "00000000-0000-0000-0000-000000000501")!

        let request = try client.makeDeletePostRequest(userID: userID, postID: postID)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertEqual(
            request.url?.absoluteString,
            "https://example.supabase.co/rest/v1/groom_posts?select=id&id=eq.\(postID.uuidString.lowercased())&user_id=eq.\(userID.uuidString.lowercased())"
        )
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertEqual(json["status"] as? String, "hidden")
    }

    func testLoadNearbyGroomsKeepsPathOnlyRowWhenSignedURLFails() throws {
        let imagePath = "00000000-0000-0000-0000-000000000001/path-only.jpg"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [GroomMockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = SupabaseGroomClient(configuration: self.configuration, session: session)

        GroomMockURLProtocol.requestHandler = { request in
            guard let url = request.url else {
                throw GroomMockError.missingURL
            }

            switch url.path {
            case "/rest/v1/rpc/list_groom_feed_nearby":
                let data = Data("""
                [
                  {
                    "id": "00000000-0000-0000-0000-000000000501",
                    "user_id": "00000000-0000-0000-0000-000000000001",
                    "image_url": "\(imagePath)",
                    "image_path": "\(imagePath)",
                    "published_at": "2026-05-31T00:00:00Z",
                    "created_at": "2026-05-31T00:00:00Z",
                    "origin_lat": 35.681236,
                    "origin_lng": 139.767125,
                    "like_count": 7
                  }
                ]
                """.utf8)
                return (GroomMockURLProtocol.response(for: url, statusCode: 200), data)

            case "/storage/v1/object/sign/groom-posts/\(imagePath)":
                return (GroomMockURLProtocol.response(for: url, statusCode: 500), Data(#"{"message":"sign failed"}"#.utf8))

            default:
                throw GroomMockError.unexpectedRequest(url.absoluteString)
            }
        }
        defer {
            GroomMockURLProtocol.requestHandler = nil
        }

        let posts = try waitForAsyncResult {
            try await client.loadNearbyGrooms(latitude: 35.681236, longitude: 139.767125)
        }

        XCTAssertEqual(posts.count, 1)
        XCTAssertEqual(posts.first?.imageURL.scheme, nil)
        XCTAssertEqual(posts.first?.imageURL.relativeString, imagePath)
        XCTAssertEqual(posts.first?.latitude, 35.681236)
        XCTAssertEqual(posts.first?.longitude, 139.767125)
        XCTAssertEqual(posts.first?.likeCount, 7)
    }

    func testLoadNearbyGroomsFiltersUnexpectedFarRowsClientSide() throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [GroomMockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = SupabaseGroomClient(configuration: self.configuration, session: session)

        GroomMockURLProtocol.requestHandler = { request in
            guard let url = request.url else {
                throw GroomMockError.missingURL
            }

            guard url.path == "/rest/v1/rpc/list_groom_feed_nearby" else {
                throw GroomMockError.unexpectedRequest(url.absoluteString)
            }
            let data = Data("""
            [
              {
                "id": "00000000-0000-0000-0000-000000000501",
                "user_id": "00000000-0000-0000-0000-000000000001",
                "image_url": "https://example.com/near.jpg",
                "image_path": null,
                "published_at": "2026-05-31T00:00:00Z",
                "created_at": "2026-05-31T00:00:00Z",
                "origin_lat": 35.681236,
                "origin_lng": 139.767125
              },
              {
                "id": "00000000-0000-0000-0000-000000000502",
                "user_id": "00000000-0000-0000-0000-000000000002",
                "image_url": "https://example.com/far.jpg",
                "image_path": null,
                "published_at": "2026-05-31T00:00:00Z",
                "created_at": "2026-05-31T00:00:00Z",
                "origin_lat": 35.701236,
                "origin_lng": 139.767125
              }
            ]
            """.utf8)
            return (GroomMockURLProtocol.response(for: url, statusCode: 200), data)
        }
        defer {
            GroomMockURLProtocol.requestHandler = nil
        }

        let posts = try waitForAsyncResult {
            try await client.loadNearbyGrooms(latitude: 35.681236, longitude: 139.767125)
        }

        XCTAssertEqual(posts.map(\.imageURL.absoluteString), ["https://example.com/near.jpg"])
    }

    func testLoadNearbyGroomsReusesCachedSignedURLForRepeatedPath() throws {
        let imagePath = "00000000-0000-0000-0000-000000000001/cached.jpg"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [GroomMockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = SupabaseGroomClient(configuration: self.configuration, session: session)
        var signRequestCount = 0

        GroomMockURLProtocol.requestHandler = { request in
            guard let url = request.url else {
                throw GroomMockError.missingURL
            }

            switch url.path {
            case "/rest/v1/rpc/list_groom_feed_nearby":
                let data = Data("""
                [
                  {
                    "id": "00000000-0000-0000-0000-000000000501",
                    "user_id": "00000000-0000-0000-0000-000000000001",
                    "image_url": "\(imagePath)",
                    "image_path": "\(imagePath)",
                    "published_at": "2026-05-31T00:00:00Z",
                    "created_at": "2026-05-31T00:00:00Z",
                    "origin_lat": 35.681236,
                    "origin_lng": 139.767125
                  }
                ]
                """.utf8)
                return (GroomMockURLProtocol.response(for: url, statusCode: 200), data)

            case "/storage/v1/object/sign/groom-posts/\(imagePath)":
                signRequestCount += 1
                let data = Data(#"{"signedURL":"https://cdn.example.com/cached.jpg"}"#.utf8)
                return (GroomMockURLProtocol.response(for: url, statusCode: 200), data)

            default:
                throw GroomMockError.unexpectedRequest(url.absoluteString)
            }
        }
        defer {
            GroomMockURLProtocol.requestHandler = nil
        }

        let first = try waitForAsyncResult {
            try await client.loadNearbyGrooms(latitude: 35.681236, longitude: 139.767125)
        }
        let second = try waitForAsyncResult {
            try await client.loadNearbyGrooms(latitude: 35.681236, longitude: 139.767125)
        }

        XCTAssertEqual(first.first?.imageURL.absoluteString, "https://cdn.example.com/cached.jpg")
        XCTAssertEqual(second.first?.imageURL.absoluteString, "https://cdn.example.com/cached.jpg")
        XCTAssertEqual(signRequestCount, 1)
    }

    func testBuildsGroomPostCreateRequest() throws {
        let client = SupabaseGroomClient(configuration: configuration)
        let authorID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000000011")!
        let characterID = UUID(uuidString: "00000000-0000-0000-0000-000000000012")!

        let request = try client.makeCreatePostRequest(
            GroomPostCreateInput(
                authorID: authorID,
                imageData: Data([0xff, 0xd8, 0xff]),
                imageContentType: "image/jpeg",
                caption: " 物販列メモ ",
                latitude: 35.681236,
                longitude: 139.767125,
                groupID: groupID,
                characterID: characterID,
                seriesName: " 2026 LIVE "
            ),
            imagePath: "00000000-0000-0000-0000-000000000001/test.jpg"
        )
        let body = try XCTUnwrap(request.httpBody)
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let payload = try XCTUnwrap(rows.first)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/groom_posts?select=id,user_id,image_url,image_path,published_at,expires_at,created_at,origin_lat,origin_lng,group_id,character_id,series_name")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertEqual(payload["user_id"] as? String, authorID.uuidString.lowercased())
        XCTAssertEqual(payload["status"] as? String, "published")
        XCTAssertEqual(payload["audience_scope"] as? String, "encountered_people")
        XCTAssertEqual(payload["image_path"] as? String, "00000000-0000-0000-0000-000000000001/test.jpg")
        XCTAssertEqual(payload["image_url"] as? String, "00000000-0000-0000-0000-000000000001/test.jpg")
        XCTAssertEqual(payload["caption"] as? String, "物販列メモ")
        XCTAssertEqual(payload["origin_lat"] as? Double, 35.681236)
        XCTAssertEqual(payload["origin_lng"] as? Double, 139.767125)
        XCTAssertEqual(payload["group_id"] as? String, groupID.uuidString.lowercased())
        XCTAssertEqual(payload["character_id"] as? String, characterID.uuidString.lowercased())
        XCTAssertEqual(payload["series_name"] as? String, "2026 LIVE")
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
        let likeJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: likeBody) as? [String: Any])

        XCTAssertEqual(likeRequest.httpMethod, "POST")
        XCTAssertEqual(likeRequest.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/set_groom_like_for_viewer")
        XCTAssertEqual(likeJSON["p_post_id"] as? String, postID.uuidString.uppercased())
        XCTAssertEqual(likeJSON["p_is_liked"] as? Bool, true)

        let unlikeRequest = try client.makeSetLikedRequest(userID: userID, postID: postID, isLiked: false)
        let unlikeBody = try XCTUnwrap(unlikeRequest.httpBody)
        let unlikeJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: unlikeBody) as? [String: Any])

        XCTAssertEqual(unlikeRequest.httpMethod, "POST")
        XCTAssertEqual(unlikeRequest.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/set_groom_like_for_viewer")
        XCTAssertEqual(unlikeJSON["p_post_id"] as? String, postID.uuidString.uppercased())
        XCTAssertEqual(unlikeJSON["p_is_liked"] as? Bool, false)
    }

    func testBuildsGroomReportAndBlockRequests() throws {
        let client = SupabaseGroomClient(configuration: configuration)
        let reporterID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let reportedUserID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let postID = UUID(uuidString: "00000000-0000-0000-0000-000000000501")!

        let reportRequest = try client.makeReportPostRequest(
            reporterID: reporterID,
            input: GroomReportCreateInput(
                groomPostID: postID,
                reportedUserID: reportedUserID,
                reason: .privacy,
                note: "   "
            )
        )
        let reportBody = try XCTUnwrap(reportRequest.httpBody)
        let reportRows = try XCTUnwrap(JSONSerialization.jsonObject(with: reportBody) as? [[String: Any]])
        let reportJSON = try XCTUnwrap(reportRows.first)

        XCTAssertEqual(reportRequest.httpMethod, "POST")
        XCTAssertEqual(reportRequest.url?.absoluteString, "https://example.supabase.co/rest/v1/groom_reports?select=id,groom_post_id,reported_user_id,reason,status,created_at")
        XCTAssertEqual(reportJSON["groom_post_id"] as? String, postID.uuidString.lowercased())
        XCTAssertEqual(reportJSON["reporter_id"] as? String, reporterID.uuidString.lowercased())
        XCTAssertEqual(reportJSON["reported_user_id"] as? String, reportedUserID.uuidString.lowercased())
        XCTAssertEqual(reportJSON["reason"] as? String, "privacy")
        XCTAssertNil(reportJSON["note"])

        let blockRequest = try client.makeBlockUserRequest(blockerID: reporterID, blockedID: reportedUserID)
        let blockBody = try XCTUnwrap(blockRequest.httpBody)
        let blockRows = try XCTUnwrap(JSONSerialization.jsonObject(with: blockBody) as? [[String: Any]])
        let blockJSON = try XCTUnwrap(blockRows.first)

        XCTAssertEqual(blockRequest.httpMethod, "POST")
        XCTAssertEqual(blockRequest.url?.absoluteString, "https://example.supabase.co/rest/v1/groom_user_blocks?select=blocked_id&on_conflict=blocker_id,blocked_id")
        XCTAssertEqual(blockJSON["blocker_id"] as? String, reporterID.uuidString.lowercased())
        XCTAssertEqual(blockJSON["blocked_id"] as? String, reportedUserID.uuidString.lowercased())
    }

    func testGroomRowsDecodeIDFieldsFromSupabaseSnakeCase() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let viewRows = try decoder.decode([GroomViewRow].self, from: Data("""
        [
          {
            "groom_post_id": "00000000-0000-0000-0000-000000000501",
            "user_id": "00000000-0000-0000-0000-000000000001"
          }
        ]
        """.utf8))
        let blockRows = try decoder.decode([GroomBlockRow].self, from: Data("""
        [
          {
            "blocked_id": "00000000-0000-0000-0000-000000000002"
          }
        ]
        """.utf8))
        let reactionRows = try decoder.decode([GroomReactionRow].self, from: Data("""
        [
          {
            "groom_post_id": "00000000-0000-0000-0000-000000000501",
            "user_id": "00000000-0000-0000-0000-000000000001",
            "reaction_type": "like",
            "created_at": "2026-06-27T00:00:00Z"
          }
        ]
        """.utf8))
        let replyRows = try decoder.decode([GroomReplyRow].self, from: Data("""
        [
          {
            "id": "00000000-0000-0000-0000-000000000701",
            "groom_post_id": "00000000-0000-0000-0000-000000000501",
            "sender_id": "00000000-0000-0000-0000-000000000001",
            "recipient_id": "00000000-0000-0000-0000-000000000002",
            "body": "かわいいです",
            "groom_snapshot": {
              "image_url": "https://example.com/groom.jpg",
              "image_path": "groom/0001.jpg"
            },
            "read_at": null,
            "created_at": "2026-06-27T00:00:00Z"
          }
        ]
        """.utf8))
        let reportRows = try decoder.decode([GroomReportRow].self, from: Data("""
        [
          {
            "id": "00000000-0000-0000-0000-000000000901",
            "groom_post_id": "00000000-0000-0000-0000-000000000501",
            "reported_user_id": "00000000-0000-0000-0000-000000000002",
            "reason": "privacy",
            "status": "open",
            "created_at": "2026-06-27T00:00:00Z"
          }
        ]
        """.utf8))

        XCTAssertEqual(viewRows.first?.groomPostID, UUID(uuidString: "00000000-0000-0000-0000-000000000501"))
        XCTAssertEqual(viewRows.first?.userID, UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        XCTAssertEqual(blockRows.first?.blockedID, UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
        XCTAssertEqual(reactionRows.first?.groomPostID, UUID(uuidString: "00000000-0000-0000-0000-000000000501"))
        XCTAssertEqual(reactionRows.first?.userID, UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        XCTAssertEqual(replyRows.first?.groomPostID, UUID(uuidString: "00000000-0000-0000-0000-000000000501"))
        XCTAssertEqual(replyRows.first?.senderID, UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        XCTAssertEqual(replyRows.first?.recipientID, UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
        XCTAssertEqual(replyRows.first?.groomSnapshot?.imagePath, "groom/0001.jpg")
        XCTAssertEqual(reportRows.first?.groomPostID, UUID(uuidString: "00000000-0000-0000-0000-000000000501"))
        XCTAssertEqual(reportRows.first?.reportedUserID, UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
    }

    func testBuildsGroomReplyAndMeguriMessageRequests() throws {
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

        let meguriMessageRequest = try client.makeGroomReplyMeguriMessageRequest(
            reply: GroomReply(
                id: replyID,
                groomPostID: postID,
                senderID: senderID,
                recipientID: recipientID,
                body: "かわいいです",
                groomImageURL: URL(string: "https://example.com/groom.jpg")
            )
        )
        let meguriMessageBody = try XCTUnwrap(meguriMessageRequest.httpBody)
        let meguriMessageRows = try XCTUnwrap(JSONSerialization.jsonObject(with: meguriMessageBody) as? [[String: Any]])
        let meguriMessagePayload = try XCTUnwrap(meguriMessageRows.first)

        XCTAssertEqual(meguriMessageRequest.url?.absoluteString, "https://example.supabase.co/rest/v1/meguri_messages?select=id")
        XCTAssertEqual(meguriMessagePayload["sender_id"] as? String, senderID.uuidString.lowercased())
        XCTAssertEqual(meguriMessagePayload["recipient_id"] as? String, recipientID.uuidString.lowercased())
        XCTAssertEqual(meguriMessagePayload["source_groom_reply_id"] as? String, replyID.uuidString.lowercased())
        XCTAssertEqual(meguriMessagePayload["source_groom_post_id"] as? String, postID.uuidString.lowercased())
        XCTAssertEqual(meguriMessagePayload["source_groom_owner_id"] as? String, recipientID.uuidString.lowercased())
        XCTAssertEqual(meguriMessagePayload["source_groom_image_url"] as? String, "https://example.com/groom.jpg")
        XCTAssertEqual(meguriMessagePayload["message_type"] as? String, "text")
        XCTAssertEqual(meguriMessagePayload["body"] as? String, "かわいいです")
    }

    func testBuildsGroomArchiveAndEngagementRequests() throws {
        let client = SupabaseGroomClient(configuration: configuration)
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let firstPostID = UUID(uuidString: "00000000-0000-0000-0000-000000000501")!
        let secondPostID = UUID(uuidString: "00000000-0000-0000-0000-000000000502")!

        let archiveRequest = try client.makeLoadOwnGroomArchiveRequest(userID: userID, limit: 42)
        XCTAssertEqual(
            archiveRequest.url?.absoluteString,
            "https://example.supabase.co/rest/v1/groom_posts?select=id,user_id,image_url,image_path,published_at,expires_at,created_at,origin_lat,origin_lng,group_id,character_id,series_name&user_id=eq.00000000-0000-0000-0000-000000000001&status=eq.published&order=published_at.desc.nullslast,created_at.desc&limit=42"
        )

        let reactionsRequest = try client.makeLoadReactionsRequest(postIDs: [secondPostID, firstPostID])
        XCTAssertEqual(
            reactionsRequest.url?.absoluteString,
            "https://example.supabase.co/rest/v1/groom_reactions?select=groom_post_id,user_id,reaction_type,created_at&groom_post_id=in.(00000000-0000-0000-0000-000000000501,00000000-0000-0000-0000-000000000502)&order=created_at.desc&reaction_type=eq.like"
        )

        let repliesRequest = try client.makeLoadRepliesRequest(postIDs: [secondPostID, firstPostID])
        XCTAssertEqual(
            repliesRequest.url?.absoluteString,
            "https://example.supabase.co/rest/v1/groom_replies?select=id,groom_post_id,sender_id,recipient_id,body,groom_snapshot,read_at,created_at&groom_post_id=in.(00000000-0000-0000-0000-000000000501,00000000-0000-0000-0000-000000000502)&order=created_at.desc"
        )
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}

private func waitForAsyncResult<Value: Sendable>(
    _ operation: @escaping @Sendable () async throws -> Value,
    timeout: TimeInterval = 3
) throws -> Value {
    let semaphore = DispatchSemaphore(value: 0)
    let resultBox = GroomAsyncResultBox<Value>()

    Task {
        do {
            resultBox.store(.success(try await operation()))
        } catch {
            resultBox.store(.failure(error))
        }
        semaphore.signal()
    }

    XCTAssertEqual(semaphore.wait(timeout: .now() + timeout), .success)
    return try XCTUnwrap(resultBox.result).get()
}

private final class GroomAsyncResultBox<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var storedResult: Result<Value, Error>?

    var result: Result<Value, Error>? {
        lock.lock()
        defer { lock.unlock() }
        return storedResult
    }

    func store(_ result: Result<Value, Error>) {
        lock.lock()
        storedResult = result
        lock.unlock()
    }
}

private enum GroomMockError: Error {
    case missingHandler
    case missingURL
    case unexpectedRequest(String)
}

private final class GroomMockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: GroomMockError.missingHandler)
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    static func response(for url: URL, statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
    }
}
