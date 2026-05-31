import XCTest
@testable import MegrumCore

final class MegrumCoreTests: XCTestCase {
    func testExchangeMethodDisplayNames() {
        XCTAssertEqual(ExchangeMethod.hand.displayName, "現地交換")
        XCTAssertEqual(ExchangeMethod.mail.displayName, "郵送交換")
        XCTAssertEqual(ExchangeMethod.both.displayName, "どちらもOK")
    }

    func testProposalStatusRawValueMatchesExistingStateMachine() {
        XCTAssertEqual(ProposalStatus.agreementOneSide.rawValue, "agreement_one_side")
        XCTAssertEqual(ProposalStatus.cancelled.rawValue, "cancelled")
        XCTAssertEqual(ProposalStatus.completed.rawValue, "completed")
    }

    func testAccountStatusSetupBoundary() {
        XCTAssertTrue(AccountStatus.registered.requiresSetup)
        XCTAssertTrue(AccountStatus.verified.requiresSetup)
        XCTAssertTrue(AccountStatus.onboarding.requiresSetup)
        XCTAssertFalse(AccountStatus.active.requiresSetup)
        XCTAssertEqual(AccountStatus.deletionRequested.rawValue, "deletion_requested")
    }

    func testBoardAudienceRawValuesMatchDatabase() {
        XCTAssertEqual(BoardThread.Audience.nearby3km.rawValue, "nearby_3km")
        XCTAssertEqual(BoardThread.Audience.samePrefecture.rawValue, "same_prefecture")
        XCTAssertEqual(BoardThread.Audience.sameSpot.rawValue, "same_spot")
        XCTAssertEqual(BoardThread.Audience.global.rawValue, "global")
    }

    func testTradeProposalBuildsCounterProposalInputForReceiver() {
        let senderID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let receiverID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let senderGoodsID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let receiverGoodsID = UUID(uuidString: "00000000-0000-0000-0000-000000000201")!
        let proposal = TradeProposal(
            id: UUID(),
            senderID: senderID,
            receiverID: receiverID,
            status: .sent,
            exchangeMethod: .both,
            senderGoodsIDs: [senderGoodsID],
            receiverGoodsIDs: [receiverGoodsID],
            conditionTags: ["終演後OK"]
        )

        let input = proposal.counterProposalInput(
            from: receiverID,
            exchangeMethod: .mail,
            conditionTags: ["即日発送"],
            message: "郵送でお願いします"
        )

        XCTAssertEqual(input?.receiverID, senderID)
        XCTAssertEqual(input?.senderGoodsIDs, [receiverGoodsID])
        XCTAssertEqual(input?.receiverGoodsIDs, [senderGoodsID])
        XCTAssertEqual(input?.exchangeMethod, .mail)
        XCTAssertEqual(input?.conditionTags, ["即日発送"])
        XCTAssertEqual(input?.message, "郵送でお願いします")
        XCTAssertEqual(input?.status, .negotiating)
    }

    func testTradeProposalCounterProposalInputRejectsNonParticipant() {
        let senderID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let receiverID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let outsiderID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        let proposal = TradeProposal(
            id: UUID(),
            senderID: senderID,
            receiverID: receiverID,
            status: .sent,
            exchangeMethod: .hand,
            senderGoodsIDs: [UUID()],
            receiverGoodsIDs: [UUID()]
        )

        XCTAssertNil(
            proposal.counterProposalInput(
                from: outsiderID,
                exchangeMethod: .mail,
                conditionTags: [],
                message: nil
            )
        )
    }
}
