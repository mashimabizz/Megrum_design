import MegrumCore
import MegrumData
import MegrumDesign
import SwiftUI

struct DisputeDetailScreen: View {
    @StateObject private var store: DisputeDetailStore
    var onSubmitTradeRequest: (TradeRequestDraft) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var presentedRequestKind: TradeRequestKind?
    @State private var isShowingWithdrawConfirmation = false

    init(
        model: DisputeDetailModel,
        initialReplyDraft: DisputeReplyDraft = DisputeReplyDraft(),
        onSubmitReply: @escaping (DisputeReplyDraft) async -> Bool = { _ in false },
        onSubmitTradeRequest: @escaping (TradeRequestDraft) async -> Bool = { _ in false },
        onWithdraw: @escaping () async -> Bool = { false }
    ) {
        self._store = StateObject(
            wrappedValue: DisputeDetailStore(
                initialState: .loaded(model),
                initialReplyDraft: initialReplyDraft,
                detail: { model },
                reply: { draft in
                    if await onSubmitReply(draft) {
                        return nil
                    }
                    throw DisputeDetailActionError.notCompleted
                },
                withdraw: {
                    if await onWithdraw() {
                        return model.replacing(
                            status: .withdrawn,
                            resolvedAt: Date(),
                            resolutionSummary: "申告は取り下げられました。"
                        )
                    }
                    throw DisputeDetailActionError.notCompleted
                }
            )
        )
        self.onSubmitTradeRequest = onSubmitTradeRequest
    }

    init(
        initialReplyDraft: DisputeReplyDraft = DisputeReplyDraft(),
        detail: @escaping DisputeDetailStore.DetailAction,
        reply: @escaping DisputeDetailStore.ReplyAction,
        withdraw: @escaping DisputeDetailStore.WithdrawAction,
        onSubmitTradeRequest: @escaping (TradeRequestDraft) async -> Bool = { _ in false }
    ) {
        self._store = StateObject(
            wrappedValue: DisputeDetailStore(
                initialReplyDraft: initialReplyDraft,
                detail: detail,
                reply: reply,
                withdraw: withdraw
            )
        )
        self.onSubmitTradeRequest = onSubmitTradeRequest
    }

    init(
        initialReplyDraft: DisputeReplyDraft = DisputeReplyDraft(),
        actions: DisputeDetailStore.Actions,
        onSubmitTradeRequest: @escaping (TradeRequestDraft) async -> Bool = { _ in false }
    ) {
        self._store = StateObject(
            wrappedValue: DisputeDetailStore(
                initialReplyDraft: initialReplyDraft,
                actions: actions
            )
        )
        self.onSubmitTradeRequest = onSubmitTradeRequest
    }

    init(
        ticketID: UUID,
        viewerID: UUID,
        disputeClient: SupabaseDisputeClient,
        mapper: DisputeDetailSupabaseMapper? = nil,
        initialReplyDraft: DisputeReplyDraft = DisputeReplyDraft(),
        onSubmitTradeRequest: @escaping (TradeRequestDraft) async -> Bool = { _ in false }
    ) {
        self.init(
            initialReplyDraft: initialReplyDraft,
            actions: .supabase(
                ticketID: ticketID,
                viewerID: viewerID,
                client: disputeClient,
                mapper: mapper
            ),
            onSubmitTradeRequest: onSubmitTradeRequest
        )
    }

    init(
        store: DisputeDetailStore,
        onSubmitTradeRequest: @escaping (TradeRequestDraft) async -> Bool = { _ in false }
    ) {
        self._store = StateObject(wrappedValue: store)
        self.onSubmitTradeRequest = onSubmitTradeRequest
    }

    var body: some View {
        DisputeDetailScreenContent(
            state: store.state,
            replyDraft: replyDraftBinding,
            isSubmittingReply: store.isSubmittingReply,
            isWithdrawing: store.isWithdrawing,
            onRetryLoad: retryLoad,
            onSubmitReply: submitReply,
            onRequestWithdraw: requestWithdrawConfirmation,
            onOpenLateRequest: openLateRequest,
            onOpenCancellationRequest: openCancellationRequest
        )
        .task {
            await store.loadIfNeeded()
        }
        .navigationTitle("異議詳細")
        .megrumInlineNavigationTitle()
        .toolbar {
            DisputeDetailToolbarContent(
                canWithdraw: store.state.model?.canWithdraw == true,
                isWithdrawing: store.isWithdrawing,
                onDismiss: dismissScreen,
                onRequestWithdraw: requestWithdrawConfirmation
            )
        }
        .disputeDetailTradeRequestSheet(
            presentedRequestKind: $presentedRequestKind,
            onSubmitTradeRequest: onSubmitTradeRequest
        )
        .disputeDetailWithdrawConfirmation(
            isPresented: $isShowingWithdrawConfirmation,
            onWithdraw: withdrawDispute
        )
        .disputeDetailActionErrorAlert(
            message: store.actionErrorMessage,
            onClear: { store.clearActionError() }
        )
    }

    private var replyDraftBinding: Binding<DisputeReplyDraft> {
        Binding(
            get: { store.replyDraft },
            set: { store.replyDraft = $0 }
        )
    }

    private func dismissScreen() {
        dismiss()
    }

    private func retryLoad() {
        Task {
            await store.load()
        }
    }

    private func submitReply() {
        Task {
            await store.submitReply()
        }
    }

    private func requestWithdrawConfirmation() {
        isShowingWithdrawConfirmation = true
    }

    private func withdrawDispute() {
        Task {
            await store.withdrawDispute()
        }
    }

    private func openLateRequest() {
        presentedRequestKind = .late
    }

    private func openCancellationRequest() {
        presentedRequestKind = .cancellation
    }
}
