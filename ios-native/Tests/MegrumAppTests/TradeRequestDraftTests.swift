@testable import MegrumApp
import XCTest

final class TradeRequestDraftTests: XCTestCase {
    func testCancellationRequestRequiresReasonAndAcknowledgement() {
        var draft = TradeRequestDraft(kind: .cancellation, reason: " 急用で向かえません ")

        XCTAssertFalse(draft.isSubmittable)
        XCTAssertNil(draft.systemMessageBody)

        draft.acknowledgesImpact = true

        XCTAssertTrue(draft.isSubmittable)
        XCTAssertEqual(draft.normalizedReason, "急用で向かえません")
        XCTAssertEqual(draft.systemMessageBody, "キャンセル申請: 急用で向かえません")
    }

    func testLateRequestRequiresReasonAcknowledgementAndBoundedDelay() {
        var draft = TradeRequestDraft(
            kind: .late,
            reason: " 物販列が進まず、北口へ15分ほど遅れます ",
            estimatedDelayMinutes: 15,
            acknowledgesImpact: true
        )

        XCTAssertTrue(draft.isSubmittable)
        XCTAssertEqual(
            draft.systemMessageBody,
            "遅刻申請: 15分ほど遅れます。物販列が進まず、北口へ15分ほど遅れます"
        )

        draft.estimatedDelayMinutes = 181

        XCTAssertFalse(draft.isSubmittable)
        XCTAssertNil(draft.systemMessageBody)
    }

    func testDisputeReplyDraftTrimsBody() {
        let draft = DisputeReplyDraft(body: "  到着時刻はチャットで共有済みです  ")

        XCTAssertTrue(draft.isSubmittable)
        XCTAssertEqual(draft.normalizedBody, "到着時刻はチャットで共有済みです")
    }
}
