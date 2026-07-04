@testable import MegrumApp
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

    func testReplacingMessagesPreservesLocalViewerEvaluationNoticeWhenReloadMissesIt() {
        let proposalID = UUID(uuidString: "00000000-0000-0000-0000-000000000311")!
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000312")!
        let remoteMessage = makeMessage(
            proposalID: proposalID,
            body: "サーバ取得メッセージ",
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let localEvaluationNotice = makeMessage(
            proposalID: proposalID,
            body: "みちの評価が完了しました",
            senderID: viewerID,
            messageType: .system,
            meta: ["action": "evaluation_submitted", "stars": "5"],
            createdAt: Date(timeIntervalSince1970: 200)
        )

        let updated = TradeMessageStateReducer.replacingMessagesPreservingViewerEvaluationNotices(
            in: [proposalID: [localEvaluationNotice]],
            proposalID: proposalID,
            messages: [remoteMessage],
            viewerID: viewerID
        )

        XCTAssertEqual(updated[proposalID], [remoteMessage, localEvaluationNotice])
    }

    func testReplacingMessagesDoesNotPreserveLocalEvaluationNoticeAfterServerReturnsViewerEvaluation() {
        let proposalID = UUID(uuidString: "00000000-0000-0000-0000-000000000313")!
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000314")!
        let localEvaluationNotice = makeMessage(
            proposalID: proposalID,
            body: "みちの評価が完了しました",
            senderID: viewerID,
            messageType: .system,
            meta: ["action": "evaluation_submitted", "stars": "5"],
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let remoteEvaluationNotice = makeMessage(
            proposalID: proposalID,
            body: "みちの評価が完了しました",
            senderID: viewerID,
            messageType: .system,
            meta: ["action": "evaluation_submitted", "stars": "5"],
            createdAt: Date(timeIntervalSince1970: 120)
        )

        let updated = TradeMessageStateReducer.replacingMessagesPreservingViewerEvaluationNotices(
            in: [proposalID: [localEvaluationNotice]],
            proposalID: proposalID,
            messages: [remoteEvaluationNotice],
            viewerID: viewerID
        )

        XCTAssertEqual(updated[proposalID], [remoteEvaluationNotice])
    }

    func testReplacingMessagesUsesRaterIDWhenServerEvaluationSenderIsSystem() {
        let proposalID = UUID(uuidString: "00000000-0000-0000-0000-000000000321")!
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000322")!
        let systemID = UUID(uuidString: "00000000-0000-0000-0000-000000000323")!
        let localEvaluationNotice = makeMessage(
            proposalID: proposalID,
            body: "みちの評価が完了しました",
            senderID: viewerID,
            messageType: .system,
            meta: ["action": "evaluation_submitted", "stars": "5"],
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let remoteEvaluationNotice = makeMessage(
            proposalID: proposalID,
            body: "評価が完了しました",
            senderID: systemID,
            messageType: .system,
            meta: [
                "action": "evaluation_submitted",
                "rater_id": viewerID.uuidString.lowercased(),
                "stars": "5",
            ],
            createdAt: Date(timeIntervalSince1970: 120)
        )

        let updated = TradeMessageStateReducer.replacingMessagesPreservingViewerEvaluationNotices(
            in: [proposalID: [localEvaluationNotice]],
            proposalID: proposalID,
            messages: [remoteEvaluationNotice],
            viewerID: viewerID
        )

        XCTAssertEqual(updated[proposalID], [remoteEvaluationNotice])
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
        senderID: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000310")!,
        messageType: TradeMessageType = .text,
        meta: [String: String] = [:],
        createdAt: Date = Date(timeIntervalSince1970: 0)
    ) -> TradeMessage {
        TradeMessage(
            id: UUID(),
            proposalID: proposalID,
            senderID: senderID,
            messageType: messageType,
            body: body,
            meta: meta,
            createdAt: createdAt
        )
    }
}
