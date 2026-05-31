@testable import MegrumApp
import MegrumCore
import XCTest

final class DisputeDetailScreenTests: XCTestCase {
    func testTicketModelNormalizesReplyWindowStatus() {
        let submittedAt = Date(timeIntervalSince1970: 1_800)
        let deadline = submittedAt.addingTimeInterval(86_400)
        let ticket = TradeDisputeTicket(
            id: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
            proposalID: UUID(uuidString: "30000000-0000-0000-0000-000000000101")!,
            ticketNo: "DPT-260531-ABCDEF12",
            status: "reply_window",
            submittedAt: submittedAt
        )

        let model = DisputeDetailModel(
            ticket: ticket,
            category: .wrong,
            reporterName: "みちりおん",
            respondentName: "相手さん",
            factMemo: "状態が説明と違いました",
            replyDeadlineAt: deadline
        )

        XCTAssertEqual(model.status, .replyWindow)
        XCTAssertEqual(model.category, .wrong)
        XCTAssertEqual(model.reporterName, "みちりおん")
        XCTAssertTrue(model.canSubmitReply)
        XCTAssertTrue(model.canWithdraw)
        XCTAssertEqual(model.replyCountdownText(now: submittedAt.addingTimeInterval(3_600)), "反論期限まで残り23時間")
    }

    func testDefaultTimelineMarksCurrentReplyWindowStep() {
        let submittedAt = Date(timeIntervalSince1970: 2_400)
        let entries = DisputeDetailTimelineBuilder.build(
            status: .replyWindow,
            submittedAt: submittedAt,
            replyDeadlineAt: submittedAt.addingTimeInterval(86_400)
        )

        XCTAssertEqual(entries.map(\.status), [.submitted, .replyWindow, .arbitration, .resolved])
        XCTAssertEqual(entries.map(\.state), [.completed, .current, .pending, .pending])
        XCTAssertEqual(entries.first?.date, submittedAt)
    }

    func testResolvedStatusDisablesReplyAndWithdrawal() {
        let model = DisputeDetailModel(
            id: UUID(uuidString: "30000000-0000-0000-0000-000000000002")!,
            proposalID: UUID(uuidString: "30000000-0000-0000-0000-000000000102")!,
            ticketNo: "DPT-260531-RESOLVED",
            status: .resolved,
            submittedAt: Date(timeIntervalSince1970: 1_000),
            resolvedAt: Date(timeIntervalSince1970: 2_000),
            resolutionSummary: "双方に非なし"
        )

        XCTAssertFalse(model.canSubmitReply)
        XCTAssertFalse(model.canWithdraw)
        XCTAssertEqual(model.timeline.last?.status, .resolved)
        XCTAssertEqual(model.timeline.last?.state, .current)
    }
}
