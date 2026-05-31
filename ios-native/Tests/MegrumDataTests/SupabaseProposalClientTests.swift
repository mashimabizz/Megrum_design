import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseProposalClientTests: XCTestCase {
    func testBuildsLoadProposalsRequest() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let viewerID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let request = try client.makeLoadProposalsRequest(viewerID: viewerID)
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/proposals?select=id,sender_id,receiver_id,listing_id,status,exchange_method,sender_have_ids,receiver_have_ids,option_tags"))
        XCTAssertTrue(url.contains("agreed_by_sender"))
        XCTAssertTrue(url.contains("agreed_by_receiver"))
        XCTAssertTrue(url.contains("evidence_photo_url"))
        XCTAssertTrue(url.contains("approved_by_sender"))
        XCTAssertTrue(url.contains("completed_at"))
        XCTAssertTrue(url.contains("or=(sender_id.eq.11111111-1111-1111-1111-111111111111,receiver_id.eq.11111111-1111-1111-1111-111111111111)"))
        XCTAssertTrue(url.contains("order=created_at.desc"))
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
        XCTAssertEqual(json.first?["agreed_by_sender"] as? Bool, true)
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

        let request = try client.makeApproveEvidenceRequest(userID: receiverID, proposal: proposal)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/approve_trade_evidence_for_viewer")
        XCTAssertNil(request.value(forHTTPHeaderField: "Prefer"))
        XCTAssertEqual(json["p_proposal_id"] as? String, "33333333-3333-3333-3333-333333333333")
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
}
