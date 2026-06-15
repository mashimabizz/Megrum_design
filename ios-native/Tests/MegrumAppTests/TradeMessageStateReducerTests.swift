import MegrumApp
import MegrumCore
import XCTest

final class TradeMessageStateReducerTests: XCTestCase {
    func testReplacingMessagesKeepsOtherProposalBuckets() {
        let targetProposalID = UUID(uuidString: "00000000-0000-0000-0000-000000000301")!
        let otherProposalID = UUID(uuidString: "00000000-0000-0000-0000-000000000302")!
        let replacement = makeMessage(proposalID: targetProposalID, body: "差し替え")
        let existing = makeMessage(proposalID: otherProposalID, body: "保持")
        let messagesByProposalID = [
            targetProposalID: [makeMessage(proposalID: targetProposalID, body: "古い")],
            otherProposalID: [existing],
        ]

        let updated = TradeMessageStateReducer.replacingMessages(
            in: messagesByProposalID,
            proposalID: targetProposalID,
            messages: [replacement]
        )

        XCTAssertEqual(updated[targetProposalID], [replacement])
        XCTAssertEqual(updated[otherProposalID], [existing])
    }

    func testAppendingMessageCreatesOrExtendsProposalBucket() {
        let proposalID = UUID(uuidString: "00000000-0000-0000-0000-000000000303")!
        let first = makeMessage(proposalID: proposalID, body: "最初")
        let second = makeMessage(proposalID: proposalID, body: "追加")

        let created = TradeMessageStateReducer.appendingMessage(
            first,
            to: [:],
            proposalID: proposalID
        )
        let appended = TradeMessageStateReducer.appendingMessage(
            second,
            to: created,
            proposalID: proposalID
        )

        XCTAssertEqual(appended[proposalID], [first, second])
    }

    func testSettingReadAtSetsAndRemovesProposalReadPosition() {
        let proposalID = UUID(uuidString: "00000000-0000-0000-0000-000000000304")!
        let readAt = Date(timeIntervalSince1970: 100)

        let updated = TradeMessageStateReducer.settingReadAt(
            in: [:],
            proposalID: proposalID,
            readAt: readAt
        )
        XCTAssertEqual(updated[proposalID], readAt)

        let removed = TradeMessageStateReducer.settingReadAt(
            in: updated,
            proposalID: proposalID,
            readAt: nil
        )
        XCTAssertNil(removed[proposalID])
    }

    func testLatestReadAtUsesLatestMessageUpdatedAtOrCreatedAt() {
        let proposalID = UUID(uuidString: "00000000-0000-0000-0000-000000000305")!
        let proposal = makeProposal(
            id: proposalID,
            createdAt: Date(timeIntervalSince1970: 100),
            updatedAt: Date(timeIntervalSince1970: 200)
        )
        let olderMessage = makeMessage(
            proposalID: proposalID,
            body: "古い",
            createdAt: Date(timeIntervalSince1970: 150)
        )
        let newestMessage = makeMessage(
            proposalID: proposalID,
            body: "新しい",
            createdAt: Date(timeIntervalSince1970: 300)
        )

        XCTAssertEqual(
            TradeMessageStateReducer.latestReadAt(
                for: proposal,
                proposalID: proposalID,
                messages: [olderMessage, newestMessage]
            ),
            Date(timeIntervalSince1970: 300)
        )
        XCTAssertEqual(
            TradeMessageStateReducer.latestReadAt(
                for: proposal,
                proposalID: proposalID,
                messages: []
            ),
            Date(timeIntervalSince1970: 200)
        )
    }

    func testResolvedReadAtUsesServerReadStateOrFallback() {
        let proposalID = UUID(uuidString: "00000000-0000-0000-0000-000000000306")!
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000307")!
        let fallback = Date(timeIntervalSince1970: 100)
        let serverReadAt = Date(timeIntervalSince1970: 200)
        let readState = ProposalReadState(
            proposalID: proposalID,
            userID: userID,
            lastReadAt: serverReadAt
        )

        XCTAssertEqual(
            TradeMessageStateReducer.resolvedReadAt(from: readState, fallback: fallback),
            serverReadAt
        )
        XCTAssertEqual(
            TradeMessageStateReducer.resolvedReadAt(from: nil, fallback: fallback),
            fallback
        )
    }

    private func makeProposal(
        id: UUID,
        createdAt: Date,
        updatedAt: Date?
    ) -> TradeProposal {
        TradeProposal(
            id: id,
            senderID: UUID(uuidString: "00000000-0000-0000-0000-000000000308")!,
            receiverID: UUID(uuidString: "00000000-0000-0000-0000-000000000309")!,
            status: .sent,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private func makeMessage(
        proposalID: UUID,
        body: String,
        createdAt: Date = Date(timeIntervalSince1970: 0)
    ) -> TradeMessage {
        TradeMessage(
            id: UUID(),
            proposalID: proposalID,
            senderID: UUID(uuidString: "00000000-0000-0000-0000-000000000310")!,
            messageType: .text,
            body: body,
            createdAt: createdAt
        )
    }
}
