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

    @MainActor
    func testStoreLoadsDetailIntoLoadedState() async {
        let model = makeModel(status: .replyWindow)
        let store = DisputeDetailStore(
            detail: { model },
            reply: { _ in model },
            withdraw: { model.replacing(status: .withdrawn) }
        )

        await store.load()

        XCTAssertEqual(store.state, .loaded(model))
    }

    @MainActor
    func testStoreRepresentsEmptyState() async {
        let store = DisputeDetailStore(
            detail: { nil },
            reply: { _ in nil },
            withdraw: { nil }
        )

        await store.load()

        XCTAssertEqual(store.state, .empty)
    }

    @MainActor
    func testStoreRepresentsLoadErrorState() async {
        let store = DisputeDetailStore(
            detail: { throw StubError.failed },
            reply: { _ in nil },
            withdraw: { nil }
        )

        await store.load()

        XCTAssertEqual(store.state, .failed("読み込みに失敗しました"))
    }

    @MainActor
    func testStoreSubmitsReplyAndUpdatesLoadedModel() async {
        let model = makeModel(status: .replyWindow)
        let updated = model.replacing(
            status: .replyReceived,
            messages: [
                DisputeDetailMessageModel(
                    id: UUID(uuidString: "30000000-0000-0000-0000-000000000201")!,
                    senderName: "あなた",
                    body: "到着時刻は共有済みです",
                    createdAt: model.submittedAt.addingTimeInterval(600)
                )
            ]
        )
        var receivedDraft: DisputeReplyDraft?
        let store = DisputeDetailStore(
            initialState: .loaded(model),
            initialReplyDraft: DisputeReplyDraft(body: "  到着時刻は共有済みです  "),
            detail: { model },
            reply: { draft in
                receivedDraft = draft
                return updated
            },
            withdraw: { model.replacing(status: .withdrawn) }
        )

        await store.submitReply()

        XCTAssertEqual(receivedDraft?.normalizedBody, "到着時刻は共有済みです")
        XCTAssertEqual(store.replyDraft, DisputeReplyDraft())
        XCTAssertEqual(store.state, .loaded(updated))
    }

    @MainActor
    func testStoreWithdrawsIntoWithdrawnModel() async {
        let model = makeModel(status: .replyWindow)
        let withdrawn = model.replacing(
            status: .withdrawn,
            resolvedAt: model.submittedAt.addingTimeInterval(1_200),
            resolutionSummary: "申告は取り下げられました。"
        )
        let store = DisputeDetailStore(
            initialState: .loaded(model),
            detail: { model },
            reply: { _ in model },
            withdraw: { withdrawn }
        )

        await store.withdrawDispute()

        XCTAssertEqual(store.state, .loaded(withdrawn))
        XCTAssertFalse(store.state.model?.canWithdraw ?? true)
    }

    private func makeModel(status: DisputeDetailStatus) -> DisputeDetailModel {
        DisputeDetailModel(
            id: UUID(uuidString: "30000000-0000-0000-0000-000000000010")!,
            proposalID: UUID(uuidString: "30000000-0000-0000-0000-000000000110")!,
            ticketNo: "DPT-260531-LIVE",
            status: status,
            category: .noshow,
            reporterName: "あなた",
            respondentName: "相手",
            factMemo: "待ち合わせ場所に相手が来ませんでした",
            submittedAt: Date(timeIntervalSince1970: 1_000),
            replyDeadlineAt: Date(timeIntervalSince1970: 87_400)
        )
    }
}

private enum StubError: LocalizedError {
    case failed

    var errorDescription: String? {
        "読み込みに失敗しました"
    }
}
