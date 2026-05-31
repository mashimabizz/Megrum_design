@testable import MegrumApp
import MegrumCore
@testable import MegrumData
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

    func testSupabaseDetailMappingPreservesFieldsAndMessages() {
        let submittedAt = Date(timeIntervalSince1970: 10_000)
        let createdAt = submittedAt.addingTimeInterval(-120)
        let replyDeadlineAt = submittedAt.addingTimeInterval(86_400)
        let reporterID = UUID(uuidString: "40000000-0000-0000-0000-000000000101")!
        let respondentID = UUID(uuidString: "40000000-0000-0000-0000-000000000102")!
        let respondentMessage = SupabaseDisputeMessage(
            id: UUID(uuidString: "40000000-0000-0000-0000-000000000301")!,
            disputeID: UUID(uuidString: "40000000-0000-0000-0000-000000000001")!,
            senderID: respondentID,
            senderRole: .respondent,
            body: "取引チャットに到着予定を書いています",
            photoURLs: [" https://example.com/respondent-a.jpg "],
            createdAt: submittedAt.addingTimeInterval(900)
        )
        let reporterMessage = SupabaseDisputeMessage(
            id: UUID(uuidString: "40000000-0000-0000-0000-000000000302")!,
            disputeID: UUID(uuidString: "40000000-0000-0000-0000-000000000001")!,
            senderID: reporterID,
            senderRole: .reporter,
            body: "待ち合わせ場所で待っています",
            photoURLs: [],
            createdAt: submittedAt.addingTimeInterval(300)
        )
        let detail = makeSupabaseDetail(
            reporterID: reporterID,
            respondentID: respondentID,
            status: "response_pending",
            category: .wrong,
            factMemo: "状態が説明と違いました",
            evidencePhotoURLs: ["https://example.com/evidence-a.jpg", " "],
            respondentDeadlineAt: replyDeadlineAt,
            submittedAt: submittedAt,
            createdAt: createdAt,
            messages: [respondentMessage, reporterMessage]
        )

        let model = DisputeDetailModel(
            supabaseDetail: detail,
            mapper: DisputeDetailSupabaseMapper(viewerID: reporterID)
        )

        XCTAssertEqual(model.id, detail.id)
        XCTAssertEqual(model.proposalID, detail.proposalID)
        XCTAssertEqual(model.reporterID, reporterID)
        XCTAssertEqual(model.respondentID, respondentID)
        XCTAssertEqual(model.counterpartyID(for: reporterID), respondentID)
        XCTAssertEqual(model.status, .replyWindow)
        XCTAssertEqual(model.category, .wrong)
        XCTAssertEqual(model.factMemo, "状態が説明と違いました")
        XCTAssertEqual(model.evidencePhotoURLs, ["https://example.com/evidence-a.jpg"])
        XCTAssertEqual(model.createdAt, createdAt)
        XCTAssertEqual(model.submittedAt, submittedAt)
        XCTAssertEqual(model.replyDeadlineAt, replyDeadlineAt)
        XCTAssertEqual(model.reporterName, "あなた")
        XCTAssertEqual(model.respondentName, "相手")
        XCTAssertEqual(model.viewerRole, .reporter)
        XCTAssertFalse(model.canSubmitReply)
        XCTAssertTrue(model.canWithdraw)
        XCTAssertEqual(model.timeline.map(\.status), [.submitted, .replyWindow, .arbitration, .resolved])
        XCTAssertEqual(model.messages.map(\.body), ["待ち合わせ場所で待っています", "取引チャットに到着予定を書いています"])
        XCTAssertEqual(model.messages.map(\.senderRole), [.reporter, .respondent])
        XCTAssertEqual(model.messages.first?.senderName, "あなた")
        XCTAssertEqual(model.messages.last?.senderName, "相手")
        XCTAssertEqual(model.messages.last?.senderID, respondentID)
        XCTAssertEqual(model.messages.last?.photoURLs, ["https://example.com/respondent-a.jpg"])
    }

    func testSupabaseDetailMappingAddsLegacyRespondentResponseAsMessage() {
        let submittedAt = Date(timeIntervalSince1970: 20_000)
        let respondedAt = submittedAt.addingTimeInterval(3_600)
        let respondentID = UUID(uuidString: "40000000-0000-0000-0000-000000000202")!
        let detail = makeSupabaseDetail(
            respondentID: respondentID,
            status: "response_pending",
            submittedAt: submittedAt,
            respondentResponseText: "現地にはいました。写真を添付します。",
            respondentEvidenceURLs: ["https://example.com/respondent-proof.jpg"],
            respondentRespondedAt: respondedAt
        )

        let model = DisputeDetailModel(
            supabaseDetail: detail,
            mapper: DisputeDetailSupabaseMapper(viewerID: respondentID)
        )

        XCTAssertEqual(model.status, .replyReceived)
        XCTAssertEqual(model.viewerRole, .respondent)
        XCTAssertFalse(model.canSubmitReply)
        XCTAssertFalse(model.canWithdraw)
        XCTAssertEqual(model.respondentEvidencePhotoURLs, ["https://example.com/respondent-proof.jpg"])
        XCTAssertEqual(model.evidenceGroups.map(\.title), ["相手の証跡"])
        XCTAssertEqual(model.messages.count, 1)
        XCTAssertEqual(model.messages[0].senderRole, .respondent)
        XCTAssertEqual(model.messages[0].senderName, "あなた")
        XCTAssertEqual(model.messages[0].body, "現地にはいました。写真を添付します。")
        XCTAssertEqual(model.messages[0].createdAt, respondedAt)
        XCTAssertEqual(model.messages[0].photoURLs, ["https://example.com/respondent-proof.jpg"])
        XCTAssertEqual(model.timeline.map(\.status), [.submitted, .replyWindow, .replyReceived, .arbitration, .resolved])
    }

    func testSupabaseClosedMappingSeparatesResolvedFromWithdrawn() {
        let closedAt = Date(timeIntervalSince1970: 30_000)
        let resolved = DisputeDetailModel(
            supabaseDetail: makeSupabaseDetail(
                status: "closed",
                outcome: "no_fault",
                operatorComment: "双方に非なしとして終了します。",
                closedAt: closedAt
            )
        )
        let withdrawn = DisputeDetailModel(
            supabaseDetail: makeSupabaseDetail(
                status: "closed",
                closedAt: closedAt
            )
        )

        XCTAssertEqual(resolved.status, .resolved)
        XCTAssertEqual(resolved.resolvedAt, closedAt)
        XCTAssertEqual(resolved.resolutionSummary, "no_fault\n双方に非なしとして終了します。")
        XCTAssertEqual(resolved.timeline.last?.date, closedAt)
        XCTAssertEqual(withdrawn.status, .withdrawn)
        XCTAssertEqual(withdrawn.resolutionSummary, "申告は取り下げられました。")
        XCTAssertEqual(withdrawn.timeline.map(\.status), [.submitted, .withdrawn])
        XCTAssertEqual(withdrawn.timeline.last?.date, closedAt)
    }

    func testRespondentCanReplyDuringResponsePendingButCannotWithdraw() {
        let respondentID = UUID(uuidString: "40000000-0000-0000-0000-000000000202")!
        let detail = makeSupabaseDetail(
            respondentID: respondentID,
            status: "response_pending",
            evidencePhotoURLs: ["https://example.com/reporter-proof.jpg"],
            respondentDeadlineAt: Date(timeIntervalSince1970: 88_000)
        )

        let model = DisputeDetailModel(
            supabaseDetail: detail,
            mapper: DisputeDetailSupabaseMapper(viewerID: respondentID)
        )

        XCTAssertEqual(model.status, .replyWindow)
        XCTAssertEqual(model.viewerRole, .respondent)
        XCTAssertTrue(model.canSubmitReply)
        XCTAssertFalse(model.canWithdraw)
        XCTAssertEqual(model.withdrawalUnavailableText, "取り下げは申告者だけが行えます。")
        XCTAssertEqual(model.evidenceGroups.map(\.title), ["申告者の証跡"])
    }

    func testReplyDraftValidationRejectsBlankAndTooLongBody() {
        XCTAssertEqual(DisputeReplyDraft(body: "   ").validationMessage, "本文を入力してください")
        XCTAssertFalse(DisputeReplyDraft(body: String(repeating: "a", count: 4_001)).isSubmittable)
        XCTAssertTrue(DisputeReplyDraft(body: String(repeating: "a", count: 4_000)).isSubmittable)
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
    func testStoreBlocksReplyWhenCurrentViewerCannotReply() async {
        let model = makeModel(status: .replyWindow).replacingViewerRole(.reporter)
        var didSubmit = false
        let store = DisputeDetailStore(
            initialState: .loaded(model),
            initialReplyDraft: DisputeReplyDraft(body: "申告者からの追記です"),
            detail: { model },
            reply: { _ in
                didSubmit = true
                return model
            },
            withdraw: { model.replacing(status: .withdrawn) }
        )

        await store.submitReply()

        XCTAssertFalse(didSubmit)
        XCTAssertEqual(store.actionErrorMessage, "この状態では反論を送信できません。")
        XCTAssertEqual(store.replyDraft.normalizedBody, "申告者からの追記です")
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

    private func makeSupabaseDetail(
        id: UUID = UUID(uuidString: "40000000-0000-0000-0000-000000000001")!,
        proposalID: UUID = UUID(uuidString: "40000000-0000-0000-0000-000000000111")!,
        reporterID: UUID = UUID(uuidString: "40000000-0000-0000-0000-000000000201")!,
        respondentID: UUID = UUID(uuidString: "40000000-0000-0000-0000-000000000202")!,
        status: String = "submitted",
        category: TradeDisputeCategory? = .noshow,
        factMemo: String? = "待ち合わせ場所に相手が来ませんでした",
        evidencePhotoURLs: [String] = [],
        outcome: String? = nil,
        operatorComment: String? = nil,
        respondentDeadlineAt: Date? = nil,
        operatorDeadlineAt: Date? = nil,
        submittedAt: Date = Date(timeIntervalSince1970: 1_000),
        closedAt: Date? = nil,
        respondentResponse: String? = nil,
        respondentResponseText: String? = nil,
        respondentEvidenceURLs: [String] = [],
        respondentRespondedAt: Date? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        messages: [SupabaseDisputeMessage] = []
    ) -> SupabaseDisputeDetail {
        SupabaseDisputeDetail(
            id: id,
            proposalID: proposalID,
            reporterID: reporterID,
            respondentID: respondentID,
            category: category,
            factMemo: factMemo,
            evidencePhotoURLs: evidencePhotoURLs,
            status: status,
            outcome: outcome,
            operatorComment: operatorComment,
            ticketNo: "DPT-260531-LIVE",
            respondentDeadlineAt: respondentDeadlineAt,
            operatorDeadlineAt: operatorDeadlineAt,
            submittedAt: submittedAt,
            closedAt: closedAt,
            respondentResponse: respondentResponse,
            respondentResponseText: respondentResponseText,
            respondentEvidenceURLs: respondentEvidenceURLs,
            respondentRespondedAt: respondentRespondedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            messages: messages
        )
    }
}

private extension DisputeDetailModel {
    func replacingViewerRole(_ viewerRole: DisputeDetailViewerRole) -> DisputeDetailModel {
        DisputeDetailModel(
            id: id,
            proposalID: proposalID,
            reporterID: reporterID,
            respondentID: respondentID,
            viewerRole: viewerRole,
            ticketNo: ticketNo,
            status: status,
            category: category,
            reporterName: reporterName,
            respondentName: respondentName,
            factMemo: factMemo,
            evidencePhotoURLs: evidencePhotoURLs,
            respondentEvidencePhotoURLs: respondentEvidencePhotoURLs,
            createdAt: createdAt,
            submittedAt: submittedAt,
            replyDeadlineAt: replyDeadlineAt,
            operatorDeadlineAt: operatorDeadlineAt,
            resolvedAt: resolvedAt,
            resolutionSummary: resolutionSummary,
            timeline: timeline,
            messages: messages
        )
    }
}

private enum StubError: LocalizedError {
    case failed

    var errorDescription: String? {
        "読み込みに失敗しました"
    }
}
