@testable import MegrumApp
import XCTest

final class TradeRequestDraftTests: XCTestCase {
    func testTradeChatLateDraftBuildsTypedSystemIntent() throws {
        let draft = TradeAssistanceRequestDraft(
            kind: .late,
            delayBucket: .twenty,
            reason: " 電車遅延 ",
            note: " 北口へ向かっています ",
            acknowledgesImpact: true
        )

        let intent = try XCTUnwrap(draft.systemIntent)

        XCTAssertEqual(intent.kind, .late)
        XCTAssertEqual(intent.action, .lateNotice)
        XCTAssertEqual(intent.delayBucket, .twenty)
        XCTAssertEqual(intent.lateMinutes, 20)
        XCTAssertEqual(intent.reason, "電車遅延")
        XCTAssertEqual(intent.note, "北口へ向かっています")
        XCTAssertTrue(intent.acknowledgedImpact)
        XCTAssertEqual(intent.messageBody, "20分遅れる旨が通知されました\n理由：電車遅延\n北口へ向かっています")
        XCTAssertEqual(
            intent.metadata,
            [
                "action": "late_notice",
                "late_minutes": "20",
                "reason": "電車遅延",
                "note": "北口へ向かっています"
            ]
        )
    }

    func testTradeChatCancelDraftBuildsTypedSystemIntent() throws {
        let draft = TradeAssistanceRequestDraft(
            kind: .cancel,
            reason: " 急用 ",
            note: " 明日の同時刻なら可能です ",
            acknowledgesImpact: true
        )

        let intent = try XCTUnwrap(draft.systemIntent)

        XCTAssertEqual(intent.kind, .cancel)
        XCTAssertEqual(intent.action, .cancelRequested)
        XCTAssertNil(intent.delayBucket)
        XCTAssertNil(intent.lateMinutes)
        XCTAssertEqual(intent.reason, "急用")
        XCTAssertEqual(intent.note, "明日の同時刻なら可能です")
        XCTAssertTrue(intent.acknowledgedImpact)
        XCTAssertEqual(intent.messageBody, "取引キャンセルが申請されました\n理由：急用\n明日の同時刻なら可能です")
        XCTAssertEqual(
            intent.metadata,
            [
                "action": "cancel_requested",
                "reason": "急用",
                "note": "明日の同時刻なら可能です"
            ]
        )
    }

    func testTradeChatRequestDraftRequiresReasonAndAcknowledgement() {
        var draft = TradeAssistanceRequestDraft(kind: .late, reason: " 電車遅延 ")

        XCTAssertFalse(draft.isSubmittable)
        XCTAssertNil(draft.systemIntent)

        draft.acknowledgesImpact = true

        XCTAssertTrue(draft.isSubmittable)
        XCTAssertNotNil(draft.systemIntent)

        draft.reason = "   "

        XCTAssertFalse(draft.isSubmittable)
        XCTAssertNil(draft.systemIntent)
    }

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
