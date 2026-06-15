import MegrumApp
import MegrumCore
import XCTest

final class TradeProposalStateReducerTests: XCTestCase {
    func testPrependingCreatedProposalAddsToFront() {
        let existing = makeProposal(idSuffix: "201", status: .sent)
        let created = makeProposal(idSuffix: "202", status: .sent)

        let updated = TradeProposalStateReducer.prependingCreatedProposal(
            created,
            to: [existing]
        )

        XCTAssertEqual(updated, [created, existing])
    }

    func testReplacingExistingProposalKeepsExistingPosition() {
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000001203")!
        let first = makeProposal(idSuffix: "204", status: .sent)
        let original = makeProposal(id: targetID, status: .sent)
        let last = makeProposal(idSuffix: "205", status: .sent)
        let updatedProposal = makeProposal(id: targetID, status: .agreed)

        let updated = TradeProposalStateReducer.replacingOrPrepending(
            updatedProposal,
            in: [first, original, last]
        )

        XCTAssertEqual(updated, [first, updatedProposal, last])
    }

    func testReplacingMissingProposalPrepends() {
        let existing = makeProposal(idSuffix: "206", status: .sent)
        let missing = makeProposal(idSuffix: "207", status: .agreed)

        let updated = TradeProposalStateReducer.replacingOrPrepending(
            missing,
            in: [existing]
        )

        XCTAssertEqual(updated, [missing, existing])
    }

    private func makeProposal(
        idSuffix: String,
        status: ProposalStatus
    ) -> TradeProposal {
        makeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000001\(idSuffix)")!,
            status: status
        )
    }

    private func makeProposal(
        id: UUID,
        status: ProposalStatus
    ) -> TradeProposal {
        TradeProposal(
            id: id,
            senderID: UUID(uuidString: "00000000-0000-0000-0000-000000001298")!,
            receiverID: UUID(uuidString: "00000000-0000-0000-0000-000000001299")!,
            status: status,
            exchangeMethod: .hand,
            senderGoodsIDs: [
                UUID(uuidString: "00000000-0000-0000-0000-000000001297")!
            ],
            receiverGoodsIDs: [
                UUID(uuidString: "00000000-0000-0000-0000-000000001296")!
            ],
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }
}
