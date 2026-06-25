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
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる", action: dismissScreen)
            }

            if store.state.model?.canWithdraw == true {
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive, action: requestWithdrawConfirmation) {
                        if store.isWithdrawing {
                            ProgressView()
                        } else {
                            Label("取り下げ", systemImage: "arrow.uturn.backward")
                        }
                    }
                }
            }
        }
        .sheet(item: $presentedRequestKind) { kind in
            NavigationStack {
                TradeRequestSheet(kind: kind, onSubmit: onSubmitTradeRequest)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "申告を取り下げますか？",
            isPresented: $isShowingWithdrawConfirmation,
            titleVisibility: .visible
        ) {
            Button("取り下げる", role: .destructive) {
                withdrawDispute()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("取り下げ後は、この申告への反論や仲裁確認を進められません。")
        }
        .alert(
            "操作を完了できませんでした",
            isPresented: Binding(
                get: { store.actionErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        store.clearActionError()
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                store.clearActionError()
            }
        } message: {
            Text(store.actionErrorMessage ?? "")
        }
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
