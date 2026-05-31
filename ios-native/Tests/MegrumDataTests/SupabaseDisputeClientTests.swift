import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseDisputeClientTests: XCTestCase {
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

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
