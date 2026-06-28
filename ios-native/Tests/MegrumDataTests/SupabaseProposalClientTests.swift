import Foundation
import MegrumCore
@testable import MegrumData
import XCTest

final class SupabaseProposalClientTests: XCTestCase {
    func testBuildsLoadProposalsRequest() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let viewerID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let request = try client.makeLoadProposalsRequest(viewerID: viewerID)
        let url = try XCTUnwrap(request.url?.absoluteString)
        let queryItems = URLComponents(string: url)?.queryItems ?? []

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/proposals?select=id,sender_id,receiver_id,listing_id,status,exchange_method,sender_mailing_address,receiver_mailing_address,sender_payment_settings,receiver_payment_settings,sender_have_ids,receiver_have_ids,cash_offer,cash_amount,cash_amount_side,option_tags"))
        XCTAssertTrue(url.contains("sender_mailing_address"))
        XCTAssertTrue(url.contains("receiver_mailing_address"))
        XCTAssertTrue(url.contains("sender_payment_settings"))
        XCTAssertTrue(url.contains("receiver_payment_settings"))
        XCTAssertTrue(url.contains("agreed_by_sender"))
        XCTAssertTrue(url.contains("agreed_by_receiver"))
        XCTAssertTrue(url.contains("evidence_photo_url"))
        XCTAssertTrue(url.contains("approved_by_sender"))
        XCTAssertTrue(url.contains("completed_at"))
        XCTAssertTrue(url.contains("updated_at"))
        XCTAssertTrue(url.contains("or=(sender_id.eq.11111111-1111-1111-1111-111111111111,receiver_id.eq.11111111-1111-1111-1111-111111111111)"))
        XCTAssertEqual(
            queryItems.first { $0.name == "order" }?.value,
            "updated_at.desc.nullslast,created_at.desc"
        )
    }

    func testProposalLegacySelectOmitsPaymentSnapshotsForUnmigratedDatabases() {
        let columns = ProposalRow.legacySelect.split(separator: ",").map(String.init)

        XCTAssertTrue(columns.contains("sender_mailing_address"))
        XCTAssertTrue(columns.contains("receiver_mailing_address"))
        XCTAssertTrue(columns.contains("sender_have_ids"))
        XCTAssertFalse(columns.contains("sender_payment_settings"))
        XCTAssertFalse(columns.contains("receiver_payment_settings"))
    }

    func testBuildsLoadEvidencePhotosRequest() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let proposalID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

        let request = try client.makeLoadEvidencePhotosRequest(proposalID: proposalID)
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/proposal_evidence_photos?select=id,proposal_id,photo_url,position,taken_at,taken_by,approved_by_sender,approved_by_receiver"))
        XCTAssertTrue(url.contains("proposal_id=eq.33333333-3333-3333-3333-333333333333"))
        XCTAssertTrue(url.contains("order=position.asc"))
    }

    func testLoadEvidencePhotosRefreshesLegacyObjectSignPhotoURL() async throws {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [ProposalEvidenceMockURLProtocol.self]
        let session = URLSession(configuration: sessionConfiguration)
        let client = SupabaseProposalClient(configuration: configuration, session: session)
        let proposalID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

        ProposalEvidenceMockURLProtocol.requestHandler = { request in
            guard let url = request.url else {
                throw ProposalEvidenceMockError.missingURL
            }
            switch url.path {
            case "/rest/v1/proposal_evidence_photos":
                let data = Data("""
                [
                  {
                    "id": "44444444-4444-4444-4444-444444444444",
                    "proposal_id": "\(proposalID.uuidString.lowercased())",
                    "photo_url": "https://example.supabase.co/object/sign/chat-photos/proposal/evidence.jpg?token=old",
                    "position": 1,
                    "taken_at": "2026-06-26T00:00:00Z",
                    "taken_by": "11111111-1111-1111-1111-111111111111",
                    "approved_by_sender": true,
                    "approved_by_receiver": false
                  }
                ]
                """.utf8)
                return (ProposalEvidenceMockURLProtocol.response(for: url, statusCode: 200), data)

            case "/storage/v1/object/sign/chat-photos/proposal/evidence.jpg":
                let data = Data(#"{"signedURL":"/object/sign/chat-photos/proposal/evidence.jpg?token=fresh"}"#.utf8)
                return (ProposalEvidenceMockURLProtocol.response(for: url, statusCode: 200), data)

            default:
                throw ProposalEvidenceMockError.unexpectedRequest(url.absoluteString)
            }
        }
        defer {
            ProposalEvidenceMockURLProtocol.requestHandler = nil
        }

        let photos = try await client.loadEvidencePhotos(proposalID: proposalID)

        XCTAssertEqual(photos.count, 1)
        XCTAssertEqual(
            photos.first?.photoURL.absoluteString,
            "https://example.supabase.co/storage/v1/object/sign/chat-photos/proposal/evidence.jpg?token=fresh"
        )
    }

    func testLoadEvidencePhotosRefreshesAuthenticatedObjectPhotoURL() async throws {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [ProposalEvidenceMockURLProtocol.self]
        let session = URLSession(configuration: sessionConfiguration)
        let client = SupabaseProposalClient(configuration: configuration, session: session)
        let proposalID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

        ProposalEvidenceMockURLProtocol.requestHandler = { request in
            guard let url = request.url else {
                throw ProposalEvidenceMockError.missingURL
            }
            switch url.path {
            case "/rest/v1/proposal_evidence_photos":
                let data = Data("""
                [
                  {
                    "id": "44444444-4444-4444-4444-444444444444",
                    "proposal_id": "\(proposalID.uuidString.lowercased())",
                    "photo_url": "https://example.supabase.co/storage/v1/object/authenticated/chat-photos/proposal/evidence.jpg",
                    "position": 1,
                    "taken_at": "2026-06-26T00:00:00Z",
                    "taken_by": "11111111-1111-1111-1111-111111111111",
                    "approved_by_sender": true,
                    "approved_by_receiver": false
                  }
                ]
                """.utf8)
                return (ProposalEvidenceMockURLProtocol.response(for: url, statusCode: 200), data)

            case "/storage/v1/object/sign/chat-photos/proposal/evidence.jpg":
                let data = Data(#"{"signedURL":"/object/sign/chat-photos/proposal/evidence.jpg?token=fresh"}"#.utf8)
                return (ProposalEvidenceMockURLProtocol.response(for: url, statusCode: 200), data)

            default:
                throw ProposalEvidenceMockError.unexpectedRequest(url.absoluteString)
            }
        }
        defer {
            ProposalEvidenceMockURLProtocol.requestHandler = nil
        }

        let photos = try await client.loadEvidencePhotos(proposalID: proposalID)

        XCTAssertEqual(photos.count, 1)
        XCTAssertEqual(
            photos.first?.photoURL.absoluteString,
            "https://example.supabase.co/storage/v1/object/sign/chat-photos/proposal/evidence.jpg?token=fresh"
        )
    }

    func testAddEvidencePhotoRetriesLegacyInsertWhenApprovalColumnsAreMissing() async throws {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [ProposalEvidenceMockURLProtocol.self]
        let session = URLSession(configuration: sessionConfiguration)
        let client = SupabaseProposalClient(configuration: configuration, session: session)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let proposalID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        var evidenceInsertAttempts = 0
        var legacyInsertBody: String?

        ProposalEvidenceMockURLProtocol.requestHandler = { request in
            guard let url = request.url else {
                throw ProposalEvidenceMockError.missingURL
            }
            let body = Self.requestBodyString(from: request)
            switch (request.httpMethod, url.path) {
            case ("GET", "/rest/v1/proposals"):
                let data = Data("""
                [
                  {
                    "id": "\(proposalID.uuidString.lowercased())",
                    "sender_id": "\(senderID.uuidString.lowercased())",
                    "receiver_id": "\(receiverID.uuidString.lowercased())",
                    "status": "agreed",
                    "exchange_method": "hand",
                    "sender_have_ids": [],
                    "receiver_have_ids": [],
                    "agreed_by_sender": true,
                    "agreed_by_receiver": true,
                    "approved_by_sender": false,
                    "approved_by_receiver": false,
                    "created_at": "2026-06-26T00:00:00Z"
                  }
                ]
                """.utf8)
                return (ProposalEvidenceMockURLProtocol.response(for: url, statusCode: 200), data)

            case ("POST", let path) where path.hasPrefix("/storage/v1/object/chat-photos/"):
                return (ProposalEvidenceMockURLProtocol.response(for: url, statusCode: 200), Data("{}".utf8))

            case ("POST", let path) where path.hasPrefix("/storage/v1/object/sign/chat-photos/"):
                let data = Data(#"{"signedURL":"/object/sign/chat-photos/33333333-3333-3333-3333-333333333333/evidence.jpg?token=fresh"}"#.utf8)
                return (ProposalEvidenceMockURLProtocol.response(for: url, statusCode: 200), data)

            case ("GET", "/rest/v1/proposal_evidence_photos"):
                return (ProposalEvidenceMockURLProtocol.response(for: url, statusCode: 200), Data("[]".utf8))

            case ("POST", "/rest/v1/proposal_evidence_photos"):
                evidenceInsertAttempts += 1
                if evidenceInsertAttempts == 1 {
                    XCTAssertTrue(body.contains("approved_by_sender"))
                    return (
                        ProposalEvidenceMockURLProtocol.response(for: url, statusCode: 400),
                        Data(#"{"message":"column approved_by_sender does not exist"}"#.utf8)
                    )
                }
                legacyInsertBody = body
                let data = Data(#"[{"id":"44444444-4444-4444-4444-444444444444"}]"#.utf8)
                return (ProposalEvidenceMockURLProtocol.response(for: url, statusCode: 201), data)

            case ("PATCH", "/rest/v1/proposals"):
                return (
                    ProposalEvidenceMockURLProtocol.response(for: url, statusCode: 400),
                    Data(#"{"message":"proposal mirror columns are unavailable"}"#.utf8)
                )

            case ("POST", "/rest/v1/messages"):
                let data = Data(#"[{"id":"55555555-5555-5555-5555-555555555555"}]"#.utf8)
                return (ProposalEvidenceMockURLProtocol.response(for: url, statusCode: 201), data)

            default:
                throw ProposalEvidenceMockError.unexpectedRequest(url.absoluteString)
            }
        }
        defer {
            ProposalEvidenceMockURLProtocol.requestHandler = nil
        }

        let proposal = try await client.addEvidencePhoto(
            userID: senderID,
            input: TradeEvidenceCreateInput(
                proposalID: proposalID,
                imageData: Data([0xFF, 0xD8, 0xFF, 0x00]),
                imageContentType: "image/jpeg",
                systemMessageBody: "証跡をアップロードしました"
            )
        )

        XCTAssertEqual(evidenceInsertAttempts, 2)
        XCTAssertFalse(legacyInsertBody?.contains("approved_by_sender") ?? true)
        XCTAssertFalse(legacyInsertBody?.contains("approved_by_receiver") ?? true)
        XCTAssertEqual(proposal.evidencePhotoURL?.host, "example.supabase.co")
    }

    func testBuildsDeleteEvidencePhotoRequestScopedToUploader() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let photoID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

        let request = try client.makeDeleteEvidencePhotoRequest(
            userID: userID,
            proposalID: proposalID,
            photoID: photoID
        )
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "DELETE")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=minimal")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/proposal_evidence_photos?"))
        XCTAssertTrue(url.contains("id=eq.44444444-4444-4444-4444-444444444444"))
        XCTAssertTrue(url.contains("proposal_id=eq.33333333-3333-3333-3333-333333333333"))
        XCTAssertTrue(url.contains("taken_by=eq.11111111-1111-1111-1111-111111111111"))
    }

    func testBuildsCreateProposalRequest() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let senderGoodsID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let receiverGoodsID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let listingID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
        let input = ProposalCreateInput(
            receiverID: receiverID,
            senderGoodsIDs: [senderGoodsID],
            receiverGoodsIDs: [receiverGoodsID],
            exchangeMethod: .mail,
            conditionTags: ["即日発送"],
            message: "よろしくお願いします",
            listingID: listingID
        )

        let request = try client.makeCreateProposalRequest(
            senderID: senderID,
            input: input,
            now: Date(timeIntervalSince1970: 0)
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "resolution=merge-duplicates,return=representation")
        XCTAssertEqual(json.first?["sender_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(json.first?["receiver_id"] as? String, "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(json.first?["match_type"] as? String, "forward")
        XCTAssertEqual(json.first?["sender_have_ids"] as? [String], ["33333333-3333-3333-3333-333333333333"])
        XCTAssertEqual(json.first?["sender_have_qtys"] as? [Int], [1])
        XCTAssertEqual(json.first?["receiver_have_ids"] as? [String], ["44444444-4444-4444-4444-444444444444"])
        XCTAssertEqual(json.first?["receiver_have_qtys"] as? [Int], [1])
        XCTAssertEqual(json.first?["status"] as? String, "sent")
        XCTAssertEqual(json.first?["exchange_method"] as? String, "mail")
        XCTAssertEqual(json.first?["option_tags"] as? [String], ["即日発送"])
        XCTAssertEqual(json.first?["message"] as? String, "よろしくお願いします")
        XCTAssertEqual(json.first?["message_tone"] as? String, "standard")
        XCTAssertEqual(json.first?["last_action_at"] as? String, "1970-01-01T00:00:00.000Z")
        XCTAssertEqual(json.first?["expires_at"] as? String, "1970-01-08T00:00:00.000Z")
        XCTAssertEqual(json.first?["listing_id"] as? String, "55555555-5555-5555-5555-555555555555")
        XCTAssertEqual(json.first?["cash_offer"] as? Bool, false)
        XCTAssertNil(json.first?["cash_amount"])
        XCTAssertNil(json.first?["cash_amount_side"])
        XCTAssertEqual(json.first?["agreed_by_sender"] as? Bool, true)
    }

    func testBuildsReviseProposalRequestForExistingProposal() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let proposalID = UUID(uuidString: "99999999-9999-9999-9999-999999999999")!
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let senderGoodsID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let receiverGoodsID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let input = ProposalCreateInput(
            receiverID: receiverID,
            senderGoodsIDs: [senderGoodsID],
            receiverGoodsIDs: [receiverGoodsID],
            exchangeMethod: .mail,
            conditionTags: ["終演後OK"],
            message: "条件を変えました",
            status: .negotiating
        )

        let request = try client.makeReviseProposalRequest(
            userID: senderID,
            proposalID: proposalID,
            input: input,
            now: Date(timeIntervalSince1970: 0)
        )
        let url = try XCTUnwrap(request.url?.absoluteString)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertTrue(url.contains("id=eq.99999999-9999-9999-9999-999999999999"))
        XCTAssertTrue(url.contains("or=(sender_id.eq.11111111-1111-1111-1111-111111111111,receiver_id.eq.11111111-1111-1111-1111-111111111111)"))
        XCTAssertEqual(json["sender_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(json["receiver_id"] as? String, "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(json["status"] as? String, "negotiating")
        XCTAssertEqual(json["exchange_method"] as? String, "mail")
        XCTAssertEqual(json["option_tags"] as? [String], ["終演後OK"])
        XCTAssertEqual(json["message"] as? String, "条件を変えました")
        XCTAssertEqual(json["agreed_by_sender"] as? Bool, true)
        XCTAssertEqual(json["agreed_by_receiver"] as? Bool, false)
        XCTAssertEqual(json["updated_at"] as? String, "1970-01-01T00:00:00.000Z")
    }

    func testBuildsCreateCashProposalRequest() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let receiverGoodsID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let input = ProposalCreateInput(
            receiverID: receiverID,
            senderGoodsIDs: [],
            receiverGoodsIDs: [receiverGoodsID],
            exchangeMethod: .mail,
            cashAmount: 1_500
        )

        let request = try client.makeCreateProposalRequest(
            senderID: senderID,
            input: input,
            now: Date(timeIntervalSince1970: 0)
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(json.first?["sender_have_ids"] as? [String], [])
        XCTAssertEqual(json.first?["sender_have_qtys"] as? [Int], [])
        XCTAssertEqual(json.first?["receiver_have_ids"] as? [String], ["44444444-4444-4444-4444-444444444444"])
        XCTAssertEqual(json.first?["cash_offer"] as? Bool, true)
        XCTAssertEqual(json.first?["cash_amount"] as? Int, 1_500)
        XCTAssertEqual(json.first?["cash_amount_side"] as? String, "sender")
    }

    func testBuildsCreateCashProposalRequestWhenReceiverSideIsCash() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let senderGoodsID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let input = ProposalCreateInput(
            receiverID: receiverID,
            senderGoodsIDs: [senderGoodsID],
            receiverGoodsIDs: [],
            exchangeMethod: .mail,
            cashAmount: 2_800
        )

        let request = try client.makeCreateProposalRequest(
            senderID: senderID,
            input: input,
            now: Date(timeIntervalSince1970: 0)
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(json.first?["sender_have_ids"] as? [String], ["33333333-3333-3333-3333-333333333333"])
        XCTAssertEqual(json.first?["sender_have_qtys"] as? [Int], [1])
        XCTAssertEqual(json.first?["receiver_have_ids"] as? [String], [])
        XCTAssertEqual(json.first?["receiver_have_qtys"] as? [Int], [])
        XCTAssertEqual(json.first?["cash_offer"] as? Bool, true)
        XCTAssertEqual(json.first?["cash_amount"] as? Int, 2_800)
        XCTAssertEqual(json.first?["cash_amount_side"] as? String, "receiver")
    }

    func testBuildsCreateProposalRequestWhenGoodsAndCashAreOnSenderSide() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let senderGoodsID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let receiverGoodsID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let input = ProposalCreateInput(
            receiverID: receiverID,
            senderGoodsIDs: [senderGoodsID],
            receiverGoodsIDs: [receiverGoodsID],
            exchangeMethod: .mail,
            cashAmount: 1_200,
            cashAmountSide: .sender
        )

        let request = try client.makeCreateProposalRequest(
            senderID: senderID,
            input: input,
            now: Date(timeIntervalSince1970: 0)
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(json.first?["sender_have_ids"] as? [String], ["33333333-3333-3333-3333-333333333333"])
        XCTAssertEqual(json.first?["receiver_have_ids"] as? [String], ["44444444-4444-4444-4444-444444444444"])
        XCTAssertEqual(json.first?["cash_offer"] as? Bool, true)
        XCTAssertEqual(json.first?["cash_amount"] as? Int, 1_200)
        XCTAssertEqual(json.first?["cash_amount_side"] as? String, "sender")
    }

    func testCreateProposalPayloadUsesNonDefaultMatchType() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let input = ProposalCreateInput(
            receiverID: receiverID,
            senderGoodsIDs: [UUID(uuidString: "33333333-3333-3333-3333-333333333333")!],
            receiverGoodsIDs: [UUID(uuidString: "44444444-4444-4444-4444-444444444444")!],
            exchangeMethod: .mail,
            matchType: .perfect
        )

        let request = try client.makeCreateProposalRequest(
            senderID: senderID,
            input: input,
            now: Date(timeIntervalSince1970: 0)
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(json.first?["match_type"] as? String, "perfect")
    }

    func testBuildsCreateProposalRequestForListingOriginWithBothMethodAndMeetup() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let listingID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
        let meetup = ProposalMeetupInput(
            startAt: Date(timeIntervalSince1970: 1_000),
            endAt: Date(timeIntervalSince1970: 2_800),
            placeName: " 横浜アリーナ 北口 ",
            latitude: 35.5122,
            longitude: 139.6171
        )
        let secondMeetup = ProposalMeetupInput(
            startAt: Date(timeIntervalSince1970: 4_000),
            endAt: Date(timeIntervalSince1970: 5_800),
            placeName: "新横浜駅 中央改札",
            latitude: 35.5076,
            longitude: 139.6175
        )
        let input = ProposalCreateInput(
            receiverID: receiverID,
            senderGoodsIDs: [
                UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
            ],
            receiverGoodsIDs: [
                UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
            ],
            exchangeMethod: .both,
            conditionTags: ["終演後OK", "同日発送"],
            message: " 個別募集からお願いします ",
            meetup: meetup,
            meetupCandidates: [meetup, secondMeetup],
            exposeCalendar: true,
            listingID: listingID
        )

        let request = try client.makeCreateProposalRequest(
            senderID: senderID,
            input: input,
            now: Date(timeIntervalSince1970: 0)
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let row = try XCTUnwrap(json.first)
        let candidates = try XCTUnwrap(row["meetup_candidates"] as? [[String: Any]])
        let candidate = try XCTUnwrap(candidates.first)

        XCTAssertEqual(row["exchange_method"] as? String, "both")
        XCTAssertEqual(row["listing_id"] as? String, "55555555-5555-5555-5555-555555555555")
        XCTAssertEqual(
            row["receiver_have_ids"] as? [String],
            [
                "44444444-4444-4444-4444-444444444444",
                "66666666-6666-6666-6666-666666666666"
            ]
        )
        XCTAssertEqual(row["option_tags"] as? [String], ["終演後OK", "同日発送"])
        XCTAssertEqual(row["expose_calendar"] as? Bool, true)
        XCTAssertEqual(row["message"] as? String, "個別募集からお願いします")
        XCTAssertEqual(row["meetup_place_name"] as? String, "横浜アリーナ 北口")
        XCTAssertEqual(row["meetup_lat"] as? Double, 35.5122)
        XCTAssertEqual(row["meetup_lng"] as? Double, 139.6171)
        XCTAssertEqual(candidates.count, 2)
        XCTAssertEqual(candidate["startAt"] as? String, "1970-01-01T00:16:40.000Z")
        XCTAssertEqual(candidate["endAt"] as? String, "1970-01-01T00:46:40.000Z")
        XCTAssertEqual(candidate["placeName"] as? String, "横浜アリーナ 北口")
        XCTAssertEqual(candidate["lat"] as? Double, 35.5122)
        XCTAssertEqual(candidate["lng"] as? Double, 139.6171)
        XCTAssertEqual(candidate["mode"] as? String, "scheduled")
        XCTAssertEqual(candidates.last?["placeName"] as? String, "新横浜駅 中央改札")
    }

    func testCreateProposalPayloadDoesNotExposeCalendarForMailOnlyEvenWhenInputRequestsIt() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let input = ProposalCreateInput(
            receiverID: receiverID,
            senderGoodsIDs: [UUID(uuidString: "33333333-3333-3333-3333-333333333333")!],
            receiverGoodsIDs: [UUID(uuidString: "44444444-4444-4444-4444-444444444444")!],
            exchangeMethod: .mail,
            exposeCalendar: true
        )

        let request = try client.makeCreateProposalRequest(
            senderID: senderID,
            input: input,
            now: Date(timeIntervalSince1970: 0)
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(json.first?["exchange_method"] as? String, "mail")
        XCTAssertEqual(json.first?["expose_calendar"] as? Bool, false)
    }

    func testBuildsCounterProposalRequestWithSenderAgreement() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let senderGoodsID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let receiverGoodsID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let input = ProposalCreateInput(
            receiverID: receiverID,
            senderGoodsIDs: [senderGoodsID],
            receiverGoodsIDs: [receiverGoodsID],
            exchangeMethod: .mail,
            conditionTags: ["同日発送"],
            message: "条件を変えます",
            status: .negotiating
        )

        let request = try client.makeCreateProposalRequest(senderID: senderID, input: input)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(json.first?["status"] as? String, "negotiating")
        XCTAssertEqual(json.first?["agreed_by_sender"] as? Bool, true)
    }

    func testBuildsAgreeProposalRequestForIncomingSentProposal() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let proposalID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let proposal = TradeProposal(
            id: proposalID,
            senderID: senderID,
            receiverID: receiverID,
            status: .sent,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            agreedBySender: true,
            agreedByReceiver: false
        )

        let request = try client.makeAgreeProposalRequest(userID: receiverID, proposal: proposal)
        let url = try XCTUnwrap(request.url?.absoluteString)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(url, "https://example.supabase.co/rest/v1/rpc/respond_to_proposal_for_viewer")
        XCTAssertNil(request.value(forHTTPHeaderField: "Prefer"))
        XCTAssertEqual(json["p_proposal_id"] as? String, "33333333-3333-3333-3333-333333333333")
        XCTAssertEqual(json["p_action"] as? String, "agree")
        XCTAssertNil(json["p_accepted_exchange_method"])
    }

    func testBuildsAgreeProposalRequestWithSelectedExchangeMethod() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let proposalID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let proposal = TradeProposal(
            id: proposalID,
            senderID: senderID,
            receiverID: receiverID,
            status: .sent,
            exchangeMethod: .both,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            agreedBySender: true,
            agreedByReceiver: false
        )

        let request = try client.makeAgreeProposalRequest(
            userID: receiverID,
            proposal: proposal,
            acceptedExchangeMethod: .mail
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(json["p_proposal_id"] as? String, "33333333-3333-3333-3333-333333333333")
        XCTAssertEqual(json["p_action"] as? String, "agree")
        XCTAssertEqual(json["p_accepted_exchange_method"] as? String, "mail")
    }

    func testBuildsRejectProposalRequest() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let proposalID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

        let request = try client.makeRejectProposalRequest(proposalID: proposalID)
        let url = try XCTUnwrap(request.url?.absoluteString)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(url, "https://example.supabase.co/rest/v1/rpc/respond_to_proposal_for_viewer")
        XCTAssertNil(request.value(forHTTPHeaderField: "Prefer"))
        XCTAssertEqual(json["p_proposal_id"] as? String, "33333333-3333-3333-3333-333333333333")
        XCTAssertEqual(json["p_action"] as? String, "reject")
        XCTAssertNil(json["p_accepted_exchange_method"])
    }

    func testBuildsApproveEvidenceRequest() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let proposalID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let proposal = TradeProposal(
            id: proposalID,
            senderID: senderID,
            receiverID: receiverID,
            status: .agreed,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            evidencePhotoURL: URL(string: "https://example.com/evidence.jpg")!,
            approvedBySender: true,
            approvedByReceiver: false
        )

        let photoID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

        let request = try client.makeApproveEvidenceRequest(userID: receiverID, proposal: proposal, photoID: photoID)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/approve_trade_evidence_for_viewer")
        XCTAssertNil(request.value(forHTTPHeaderField: "Prefer"))
        XCTAssertEqual(json["p_proposal_id"] as? String, "33333333-3333-3333-3333-333333333333")
        XCTAssertEqual(json["p_photo_id"] as? String, "44444444-4444-4444-4444-444444444444")
    }

    func testBuildsApproveCancelRequestForAgreedParticipant() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let proposalID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let proposal = TradeProposal(
            id: proposalID,
            senderID: senderID,
            receiverID: receiverID,
            status: .agreed,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            agreedBySender: true,
            agreedByReceiver: true
        )

        let request = try client.makeApproveCancelRequest(
            userID: receiverID,
            proposal: proposal,
            now: Date(timeIntervalSince1970: 0)
        )
        let url = try XCTUnwrap(request.url?.absoluteString)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/proposals?select=id,sender_id,receiver_id,listing_id,status"))
        XCTAssertTrue(url.contains("id=eq.33333333-3333-3333-3333-333333333333"))
        XCTAssertTrue(url.contains("status=eq.agreed"))
        XCTAssertTrue(url.contains("or=(sender_id.eq.22222222-2222-2222-2222-222222222222,receiver_id.eq.22222222-2222-2222-2222-222222222222)"))
        XCTAssertTrue(url.contains("limit=1"))
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertEqual(json["status"] as? String, "cancelled")
        XCTAssertEqual(json["last_action_at"] as? String, "1970-01-01T00:00:00.000Z")
    }

    func testRejectsApproveCancelRequestForNonParticipant() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let proposal = TradeProposal(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            senderID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            receiverID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            status: .agreed,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: []
        )

        XCTAssertThrowsError(
            try client.makeApproveCancelRequest(
                userID: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
                proposal: proposal
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseProposalClientError, .notParticipant)
        }
    }

    func testRejectsApproveCancelRequestBeforeAgreement() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposal = TradeProposal(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            senderID: senderID,
            receiverID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            status: .negotiating,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: []
        )

        XCTAssertThrowsError(
            try client.makeApproveCancelRequest(userID: senderID, proposal: proposal)
        ) { error in
            XCTAssertEqual(error as? SupabaseProposalClientError, .invalidStatus)
        }
    }

    func testRejectsApproveEvidenceRequestWithoutEvidencePhoto() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let proposal = TradeProposal(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            senderID: senderID,
            receiverID: receiverID,
            status: .agreed,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: []
        )

        XCTAssertThrowsError(
            try client.makeApproveEvidenceRequest(userID: receiverID, proposal: proposal)
        ) { error in
            XCTAssertEqual(error as? SupabaseProposalClientError, .missingEvidence)
        }
    }

    func testBuildsSubmitEvaluationRequest() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let proposalID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let proposal = TradeProposal(
            id: proposalID,
            senderID: senderID,
            receiverID: receiverID,
            status: .completed,
            exchangeMethod: .mail,
            senderGoodsIDs: [],
            receiverGoodsIDs: []
        )
        let input = TradeEvaluationCreateInput(
            proposalID: proposalID,
            stars: 5,
            comment: "ありがとうございました"
        )

        let request = try client.makeSubmitEvaluationRequest(userID: senderID, proposal: proposal, input: input)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(json.first?["proposal_id"] as? String, "33333333-3333-3333-3333-333333333333")
        XCTAssertEqual(json.first?["rater_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(json.first?["ratee_id"] as? String, "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(json.first?["stars"] as? Int, 5)
        XCTAssertEqual(json.first?["comment"] as? String, "ありがとうございました")
    }

    func testRejectsSubmitEvaluationRequestBeforeCompletion() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let proposalID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let proposal = TradeProposal(
            id: proposalID,
            senderID: senderID,
            receiverID: receiverID,
            status: .agreed,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: []
        )

        XCTAssertThrowsError(
            try client.makeSubmitEvaluationRequest(
                userID: senderID,
                proposal: proposal,
                input: TradeEvaluationCreateInput(proposalID: proposalID, stars: 5, comment: nil)
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseProposalClientError, .invalidStatus)
        }
    }

    func testRejectsSubmitEvaluationRequestWithInvalidStars() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let proposalID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let proposal = TradeProposal(
            id: proposalID,
            senderID: senderID,
            receiverID: receiverID,
            status: .completed,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: []
        )

        XCTAssertThrowsError(
            try client.makeSubmitEvaluationRequest(
                userID: senderID,
                proposal: proposal,
                input: TradeEvaluationCreateInput(proposalID: proposalID, stars: 6, comment: nil)
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseProposalClientError, .invalidRating)
        }
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }

    private static func requestBodyString(from request: URLRequest) -> String {
        if let body = request.httpBody {
            return String(data: body, encoding: .utf8) ?? ""
        }
        guard let stream = request.httpBodyStream else {
            return ""
        }
        stream.open()
        defer { stream.close() }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1_024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else {
                break
            }
            data.append(buffer, count: count)
        }
        return String(data: data, encoding: .utf8) ?? ""
    }
}

private enum ProposalEvidenceMockError: Error {
    case missingURL
    case missingHandler
    case unexpectedRequest(String)
}

private final class ProposalEvidenceMockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: ProposalEvidenceMockError.missingHandler)
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
