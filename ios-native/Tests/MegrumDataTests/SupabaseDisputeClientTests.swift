import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseDisputeClientTests: XCTestCase {
    func testBuildsLoadDisputesForProposalRequest() throws {
        let client = SupabaseDisputeClient(configuration: configuration)
        let proposalID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

        let request = try client.makeLoadDisputesRequest(proposalID: proposalID, limit: 3)
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/disputes?select=id,proposal_id,reporter_id,respondent_id"))
        XCTAssertTrue(url.contains("dispute_messages"))
        XCTAssertTrue(url.contains("proposal_id=eq.33333333-3333-3333-3333-333333333333"))
        XCTAssertTrue(url.contains("order=submitted_at.desc"))
        XCTAssertTrue(url.contains("limit=3"))
    }

    func testBuildsLoadDisputeByTicketIDRequest() throws {
        let client = SupabaseDisputeClient(configuration: configuration)
        let ticketID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

        let request = try client.makeLoadDisputeRequest(ticketID: ticketID)
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/disputes?select=id,proposal_id,reporter_id,respondent_id"))
        XCTAssertTrue(url.contains("id=eq.44444444-4444-4444-4444-444444444444"))
        XCTAssertTrue(url.contains("limit=1"))
    }

    func testBuildsCreateDisputeRequest() throws {
        let client = SupabaseDisputeClient(configuration: configuration)
        let reporterID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let respondentID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let proposalID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let proposal = TradeProposal(
            id: proposalID,
            senderID: reporterID,
            receiverID: respondentID,
            status: .agreed,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: []
        )
        let input = TradeDisputeCreateInput(
            proposalID: proposalID,
            category: .wrong,
            factMemo: "  受け取ったグッズの状態が違いました  "
        )

        let request = try client.makeCreateDisputeRequest(
            userID: reporterID,
            proposal: proposal,
            input: input,
            ticketNo: "DPT-260531-ABCD"
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertTrue(request.url?.absoluteString.contains("/rest/v1/disputes?select=id,proposal_id,ticket_no,status,submitted_at") ?? false)
        XCTAssertEqual(json.first?["proposal_id"] as? String, "33333333-3333-3333-3333-333333333333")
        XCTAssertEqual(json.first?["reporter_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(json.first?["respondent_id"] as? String, "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(json.first?["category"] as? String, "wrong")
        XCTAssertEqual(json.first?["fact_memo"] as? String, "受け取ったグッズの状態が違いました")
        XCTAssertEqual(json.first?["ticket_no"] as? String, "DPT-260531-ABCD")
        XCTAssertEqual(json.first?["evidence_photo_urls"] as? [String], [])
    }

    func testBuildsCreateDisputeReplyRequest() throws {
        let client = SupabaseDisputeClient(configuration: configuration)
        let disputeID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let senderID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeCreateDisputeReplyRequest(
            SupabaseDisputeReplyCreateInput(
                disputeID: disputeID,
                senderID: senderID,
                senderRole: .respondent,
                body: "  受け渡し時にその場で確認済みです  ",
                photoURLs: [" https://example.com/a.jpg ", ""]
            )
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/dispute_messages?select=id,dispute_id,sender_id,sender_role,body,photo_urls,created_at")
        XCTAssertEqual(json.first?["dispute_id"] as? String, "44444444-4444-4444-4444-444444444444")
        XCTAssertEqual(json.first?["sender_id"] as? String, "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(json.first?["sender_role"] as? String, "respondent")
        XCTAssertEqual(json.first?["body"] as? String, "受け渡し時にその場で確認済みです")
        XCTAssertEqual(json.first?["photo_urls"] as? [String], ["https://example.com/a.jpg"])
    }

    func testBuildsMarkRespondentReplyReceivedRequest() throws {
        let client = SupabaseDisputeClient(configuration: configuration)
        let disputeID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let respondentID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let respondedAt = Date(timeIntervalSince1970: 1_800_000_000)

        let request = try client.makeMarkRespondentReplyReceivedRequest(
            SupabaseDisputeReplyCreateInput(
                disputeID: disputeID,
                senderID: respondentID,
                senderRole: .respondent,
                body: "  受け渡し時の状況に相違があります  ",
                photoURLs: [" https://example.com/respondent-proof.jpg ", ""]
            ),
            respondedAt: respondedAt
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/disputes?select=id,proposal_id,reporter_id,respondent_id"))
        XCTAssertTrue(url.contains("id=eq.44444444-4444-4444-4444-444444444444"))
        XCTAssertTrue(url.contains("respondent_id=eq.22222222-2222-2222-2222-222222222222"))
        XCTAssertTrue(url.contains("status=in.(submitted,response_pending)") || url.contains("status=in.%28submitted,response_pending%29"))
        XCTAssertEqual(json["respondent_response"] as? String, "disputed")
        XCTAssertEqual(json["respondent_response_text"] as? String, "受け渡し時の状況に相違があります")
        XCTAssertEqual(json["respondent_evidence_urls"] as? [String], ["https://example.com/respondent-proof.jpg"])
        XCTAssertEqual(json["respondent_responded_at"] as? String, "2027-01-15T08:00:00.000Z")
        XCTAssertEqual(json["status"] as? String, "arbitrating")
    }

    func testBuildsWithdrawDisputeRequest() throws {
        let client = SupabaseDisputeClient(configuration: configuration)
        let ticketID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let reporterID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let closedAt = Date(timeIntervalSince1970: 1_800_000_000)

        let request = try client.makeWithdrawDisputeRequest(
            ticketID: ticketID,
            reporterID: reporterID,
            closedAt: closedAt
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/disputes?select=id,proposal_id,reporter_id,respondent_id"))
        XCTAssertTrue(url.contains("id=eq.44444444-4444-4444-4444-444444444444"))
        XCTAssertTrue(url.contains("reporter_id=eq.11111111-1111-1111-1111-111111111111"))
        XCTAssertTrue(url.contains("status=neq.closed"))
        XCTAssertEqual(json["status"] as? String, "closed")
        XCTAssertEqual(json["closed_at"] as? String, "2027-01-15T08:00:00.000Z")
    }

    func testRejectsDisputeRequestWithoutRespondent() throws {
        let client = SupabaseDisputeClient(configuration: configuration)
        let reporterID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposal = TradeProposal(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            senderID: reporterID,
            receiverID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            status: .agreed,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: []
        )

        XCTAssertThrowsError(
            try client.makeCreateDisputeRequest(
                userID: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                proposal: proposal,
                input: TradeDisputeCreateInput(proposalID: proposal.id, category: .other, factMemo: "確認してください"),
                ticketNo: "DPT-260531-ABCD"
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseDisputeClientError, .notParticipant)
        }
    }

    func testRejectsDisputeRequestWithBlankFactMemo() throws {
        let client = SupabaseDisputeClient(configuration: configuration)
        let reporterID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let respondentID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let proposal = TradeProposal(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            senderID: reporterID,
            receiverID: respondentID,
            status: .agreed,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: []
        )

        XCTAssertThrowsError(
            try client.makeCreateDisputeRequest(
                userID: reporterID,
                proposal: proposal,
                input: TradeDisputeCreateInput(proposalID: proposal.id, category: .other, factMemo: "   "),
                ticketNo: "DPT-260531-ABCD"
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseDisputeClientError, .emptyFactMemo)
        }
    }

    func testRejectsCreateDisputeReplyRequestWithBlankBody() throws {
        let client = SupabaseDisputeClient(configuration: configuration)

        XCTAssertThrowsError(
            try client.makeCreateDisputeReplyRequest(
                SupabaseDisputeReplyCreateInput(
                    disputeID: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                    senderID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                    senderRole: .respondent,
                    body: "   "
                )
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseDisputeClientError, .emptyReplyBody)
        }
    }

    func testRejectsCreateDisputeReplyRequestWithTooLongBody() throws {
        let client = SupabaseDisputeClient(configuration: configuration)

        XCTAssertThrowsError(
            try client.makeCreateDisputeReplyRequest(
                SupabaseDisputeReplyCreateInput(
                    disputeID: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                    senderID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                    senderRole: .respondent,
                    body: String(repeating: "あ", count: 4_001)
                )
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseDisputeClientError, .replyBodyTooLong(maxLength: 4_000))
        }
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
